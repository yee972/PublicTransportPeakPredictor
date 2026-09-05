import '../../models/rail_network.dart';
import '../../models/ridership_day.dart';
import '../local/app_database.dart';
import '../remote/reference_api.dart';

class NetworkRepository {
  final ReferenceApi _api;
  final AppDatabase _database;

  RailNetwork? _memoryCache;
  List<ScheduleSlot>? _scheduleCache;

  NetworkRepository(this._api, this._database);

  Future<RailNetwork> loadNetwork({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCache != null) return _memoryCache!;

    try {
      final lines = await _api.fetchLines();
      final stations = await _api.fetchStations();
      final edges = await _api.fetchEdges();
      final links = await _api.fetchLinks();

      final network = RailNetwork(
        lines: lines,
        stations: stations,
        edges: edges,
        links: links,
      );
      await _writeCache(network);
      _memoryCache = network;
      return network;
    } on DataFailure {
      final cached = await _readCache();
      if (cached != null && !cached.isEmpty) {
        _memoryCache = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<List<ScheduleSlot>> loadSchedule({bool forceRefresh = false}) async {
    if (!forceRefresh && _scheduleCache != null) return _scheduleCache!;
    try {
      final slots = await _api.fetchSchedule();
      await _cacheSchedule(slots);
      _scheduleCache = slots;
      return slots;
    } on DataFailure {
      final cached = await _database.readSchedule();
      if (cached.isNotEmpty) {
        _scheduleCache = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<DateTime?> lastSyncedAt() => _database.lastSyncedAt('stations');

  Future<void> clearCache() async {
    _memoryCache = null;
    _scheduleCache = null;
    await _database.clear();
  }

  Future<void> _cacheSchedule(List<ScheduleSlot> slots) async {
    try {
      await _database.replaceAll(
        'schedule_frequency',
        slots.map((slot) => slot.toJson()).toList(),
      );
    } catch (_) {
      return;
    }
  }

  Future<void> _writeCache(RailNetwork network) async {
    try {
      await _database.replaceAll(
        'rail_lines',
        network.lines.map((line) => line.toJson()).toList(),
      );
      await _database.replaceAll(
        'stations',
        network.stations.map((station) => station.toJson()).toList(),
      );
      await _database.replaceAll(
        'rail_edges',
        network.edges.map((edge) => edge.toJson()).toList(),
      );
      await _database.replaceAll(
        'station_links',
        network.links.map((link) => link.toJson()).toList(),
      );
    } catch (_) {
      return;
    }
  }

  Future<RailNetwork?> _readCache() async {
    if (!await _database.hasNetworkCache) return null;
    final lines = await _database.readLines();
    final stations = await _database.readStations();
    final edges = await _database.readEdges();
    final links = await _database.readLinks();
    if (lines.isEmpty || stations.isEmpty) return null;
    return RailNetwork(
      lines: lines,
      stations: stations,
      edges: edges,
      links: links,
      fromCache: true,
    );
  }
}
