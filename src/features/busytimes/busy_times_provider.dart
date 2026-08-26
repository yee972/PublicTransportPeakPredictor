import 'package:flutter/foundation.dart';

import '../../algorithms/schedule_intensity.dart';
import '../../data/repositories/network_repository.dart';
import '../../data/repositories/ridership_repository.dart';
import '../../models/rail_network.dart';
import '../../models/ridership_day.dart';
import '../../models/station.dart';
import '../../services/location_service.dart';
import '../forecast/forecast_provider.dart';

class StationLoad {
  final Station station;
  final int trips;
  final double intensity;

  const StationLoad({
    required this.station,
    required this.trips,
    required this.intensity,
  });
}

class BusyTimesProvider extends ChangeNotifier {
  final NetworkRepository _networkRepository;
  final RidershipRepository _ridershipRepository;
  final LocationService _location;

  LoadState _state = LoadState.idle;
  String? _errorMessage;
  RailNetwork _network = RailNetwork.empty();
  ScheduleIntensity? _intensity;

  String? _selectedStationId;
  String? _selectedLineId;
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = DateTime.now().hour;
  String? _locationMessage;
  bool _locating = false;

  BusyTimesProvider(
    this._networkRepository,
    this._ridershipRepository,
    this._location,
  );

  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  RailNetwork get network => _network;
  ScheduleIntensity? get intensity => _intensity;
  String? get selectedStationId => _selectedStationId;
  String? get selectedLineId => _selectedLineId;
  DateTime get selectedDate => _selectedDate;
  int get selectedHour => _selectedHour;
  String? get locationMessage => _locationMessage;
  bool get locating => _locating;
  String get dayType => ScheduleSlot.dayTypeFor(_selectedDate);
  bool get isReady => _state == LoadState.ready;

  Station? get selectedStation =>
      _selectedStationId == null ? null : _network.station(_selectedStationId!);

  Future<void> load({bool forceRefresh = false}) async {
    if (_state == LoadState.loading) return;
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final network = await _networkRepository.loadNetwork(forceRefresh: forceRefresh);
      final schedule = await _networkRepository.loadSchedule(forceRefresh: forceRefresh);
      await _ridershipRepository.load(forceRefresh: forceRefresh);

      _network = network;
      _intensity = ScheduleIntensity(slots: schedule, stations: network.stations);
      _selectedLineId ??= network.lines.isEmpty ? null : network.lines.first.id;
      _selectedStationId ??= _defaultStation(network);
      _state = LoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = LoadState.failed;
    }
    notifyListeners();
  }

  String? _defaultStation(RailNetwork network) {
    if (network.stations.isEmpty) return null;
    final ranked = rankedStations(limit: 1, network: network);
    if (ranked.isNotEmpty) return ranked.first.station.id;
    return network.stations.first.id;
  }

  void selectStation(String stationId) {
    _selectedStationId = stationId;
    notifyListeners();
  }

  void selectLine(String lineId) {
    _selectedLineId = lineId;
    notifyListeners();
  }

  void selectHour(int hour) {
    _selectedHour = hour.clamp(0, 23);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  List<StationLoad> rankedStations({int limit = 12, RailNetwork? network}) {
    final source = network ?? _network;
    final resolver = _intensity;
    if (resolver == null || source.stations.isEmpty) return const [];

    final type = ScheduleSlot.dayTypeFor(_selectedDate);
    final loads = source.stations.map((station) {
      final trips = resolver.stationTrips(station.id, type, _selectedHour);
      return StationLoad(
        station: station,
        trips: trips,
        intensity: resolver.stationIntensity(station.id, type, _selectedHour),
      );
    }).where((load) => load.trips > 0).toList()
      ..sort((a, b) => b.trips.compareTo(a.trips));

    return loads.take(limit).toList();
  }

  List<StationLoad> stationsForMap({int limit = 60}) =>
      rankedStations(limit: limit);

  List<HourIntensity> profileForSelectedStation() {
    final resolver = _intensity;
    final stationId = _selectedStationId;
    if (resolver == null || stationId == null) return const [];
    return resolver.stationProfile(stationId, dayType);
  }

  List<int> peakHoursForSelectedStation() {
    final resolver = _intensity;
    final stationId = _selectedStationId;
    if (resolver == null || stationId == null) return const [];
    return resolver.peakHours(stationId, dayType);
  }

  Future<void> useCurrentLocation() async {
    _locating = true;
    _locationMessage = null;
    notifyListeners();

    final result = await _location.currentPosition();
    if (result.isSuccess && result.latitude != null && result.longitude != null) {
      final nearest = _network.nearestStation(result.latitude!, result.longitude!);
      if (nearest != null) {
        _selectedStationId = nearest.id;
        final metres = nearest.metresTo(result.latitude!, result.longitude!);
        _locationMessage =
            'Nearest station: ${nearest.name} (${_formatDistance(metres)} away)';
      } else {
        _locationMessage = 'No station found near you';
      }
    } else {
      _locationMessage = result.message;
    }

    _locating = false;
    notifyListeners();
  }

  void clearLocationMessage() {
    if (_locationMessage == null) return;
    _locationMessage = null;
    notifyListeners();
  }

  static String _formatDistance(double metres) {
    if (metres < 1000) return '${metres.round()} m';
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }
}
