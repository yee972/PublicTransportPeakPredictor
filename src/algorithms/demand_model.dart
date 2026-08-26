import 'dart:math' as math;

import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../models/demand_forecast.dart';
import '../models/ridership_day.dart';

class DemandModel {
  final String lineId;
  final List<_Observation> _history;
  final Map<String, String> _holidays;

  final double _typicalRiders;
  final int _maximumRiders;
  final double _holidayFactor;

  DemandModel._(
    this.lineId,
    this._history,
    this._holidays,
    this._typicalRiders,
    this._maximumRiders,
    this._holidayFactor,
  );

  factory DemandModel({
    required String lineId,
    required List<RidershipDay> history,
    List<PublicHoliday> holidays = const [],
  }) {
    final observations = history
        .where((day) => day.lineId == lineId && day.riders > 0)
        .map((day) => _Observation(_dateOnly(day.serviceDate), day.riders))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final holidayMap = <String, String>{
      for (final holiday in holidays) _key(holiday.date): holiday.name,
    };

    final values = observations.map((o) => o.riders).toList();
    final typical = values.isEmpty ? 0.0 : _median(values);
    final maximum = values.isEmpty ? 0 : values.reduce(math.max);

    final model = DemandModel._(lineId, observations, holidayMap, typical, maximum, 1.0);
    return DemandModel._(
      lineId,
      observations,
      holidayMap,
      typical,
      maximum,
      model._learnHolidayFactor(),
    );
  }

  bool get hasEnoughHistory => _history.length >= AppConfig.minimumHistoryDays;

  int get observationCount => _history.length;

  int get maximumRiders => _maximumRiders;

  double get typicalRiders => _typicalRiders;

  double get holidayFactor => _holidayFactor;

  DateTime? get latestDate => _history.isEmpty ? null : _history.last.date;

  List<RidershipPoint> recentActuals(int days) {
    final start = math.max(0, _history.length - days);
    return _history
        .sublist(start)
        .map((o) => RidershipPoint(date: o.date, riders: o.riders, isActual: true))
        .toList();
  }

  DemandForecast forecastFor(DateTime target) {
    return _forecast(_dateOnly(target), _history);
  }

  List<DemandForecast> forecastRange(DateTime start, int days) {
    final from = _dateOnly(start);
    return List.generate(
      days,
      (index) => forecastFor(from.add(Duration(days: index))),
    );
  }

  ValidationMetrics validate({int holdOutDays = AppConfig.validationHoldOutDays}) {
    if (_history.length < AppConfig.minimumHistoryDays + holdOutDays) {
      return ValidationMetrics(
        lineId: lineId,
        meanAbsoluteError: 0,
        meanAbsolutePercentageError: 0,
        classificationAccuracy: 0,
        sampleSize: 0,
        holdOutDays: holdOutDays,
      );
    }

    final splitIndex = _history.length - holdOutDays;
    final absoluteErrors = <double>[];
    final percentageErrors = <double>[];
    var correctClassifications = 0;
    var evaluated = 0;

    final trainingValues =
        _history.sublist(0, splitIndex).map((o) => o.riders).toList();
    final threshold = _median(trainingValues);

    for (var index = splitIndex; index < _history.length; index++) {
      final actual = _history[index];
      final visible = _history.sublist(0, index);
      final forecast = _forecast(actual.date, visible);
      if (!forecast.hasEnoughHistory) continue;

      final error = (forecast.predictedRiders - actual.riders).abs().toDouble();
      absoluteErrors.add(error);
      percentageErrors.add(error / actual.riders * 100);
      if ((forecast.predictedRiders >= threshold) == (actual.riders >= threshold)) {
        correctClassifications++;
      }
      evaluated++;
    }

    if (evaluated == 0) {
      return ValidationMetrics(
        lineId: lineId,
        meanAbsoluteError: 0,
        meanAbsolutePercentageError: 0,
        classificationAccuracy: 0,
        sampleSize: 0,
        holdOutDays: holdOutDays,
      );
    }

    return ValidationMetrics(
      lineId: lineId,
      meanAbsoluteError: _mean(absoluteErrors),
      meanAbsolutePercentageError: _mean(percentageErrors),
      classificationAccuracy: correctClassifications / evaluated * 100,
      sampleSize: evaluated,
      holdOutDays: holdOutDays,
    );
  }

