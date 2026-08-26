import 'package:shared_preferences/shared_preferences.dart';

import '../../models/journey.dart';

class PreferencesService {
  static const String _homeStationKey = 'home_station_id';
  static const String _preferenceKey = 'journey_preference';
  static const String _alertsKey = 'peak_alerts_enabled';
  static const String _lastLineKey = 'last_viewed_line';
  static const String _offlineKey = 'offline_mode_enabled';

  Future<String?> readHomeStation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_homeStationKey);
  }

  Future<void> writeHomeStation(String? stationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (stationId == null) {
      await prefs.remove(_homeStationKey);
      return;
    }
    await prefs.setString(_homeStationKey, stationId);
  }

  Future<JourneyPreference> readJourneyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_preferenceKey) ?? 'balanced';
    return JourneyPreferenceLabel.fromStorage(stored);
  }

  Future<void> writeJourneyPreference(JourneyPreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, preference.storageValue);
  }

  Future<bool> readAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alertsKey) ?? true;
  }

  Future<void> writeAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alertsKey, enabled);
  }

  Future<String?> readLastViewedLine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLineKey);
  }

  Future<void> writeLastViewedLine(String lineId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLineKey, lineId);
  }

  Future<bool> readOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineKey) ?? false;
  }

  Future<void> writeOfflineModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineKey, enabled);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_homeStationKey);
    await prefs.remove(_preferenceKey);
    await prefs.remove(_lastLineKey);
  }
}
