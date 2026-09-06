import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';

import '../../models/journey.dart';
import '../../models/user_profile.dart';
import 'reference_api.dart';

class AccountApi {
  final SupabaseClient _client;

  AccountApi(this._client);

  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(AppConfig.requestTimeout);
      if (row == null) return null;
      return UserProfile.fromJson(row);
    } on PostgrestException catch (error) {
      throw DataFailure('Could not load your profile: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not load your profile. Check your connection.');
    }
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    try {
      final row = await _client
          .from('profiles')
          .upsert(profile.toJson())
          .select()
          .single()
          .timeout(AppConfig.requestTimeout);
      return UserProfile.fromJson(row);
    } on PostgrestException catch (error) {
      throw DataFailure('Could not save your profile: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not save your profile. Check your connection.');
    }
  }

  Future<List<SavedRoute>> fetchSavedRoutes(String userId) async {
    try {
      final rows = await _client
          .from('saved_routes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .timeout(AppConfig.requestTimeout);
      return rows.map<SavedRoute>((row) => SavedRoute.fromJson(row)).toList();
    } on PostgrestException catch (error) {
      throw DataFailure('Could not load saved routes: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not load saved routes. Check your connection.');
    }
  }

  Future<SavedRoute> createSavedRoute({
    required String userId,
    required String label,
    required String originStationId,
    required String destinationStationId,
    required JourneyPreference preference,
  }) async {
    try {
      final row = await _client
          .from('saved_routes')
          .insert({
            'user_id': userId,
            'label': label,
            'origin_station_id': originStationId,
            'destination_station_id': destinationStationId,
            'preference': preference.storageValue,
          })
          .select()
          .single()
          .timeout(AppConfig.requestTimeout);
      return SavedRoute.fromJson(row);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const DataFailure('You already saved a route with that name.');
      }
      throw DataFailure('Could not save this route: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not save this route. Check your connection.');
    }
  }

  Future<void> deleteSavedRoute(String routeId) async {
    try {
      await _client
          .from('saved_routes')
          .delete()
          .eq('id', routeId)
          .timeout(AppConfig.requestTimeout);
    } on PostgrestException catch (error) {
      throw DataFailure('Could not delete this route: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not delete this route. Check your connection.');
    }
  }
}