  DemandForecast _forecast(DateTime target, List<_Observation> visible) {
    if (visible.length < AppConfig.minimumHistoryDays) {
      return DemandForecast.insufficient(target, lineId);
    }

    final baseline = _baselineFor(target.weekday, visible, visible.length);
    if (baseline == null) {
      return DemandForecast.insufficient(target, lineId);
    }

    final trend = _trendAt(visible);
    final holidayName = _holidays[_key(target)];
    final holidayEffect = holidayName == null ? 1.0 : _holidayFactor;
    final predicted = baseline * trend * holidayEffect;

    final typical = _typicalOf(visible);
    final relative = typical <= 0 ? 1.0 : predicted / typical;

    return DemandForecast(
      date: target,
      lineId: lineId,
      predictedRiders: predicted.round(),
      baselineRiders: baseline.round(),
      trendFactor: trend,
      holidayFactor: holidayEffect,
      percentOfMax: _maximumRiders <= 0 ? 0 : predicted / _maximumRiders,
      deviationFromBaseline: baseline <= 0 ? 0 : predicted / baseline - 1,
      relativeToTypical: relative,
      band: _bandFor(relative),
      hasEnoughHistory: true,
      holidayName: holidayName,
    );
  }

  double? _baselineFor(int weekday, List<_Observation> visible, int upTo) {
    final sameWeekday = <int>[];
    for (var index = upTo - 1; index >= 0; index--) {
      final observation = visible[index];
      if (observation.date.weekday == weekday) {
        sameWeekday.add(observation.riders);
        if (sameWeekday.length == AppConfig.baselineWeeks) break;
      }
    }
    if (sameWeekday.length < 4) return null;
    return _median(sameWeekday);
  }

  double _trendAt(List<_Observation> visible) {
    final ratios = <double>[];
    final start = math.max(0, visible.length - AppConfig.trendWindowDays);
    for (var index = start; index < visible.length; index++) {
      final observation = visible[index];
      final baseline = _baselineFor(observation.date.weekday, visible, index);
      if (baseline == null || baseline <= 0) continue;
      ratios.add(observation.riders / baseline);
    }
    if (ratios.isEmpty) return 1.0;

    var weightedSum = 0.0;
    var weightTotal = 0.0;
    for (var index = 0; index < ratios.length; index++) {
      final weight = math.pow(0.85, ratios.length - 1 - index).toDouble();
      weightedSum += ratios[index] * weight;
      weightTotal += weight;
    }
    final trend = weightedSum / weightTotal;
    return trend.clamp(0.8, 1.2);
  }

  double _learnHolidayFactor() {
    if (_holidays.isEmpty || _history.length < AppConfig.minimumHistoryDays) {
      return 1.0;
    }
    final ratios = <double>[];
    for (var index = AppConfig.minimumHistoryDays; index < _history.length; index++) {
      final observation = _history[index];
      if (!_holidays.containsKey(_key(observation.date))) continue;
      final visible = _history.sublist(0, index);
      final baseline = _baselineFor(observation.date.weekday, visible, visible.length);
      if (baseline == null || baseline <= 0) continue;
      ratios.add(observation.riders / baseline);
    }
    if (ratios.isEmpty) return 1.0;
    return _median(ratios.map((r) => (r * 1000).round()).toList()) / 1000.0;
  }

  double _typicalOf(List<_Observation> visible) {
    if (visible.isEmpty) return 0;
    final window = visible.length <= 90
        ? visible
        : visible.sublist(visible.length - 90);
    return _median(window.map((o) => o.riders).toList());
  }

  static DemandBand _bandFor(double relativeToTypical) {
    if (relativeToTypical < 0.80) return DemandBand.quiet;
    if (relativeToTypical < 1.02) return DemandBand.baseline;
    if (relativeToTypical < 1.12) return DemandBand.moderate;
    return DemandBand.busy;
  }

  static double _median(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle].toDouble();
    return (sorted[middle - 1] + sorted[middle]) / 2.0;
  }

  static double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _key(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class _Observation {
  final DateTime date;
  final int riders;

  const _Observation(this.date, this.riders);
}
