import 'package:flutter/foundation.dart';

import '../../algorithms/journey_planner.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/network_repository.dart';
import '../../models/journey.dart';
import '../../models/rail_network.dart';
import '../../models/station.dart';
import '../../models/user_profile.dart';
import '../../services/location_service.dart';
import '../forecast/forecast_provider.dart';

class RoutePlannerProvider extends ChangeNotifier {
  final NetworkRepository _networkRepository;
  final AccountRepository _accounts;
  final LocationService _location;

  LoadState _state = LoadState.idle;
  String? _errorMessage;
  RailNetwork _network = RailNetwork.empty();
  JourneyPlanner? _planner;

  String? _originId;
  String? _destinationId;
  DateTime _departureTime = DateTime.now();
  List<Journey> _results = const [];
  bool _planning = false;
  String? _planMessage;

  List<SavedRoute> _savedRoutes = const [];
  bool _loadingSaved = false;
  String? _savedMessage;

  bool _locating = false;
  String? _locationMessage;

  RoutePlannerProvider(this._networkRepository, this._accounts, this._location);

  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  RailNetwork get network => _network;
  JourneyPlanner? get planner => _planner;
  String? get originId => _originId;
  String? get destinationId => _destinationId;
  DateTime get departureTime => _departureTime;
  List<Journey> get results => _results;
  bool get planning => _planning;
  String? get planMessage => _planMessage;
  List<SavedRoute> get savedRoutes => _savedRoutes;
  bool get loadingSaved => _loadingSaved;
  String? get savedMessage => _savedMessage;
  bool get locating => _locating;
  String? get locationMessage => _locationMessage;
  bool get isReady => _state == LoadState.ready;

  Station? get origin => _originId == null ? null : _network.station(_originId!);
  Station? get destination =>
      _destinationId == null ? null : _network.station(_destinationId!);

  bool get canPlan =>
      _originId != null && _destinationId != null && _originId != _destinationId;

  Future<void> load({bool forceRefresh = false}) async {
    if (_state == LoadState.loading) return;
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final network = await _networkRepository.loadNetwork(forceRefresh: forceRefresh);
      _network = network;
      _planner = JourneyPlanner(
        stations: network.stations,
        edges: network.edges,
        links: network.links,
      );
      _originId ??= await _accounts.cachedHomeStation();
      if (_originId != null && network.station(_originId!) == null) {
        _originId = null;
      }
      _state = LoadState.ready;
    } catch (error) {
      _errorMessage = error.toString();
      _state = LoadState.failed;
    }
    notifyListeners();
  }

  void setOrigin(String? stationId) {
    _originId = stationId;
    _results = const [];
    _planMessage = null;
    notifyListeners();
  }

  void setDestination(String? stationId) {
    _destinationId = stationId;
    _results = const [];
    _planMessage = null;
    notifyListeners();
  }

  void swapEndpoints() {
    final origin = _originId;
    _originId = _destinationId;
    _destinationId = origin;
    _results = const [];
    notifyListeners();
  }

  void setDepartureTime(DateTime value) {
    _departureTime = value;
    _results = const [];
    notifyListeners();
  }

  void plan({required CrowdIndexResolver crowdIndex}) {
    final planner = _planner;
    if (planner == null || !canPlan) return;

    _planning = true;
    _planMessage = null;
    notifyListeners();

    final journeys = planner.planAlternatives(
      originId: _originId!,
      destinationId: _destinationId!,
      departureTime: _departureTime,
      crowdIndex: crowdIndex,
    );

    _results = journeys;
    _planning = false;
    if (journeys.isEmpty) {
      _planMessage = 'No route found between these stations.';
    }
    notifyListeners();
  }

  Future<void> useCurrentLocationAsOrigin() async {
    _locating = true;
    _locationMessage = null;
    notifyListeners();

    final result = await _location.currentPosition();
    if (result.isSuccess && result.latitude != null && result.longitude != null) {
      final nearest = _network.nearestStation(result.latitude!, result.longitude!);
      if (nearest != null) {
        _originId = nearest.id;
        _results = const [];
        _locationMessage = 'Starting from ${nearest.name}';
      } else {
        _locationMessage = 'No station found near you';
      }
    } else {
      _locationMessage = result.message;
    }

    _locating = false;
    notifyListeners();
  }

  Future<void> loadSavedRoutes(String userId) async {
    _loadingSaved = true;
    _savedMessage = null;
    notifyListeners();
    try {
      _savedRoutes = await _accounts.loadSavedRoutes(userId);
    } catch (error) {
      _savedMessage = error.toString();
    }
    _loadingSaved = false;
    notifyListeners();
  }

  Future<bool> saveCurrentRoute({
    required String userId,
    required String label,
    required JourneyPreference preference,
  }) async {
    if (!canPlan) return false;
    try {
      final saved = await _accounts.saveRoute(
        userId: userId,
        label: label,
        originStationId: _originId!,
        destinationStationId: _destinationId!,
        preference: preference,
      );
      _savedRoutes = [saved, ..._savedRoutes];
      _savedMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _savedMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteSavedRoute(String routeId) async {
    try {
      await _accounts.deleteRoute(routeId);
      _savedRoutes =
          _savedRoutes.where((route) => route.id != routeId).toList();
      _savedMessage = null;
    } catch (error) {
      _savedMessage = error.toString();
    }
    notifyListeners();
  }

  void applySavedRoute(SavedRoute route) {
    _originId = route.originStationId;
    _destinationId = route.destinationStationId;
    _results = const [];
    notifyListeners();
  }

  void clearMessages() {
    _planMessage = null;
    _savedMessage = null;
    _locationMessage = null;
    notifyListeners();
  }
}
