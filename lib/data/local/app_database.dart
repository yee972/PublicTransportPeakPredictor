import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/rail_edge.dart';
import '../../models/rail_line.dart';
import '../../models/ridership_day.dart';
import '../../models/station.dart';

class AppDatabase {
  static const String _fileName = 'peak_predictor.db';
  static const int _version = 1;

  static final AppDatabase instance = AppDatabase._();

  AppDatabase._();

  static bool get isSupported => !kIsWeb;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _fileName),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rail_lines(
            id TEXT PRIMARY KEY, code TEXT, name TEXT, short_name TEXT,
            colour TEXT, operator TEXT, data_key TEXT, series_id TEXT,
            sort_order INTEGER)
        ''');
        await db.execute('''
          CREATE TABLE stations(
            id TEXT PRIMARY KEY, name TEXT, latitude REAL, longitude REAL,
            transfer_seconds INTEGER, line_ids TEXT)
        ''');
        await db.execute('''
          CREATE TABLE rail_edges(
            line_id TEXT, from_station_id TEXT, to_station_id TEXT,
            travel_seconds INTEGER, distance_metres INTEGER,
            PRIMARY KEY(line_id, from_station_id, to_station_id))
        ''');
        await db.execute('''
          CREATE TABLE station_links(
            from_station_id TEXT, to_station_id TEXT, walk_seconds INTEGER,
            PRIMARY KEY(from_station_id, to_station_id))
        ''');
        await db.execute('''
          CREATE TABLE ridership_daily(
            service_date TEXT, line_id TEXT, riders INTEGER,
            PRIMARY KEY(service_date, line_id))
        ''');
        await db.execute('''
          CREATE TABLE public_holidays(holiday_date TEXT PRIMARY KEY, name TEXT)
        ''');
        await db.execute('''
          CREATE TABLE schedule_frequency(
            line_id TEXT, day_type TEXT, hour_of_day INTEGER,
            trips_per_hour INTEGER,
            PRIMARY KEY(line_id, day_type, hour_of_day))
        ''');
        await db.execute('''
          CREATE TABLE cache_metadata(table_name TEXT PRIMARY KEY, synced_at TEXT)
        ''');
      },
    );
  }

  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    if (!isSupported) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table);
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      await txn.insert(
        'cache_metadata',
        {'table_name': table, 'synced_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<DateTime?> lastSyncedAt(String table) async {
    if (!isSupported) return null;
    final db = await database;
    final rows = await db.query(
      'cache_metadata',
      where: 'table_name = ?',
      whereArgs: [table],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['synced_at'] as String);
  }

  Future<List<RailLine>> readLines() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('rail_lines', orderBy: 'sort_order ASC');
    return rows.map(RailLine.fromJson).toList();
  }

  Future<List<Station>> readStations() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('stations', orderBy: 'name ASC');
    return rows.map(Station.fromJson).toList();
  }

  Future<List<RailEdge>> readEdges() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('rail_edges');
    return rows.map(RailEdge.fromJson).toList();
  }

  Future<List<StationLink>> readLinks() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('station_links');
    return rows.map(StationLink.fromJson).toList();
  }

  Future<List<RidershipDay>> readRidership() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('ridership_daily', orderBy: 'service_date ASC');
    return rows.map(RidershipDay.fromJson).toList();
  }

  Future<List<PublicHoliday>> readHolidays() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('public_holidays');
    return rows.map(PublicHoliday.fromJson).toList();
  }

  Future<List<ScheduleSlot>> readSchedule() async {
    if (!isSupported) return const [];
    final db = await database;
    final rows = await db.query('schedule_frequency');
    return rows.map(ScheduleSlot.fromJson).toList();
  }

  Future<bool> get hasNetworkCache async {
    if (!isSupported) return false;
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM stations');
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<void> clear() async {
    if (!isSupported) return;
    final db = await database;
    for (final table in const [
      'rail_lines',
      'stations',
      'rail_edges',
      'station_links',
      'ridership_daily',
      'public_holidays',
      'schedule_frequency',
      'cache_metadata',
    ]) {
      await db.delete(table);
    }
  }
}
