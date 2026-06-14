import 'dart:math' as math;

DateTime calculateNextRecurringDate(DateTime current, String frequency) {
  final normalizedFrequency = frequency.toLowerCase();
  if (normalizedFrequency.contains('ngày') ||
      normalizedFrequency.contains('daily')) {
    return current.add(const Duration(days: 1));
  }
  if (normalizedFrequency.contains('tuần') ||
      normalizedFrequency.contains('weekly')) {
    return current.add(const Duration(days: 7));
  }
  if (normalizedFrequency.contains('năm') ||
      normalizedFrequency.contains('yearly')) {
    return _clampedDate(current.year + 1, current.month, current.day);
  }

  var year = current.year;
  var month = current.month + 1;
  if (month > 12) {
    year += 1;
    month = 1;
  }
  return _clampedDate(year, month, current.day);
}

bool isRecurringDateWithinSchedule(DateTime dueDate, DateTime? endDate) {
  if (endDate == null) return true;
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  return !due.isAfter(end);
}

DateTime _clampedDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(day, lastDay));
}
