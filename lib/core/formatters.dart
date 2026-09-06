class Formatters {
  static const List<String> _weekdays = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];

  static const List<String> _weekdayLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String thousands(int value) {
    final negative = value < 0;
    final text = value.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
      buffer.write(text[index]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

  static String weekdayLong(DateTime date) => _weekdayLong[date.weekday - 1];

  static String dayMonth(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  static String dayMonthYear(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static String fullDate(DateTime date) =>
      '${weekdayLong(date)}, ${date.day} ${_months[date.month - 1]} ${date.year}';

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  static String hourLabel(int hour) {
    if (hour == 0) return '12am';
    if (hour == 12) return '12pm';
    if (hour < 12) return '${hour}am';
    return '${hour - 12}pm';
  }

  static String hourRange(int hour) =>
      '${hourLabel(hour)} - ${hourLabel((hour + 1) % 24)}';

  static String percent(double fraction, {int decimals = 0}) =>
      '${(fraction * 100).toStringAsFixed(decimals)}%';

  static String signedPercent(double fraction) {
    final value = fraction * 100;
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  static String dayTypeLabel(String dayType) {
    switch (dayType) {
      case 'saturday':
        return 'Saturday';
      case 'sunday':
        return 'Sunday';
      default:
        return 'Weekday';
    }
  }
}
