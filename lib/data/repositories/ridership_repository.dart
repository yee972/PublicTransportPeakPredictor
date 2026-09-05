import '../../models/ridership_day.dart';
import '../local/app_database.dart';
import '../remote/reference_api.dart';
import '../remote/ridership_api.dart';

class RidershipSnapshot {
  final List<RidershipDay> ridership;
  final List<PublicHoliday> holidays;
  final bool fromCache;
  final DateTime? syncedAt;

  const RidershipSnapshot({
    required this.ridership,
    required this.holidays,
    required this.fromCache,
    this.syncedAt,
  });

  bool get isEmpty => ridership.isEmpty;
}

class RidershipRepository {
  final RidershipApi _api;
  final AppDatabase _database;

  RidershipSnapshot? _memoryCache;

  RidershipRepository(this._api, this._database);

  Future<RidershipSnapshot> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCache != null) return _memoryCache!;

    try {
      final ridership = await _api.fetchRidership();
      final holidays = await _api.fetchHolidays();

      await _cache(ridership, holidays);

      final snapshot = RidershipSnapshot(
        ridership: ridership,
        holidays: holidays,
        fromCache: false,
        syncedAt: DateTime.now(),
      );
      _memoryCache = snapshot;
      return snapshot;
    } on DataFailure {
      final cachedRidership = await _database.readRidership();
      if (cachedRidership.isEmpty) rethrow;
      final snapshot = RidershipSnapshot(
        ridership: cachedRidership,
        holidays: await _database.readHolidays(),
        fromCache: true,
        syncedAt: await _database.lastSyncedAt('ridership_daily'),
      );
      _memoryCache = snapshot;
      return snapshot;
    }
  }

  Future<void> _cache(
    List<RidershipDay> ridership,
    List<PublicHoliday> holidays,
  ) async {
    try {
      await _database.replaceAll(
        'ridership_daily',
        ridership.map((day) => day.toJson()).toList(),
      );
      await _database.replaceAll(
        'public_holidays',
        holidays.map((holiday) => holiday.toJson()).toList(),
      );
    } catch (_) {
      return;
    }
  }

  void invalidate() => _memoryCache = null;
}
