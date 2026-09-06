import 'package:flutter/foundation.dart';

import '../../algorithms/demand_model.dart';
import '../../algorithms/schedule_intensity.dart';
import '../../core/app_config.dart';
import '../../models/demand_band.dart';
import '../../data/repositories/network_repository.dart';
import '../../data/repositories/ridership_repository.dart';
import '../../models/demand_forecast.dart';
import '../../models/rail_line.dart';
import '../../models/rail_network.dart';
import '../../models/ridership_day.dart';

enum LoadState { idle, loading, ready, failed }

class ForecastProvider extends ChangeNotifier {
  final NetworkRepository _networkRepository;
  final RidershipRepository _ridershipRepository;

  LoadState _state = LoadState.idle;
  String? _errorMessage;
  bool _usingCachedData = false;
  DateTime? _syncedAt;

  RailNetwork _network = RailNetwork.empty();
  ScheduleIntensity? _intensity;
  final Map<String, DemandModel> _models = {};
  final Map<String, ValidationMetrics> _validation = {};
  final Map<String, Map<String, double>> _lineLoadCache = {};

  ForecastProvider(this._networkRepository, this._ridershipRepository);

  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get usingCachedData => _usingCachedData;
  DateTime? get syncedAt => _syncedAt;
  RailNetwork get network => _network;
  ScheduleIntensity? get intensity => _intensity;
  bool get isReady => _state == LoadState.ready;

  List<RailLine> get lines => _network.lines;

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get latestDataDate {
    DateTime? latest;
    for (final model in _models.values) {
      final date = model.latestDate;
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest ?? DateTime.now();
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (_state == LoadState.loading) return;
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _networkRepository.loadNetwork(forceRefresh: forceRefresh),
        _networkRepository.loadSchedule(forceRefresh: forceRefresh),
        _ridershipRepository.load(forceRefresh: forceRefresh),
      ]);
      final network = results[0] as RailNetwork;
      final schedule = results[1] as List<ScheduleSlot>;
      final snapshot = results[2] as RidershipSnapshot;

      _network = network;
      _intensity = ScheduleIntensity(slots: schedule, stations: network.stations);
      _usingCachedData = network.fromCache || snapshot.fromCache;
      _syncedAt = snapshot.syncedAt ?? await _networkRepository.lastSyncedAt();

      _buildModels(network.lines, snapshot.ridership, snapshot.holidays);

