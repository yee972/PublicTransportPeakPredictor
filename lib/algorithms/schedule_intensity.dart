import 'dart:math' as math;

import '../models/ridership_day.dart';
import '../models/station.dart';

class HourIntensity {
  final int hour;
  final int trips;
  final double intensity;

  const HourIntensity({
    required this.hour,
    required this.trips,
    required this.intensity,
  });

  bool get isServiceHour => trips > 0;
}

class ScheduleIntensity {
  final Map<String, Map<String, List<int>>> _tripsByLine;
  final Map<String, List<String>> _linesByStation;
  final Map<String, int> _lineMaxTrips;
  final int _networkMaxStationTrips;

  ScheduleIntensity._(
    this._tripsByLine,
    this._linesByStation,
    this._lineMaxTrips,
    this._networkMaxStationTrips,
  );

  factory ScheduleIntensity({
    required List<ScheduleSlot> slots,
    required List<Station> stations,
  }) {
    final tripsByLine = <String, Map<String, List<int>>>{};
    for (final slot in slots) {
      final byDayType = tripsByLine.putIfAbsent(slot.lineId, () => {});
      final hours = byDayType.putIfAbsent(slot.dayType, () => List.filled(24, 0));
      if (slot.hourOfDay >= 0 && slot.hourOfDay < 24) {
        hours[slot.hourOfDay] = slot.tripsPerHour;
      }
    }

    final lineMaxTrips = <String, int>{};
    tripsByLine.forEach((lineId, byDayType) {
      var maximum = 0;
      for (final hours in byDayType.values) {
        for (final trips in hours) {
          maximum = math.max(maximum, trips);
        }
      }
      lineMaxTrips[lineId] = maximum;
    });

    final linesByStation = <String, List<String>>{
      for (final station in stations) station.id: station.lineIds,
    };

    var networkMaximum = 0;
    for (final entry in linesByStation.entries) {
      for (final dayType in const ['weekday', 'saturday', 'sunday']) {
        for (var hour = 0; hour < 24; hour++) {
          var total = 0;
          for (final lineId in entry.value) {
            total += tripsByLine[lineId]?[dayType]?[hour] ?? 0;
          }
          networkMaximum = math.max(networkMaximum, total);
        }
      }
    }

    return ScheduleIntensity._(
      tripsByLine,
      linesByStation,
      lineMaxTrips,
      math.max(networkMaximum, 1),
    );
  }

  int lineTrips(String lineId, String dayType, int hour) {
    if (hour < 0 || hour > 23) return 0;
    return _tripsByLine[lineId]?[dayType]?[hour] ?? 0;
  }

  double lineIntensity(String lineId, String dayType, int hour) {
    final maximum = _lineMaxTrips[lineId] ?? 0;
    if (maximum <= 0) return 0;
    return lineTrips(lineId, dayType, hour) / maximum;
  }

  int stationTrips(String stationId, String dayType, int hour) {
    final lines = _linesByStation[stationId] ?? const [];
    var total = 0;
    for (final lineId in lines) {
      total += lineTrips(lineId, dayType, hour);
    }
    return total;
  }

  double stationIntensity(String stationId, String dayType, int hour) {
    return stationTrips(stationId, dayType, hour) / _networkMaxStationTrips;
  }

  List<HourIntensity> stationProfile(String stationId, String dayType) {
    return List.generate(24, (hour) {
      final trips = stationTrips(stationId, dayType, hour);
      return HourIntensity(
        hour: hour,
        trips: trips,
        intensity: trips / _networkMaxStationTrips,
      );
    });
  }

  List<HourIntensity> lineProfile(String lineId, String dayType) {
    final maximum = math.max(_lineMaxTrips[lineId] ?? 1, 1);
    return List.generate(24, (hour) {
      final trips = lineTrips(lineId, dayType, hour);
      return HourIntensity(
        hour: hour,
        trips: trips,
        intensity: trips / maximum,
      );
    });
  }

  List<int> peakHours(String stationId, String dayType, {int count = 3}) {
    final profile = stationProfile(stationId, dayType)
        .where((slot) => slot.isServiceHour)
        .toList()
      ..sort((a, b) => b.trips.compareTo(a.trips));
    return profile.take(count).map((slot) => slot.hour).toList()..sort();
  }

  int dailyTrips(String lineId, String dayType) {
    var total = 0;
    for (var hour = 0; hour < 24; hour++) {
      total += lineTrips(lineId, dayType, hour);
    }
    return total;
  }

  double crowdIndex({
    required String lineId,
    required String stationId,
    required String dayType,
    required int hour,
    required double lineLoad,
  }) {
    final hourly = lineIntensity(lineId, dayType, hour);
    final interchangeLoad = stationIntensity(stationId, dayType, hour);
    return hourly * (lineLoad * 0.75 + interchangeLoad * 0.25);
  }

  static String dayTypeFor(DateTime date) => ScheduleSlot.dayTypeFor(date);
}
