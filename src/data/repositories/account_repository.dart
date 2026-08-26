import '../../models/journey.dart';
import '../../models/user_profile.dart';
import '../local/preferences_service.dart';
import '../remote/account_api.dart';

class AccountRepository {
  final AccountApi _api;
  final PreferencesService _preferences;

  AccountRepository(this._api, this._preferences);

  Future<UserProfile?> loadProfile(String userId) async {
    final profile = await _api.fetchProfile(userId);
    if (profile?.homeStationId != null) {
      await _preferences.writeHomeStation(profile!.homeStationId);
    }
    return profile;
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final saved = await _api.upsertProfile(profile);
    await _preferences.writeHomeStation(saved.homeStationId);
    await _preferences.writeAlertsEnabled(saved.peakAlertsEnabled);
    return saved;
  }

  Future<String?> cachedHomeStation() => _preferences.readHomeStation();

  Future<List<SavedRoute>> loadSavedRoutes(String userId) =>
      _api.fetchSavedRoutes(userId);

  Future<SavedRoute> saveRoute({
    required String userId,
    required String label,
    required String originStationId,
    required String destinationStationId,
    required JourneyPreference preference,
  }) {
    return _api.createSavedRoute(
      userId: userId,
      label: label,
      originStationId: originStationId,
      destinationStationId: destinationStationId,
      preference: preference,
    );
  }

  Future<void> deleteRoute(String routeId) => _api.deleteSavedRoute(routeId);

  Future<JourneyPreference> preferredJourneyType() =>
      _preferences.readJourneyPreference();

  Future<void> setPreferredJourneyType(JourneyPreference preference) =>
      _preferences.writeJourneyPreference(preference);

  Future<void> clearLocalState() => _preferences.clear();
}
