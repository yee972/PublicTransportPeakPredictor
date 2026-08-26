class RidershipDay {
  final DateTime serviceDate;
  final String lineId;
  final int riders;

  const RidershipDay({
    required this.serviceDate,
    required this.lineId,
    required this.riders,
  });

  factory RidershipDay.fromJson(Map<String, dynamic> json) => RidershipDay(
        serviceDate: DateTime.parse(json['service_date'] as String),
        lineId: json['line_id'] as String,
        riders: (json['riders'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'service_date': serviceDate.toIso8601String().substring(0, 10),
        'line_id': lineId,
        'riders': riders,
      };
}

class PublicHoliday {
  final DateTime date;
  final String name;

  const PublicHoliday({required this.date, required this.name});

  factory PublicHoliday.fromJson(Map<String, dynamic> json) => PublicHoliday(
        date: DateTime.parse(json['holiday_date'] as String),
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'holiday_date': date.toIso8601String().substring(0, 10),
        'name': name,
      };
}

class ScheduleSlot {
  final String lineId;
  final String dayType;
  final int hourOfDay;
  final int tripsPerHour;

  const ScheduleSlot({
    required this.lineId,
    required this.dayType,
    required this.hourOfDay,
    required this.tripsPerHour,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        lineId: json['line_id'] as String,
        dayType: json['day_type'] as String,
        hourOfDay: (json['hour_of_day'] as num).toInt(),
        tripsPerHour: (json['trips_per_hour'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'day_type': dayType,
        'hour_of_day': hourOfDay,
        'trips_per_hour': tripsPerHour,
      };

  static String dayTypeFor(DateTime date) {
    if (date.weekday == DateTime.saturday) return 'saturday';
    if (date.weekday == DateTime.sunday) return 'sunday';
    return 'weekday';
  }
}