      _state = LoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = LoadState.failed;
    }
    notifyListeners();
  }

  void _buildModels(
    List<RailLine> lines,
    List<RidershipDay> ridership,
    List<PublicHoliday> holidays,
  ) {
    _models.clear();
    _validation.clear();
    _lineLoadCache.clear();
    for (final line in lines) {
      final model = DemandModel(
        lineId: line.seriesId,
        history: ridership,
        holidays: holidays,
      );
      _models[line.id] = model;
      _validation[line.id] = model.validate();
    }
  }

  DemandModel? modelFor(String lineId) => _models[lineId];

  ValidationMetrics? validationFor(String lineId) => _validation[lineId];

  List<ValidationMetrics> get allValidation {
    return _network.lines
        .map((line) => _validation[line.id])
        .whereType<ValidationMetrics>()
        .where((metrics) => metrics.isReliable)
        .toList();
  }

  List<ValidationMetrics> get distinctSeriesValidation {
    final seen = <String>{};
    final result = <ValidationMetrics>[];
    for (final line in _network.lines) {
      if (!seen.add(line.seriesId)) continue;
      final metrics = _validation[line.id];
      if (metrics != null && metrics.isReliable) result.add(metrics);
    }
    return result;
  }

  double get networkAccuracy {
    final reliable = distinctSeriesValidation;
    if (reliable.isEmpty) return 0;
    final total = reliable
        .map((metrics) => metrics.classificationAccuracy)
        .reduce((a, b) => a + b);
    return total / reliable.length;
  }

  double get networkMape {
    final reliable = distinctSeriesValidation;
    if (reliable.isEmpty) return 0;
    final total = reliable
        .map((metrics) => metrics.meanAbsolutePercentageError)
        .reduce((a, b) => a + b);
    return total / reliable.length;
  }

  DemandForecast forecastFor(String lineId, DateTime date) {
    final model = _models[lineId];
    if (model == null) return DemandForecast.insufficient(date, lineId);
    return model.forecastFor(date);
  }

  List<DemandForecast> sevenDayFor(String lineId, {DateTime? from}) {
    final model = _models[lineId];
    final start = from ?? today.add(const Duration(days: 1));
    if (model == null) {
      return List.generate(
        AppConfig.forecastHorizonDays,
        (index) => DemandForecast.insufficient(
          start.add(Duration(days: index)),
          lineId,
        ),
      );
    }
    return model.forecastRange(start, AppConfig.forecastHorizonDays);
  }

  List<DemandForecast> networkSevenDay({DateTime? from}) {
    final start = from ?? today.add(const Duration(days: 1));
    return List.generate(AppConfig.forecastHorizonDays, (index) {
      final date = start.add(Duration(days: index));
      return _blendAcrossLines(date);
    });
  }

  DemandForecast _blendAcrossLines(DateTime date) {
    final seenSeries = <String>{};
    final forecasts = <DemandForecast>[];
    for (final line in _network.lines) {
      if (!seenSeries.add(line.seriesId)) continue;
      final forecast = forecastFor(line.id, date);
      if (forecast.hasEnoughHistory) forecasts.add(forecast);
    }

    if (forecasts.isEmpty) return DemandForecast.insufficient(date, 'network');

    var predicted = 0;
    var baseline = 0;
    var relativeSum = 0.0;
    var percentSum = 0.0;
    String? holidayName;
    for (final forecast in forecasts) {
      predicted += forecast.predictedRiders;
      baseline += forecast.baselineRiders;
      relativeSum += forecast.relativeToTypical;
      percentSum += forecast.percentOfMax;
      holidayName ??= forecast.holidayName;
    }
    final relative = relativeSum / forecasts.length;

    return DemandForecast(
      date: date,
      lineId: 'network',
      predictedRiders: predicted,
      baselineRiders: baseline,
      trendFactor: 1,
      holidayFactor: 1,
      percentOfMax: percentSum / forecasts.length,
      deviationFromBaseline: baseline <= 0 ? 0 : predicted / baseline - 1,
      relativeToTypical: relative,
      band: DemandBands.fromRelative(relative),
      hasEnoughHistory: true,
      holidayName: holidayName,
    );
  }

  Map<String, double> lineLoadsFor(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    final cached = _lineLoadCache[key];
    if (cached != null) return cached;

    final resolver = _intensity;
    final loads = <String, double>{};
    if (resolver == null) return loads;

    final dayType = ScheduleSlot.dayTypeFor(date);
    final ridersPerTrain = <String, double>{};
    var heaviest = 0.0;
    for (final line in _network.lines) {
      final trips = resolver.dailyTrips(line.id, dayType);
      final forecast = forecastFor(line.id, date);
      if (trips <= 0 || !forecast.hasEnoughHistory) {
        ridersPerTrain[line.id] = 0;
        continue;
      }
      final value = forecast.predictedRiders / trips;
      ridersPerTrain[line.id] = value;
      if (value > heaviest) heaviest = value;
    }

    ridersPerTrain.forEach((lineId, value) {
      loads[lineId] = heaviest <= 0 ? 0 : value / heaviest;
    });
    _lineLoadCache[key] = loads;
    return loads;
  }

  double crowdIndexFor({
    required String lineId,
    required String stationId,
    required int hour,
    required DateTime date,
  }) {
    final resolver = _intensity;
    if (resolver == null) return 0;
    return resolver.crowdIndex(
      lineId: lineId,
      stationId: stationId,
      dayType: ScheduleSlot.dayTypeFor(date),
      hour: hour,
      lineLoad: lineLoadsFor(date)[lineId] ?? 0,
    );
  }
}
