const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Groups digits with commas: 1234567.8 → "1,234,568".
String groupDigits(double value, {int decimals = 0}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  final grouped = parts.length > 1 ? '$buffer.${parts[1]}' : '$buffer';
  return negative ? '-$grouped' : grouped;
}

/// "Rs 12,400"
String rs(double value, {bool hidden = false}) =>
    hidden ? 'Rs ••••' : 'Rs ${groupDigits(value)}';

String monthShort(int month) => _months[month - 1];
String monthLong(int month) => _monthsLong[month - 1];
String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

/// "Thursday, 19 November"
String longDate(DateTime d) =>
    '${_weekdaysLong[d.weekday - 1]}, ${d.day} ${_monthsLong[d.month - 1]}';

/// "19 Nov"
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Today", "Yesterday", or "19 Nov".
String relativeDay(DateTime d, {DateTime? now}) {
  final today = dayOnly(now ?? DateTime.now());
  final diff = today.difference(dayOnly(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  if (d.year != today.year) return '${shortDate(d)} ${d.year}';
  return shortDate(d);
}

String greeting(DateTime now) {
  final h = now.hour;
  if (h < 5) return 'Good night';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
