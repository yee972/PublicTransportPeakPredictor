import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';

import '../../models/rail_edge.dart';
import '../../models/rail_line.dart';
import '../../models/ridership_day.dart';
import '../../models/station.dart';

class DataFailure implements Exception {
  final String message;

  const DataFailure(this.message);

  @override
  String toString() => message;
}

class ReferenceApi {
  final SupabaseClient _client;

  ReferenceApi(this._client);

  Future<List<RailLine>> fetchLines() async {
    return _guard('rail lines', () async {
      final rows = await _client.from('rail_lines').select().order('sort_order', ascending: true);
      return rows.map<RailLine>((row) => RailLine.fromJson(row)).toList();
    });
  }

  Future<List<Station>> fetchStations() async {
    return _guard('stations', () async {
      final stationRows = await _client.from('stations').select().order('name', ascending: true);
      final lineRows = await _client
          .from('station_lines')
          .select()
          .order('line_id', ascending: true)
          .order('stop_sequence', ascending: true);

      final linesByStation = <String, List<String>>{};
      for (final row in lineRows) {
        final stationId = row['station_id'] as String;
        linesByStation.putIfAbsent(stationId, () => []).add(row['line_id'] as String);
      }

      return stationRows.map<Station>((row) {
        final station = Station.fromJson(row);
        return station.withLines(linesByStation[station.id] ?? const []);
      }).toList();
    });
  }

  Future<List<StationLine>> fetchStationLines() async {
    return _guard('station lines', () async {
      final rows = await _client
          .from('station_lines')
          .select()
          .order('line_id', ascending: true)
          .order('stop_sequence', ascending: true);
      return rows.map<StationLine>((row) => StationLine.fromJson(row)).toList();
    });
  }

  Future<List<RailEdge>> fetchEdges() async {
    return _guard('rail edges', () async {
      final rows = await _client.from('rail_edges').select();
      return rows.map<RailEdge>((row) => RailEdge.fromJson(row)).toList();
    });
  }

  Future<List<StationLink>> fetchLinks() async {
    return _guard('station links', () async {
      final rows = await _client.from('station_links').select();
      return rows.map<StationLink>((row) => StationLink.fromJson(row)).toList();
    });
  }

  Future<List<ScheduleSlot>> fetchSchedule() async {
    return _guard('service frequency', () async {
      final rows = await _client
          .from('schedule_frequency')
          .select()
          .order('line_id', ascending: true)
          .order('hour_of_day', ascending: true);
      return rows.map<ScheduleSlot>((row) => ScheduleSlot.fromJson(row)).toList();
    });
  }

  static Future<T> _guard<T>(String label, Future<T> Function() action) async {
    try {
      return await action().timeout(AppConfig.requestTimeout);
    } on PostgrestException catch (error) {
      throw DataFailure('Could not load $label: ${error.message}');
    } catch (_) {
      throw DataFailure('Could not load $label. Check your connection.');
    }
  }
}
