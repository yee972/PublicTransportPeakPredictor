import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';

import '../../models/ridership_day.dart';
import 'reference_api.dart';

class RidershipApi {
  final SupabaseClient _client;

  RidershipApi(this._client);

  static const int _linesPerDay = 8;

  Future<List<RidershipDay>> fetchRidership({int days = 400}) async {
    try {
      final rows = await _client
          .from('ridership_daily')
          .select()
          .order('service_date', ascending: false)
          .limit(days * _linesPerDay)
          .timeout(AppConfig.requestTimeout);
      return rows.map<RidershipDay>((row) => RidershipDay.fromJson(row)).toList();
    } on PostgrestException catch (error) {
      throw DataFailure('Could not load ridership: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not load ridership. Check your connection.');
    }
  }

  Future<List<PublicHoliday>> fetchHolidays() async {
    try {
      final rows = await _client
          .from('public_holidays')
          .select()
          .order('holiday_date')
          .timeout(AppConfig.requestTimeout);
      return rows.map<PublicHoliday>((row) => PublicHoliday.fromJson(row)).toList();
    } on PostgrestException catch (error) {
      throw DataFailure('Could not load holidays: ${error.message}');
    } catch (_) {
      throw const DataFailure('Could not load holidays. Check your connection.');
    }
  }
}
