import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/utils/recurring_schedule.dart';

void main() {
  test('monthly schedule clamps a day that is missing next month', () {
    final next = calculateNextRecurringDate(
      DateTime(2026, 1, 31),
      'Hằng tháng',
    );

    expect(next, DateTime(2026, 2, 28));
  });

  test('yearly schedule clamps leap day in a non-leap year', () {
    final next = calculateNextRecurringDate(DateTime(2024, 2, 29), 'Hằng năm');

    expect(next, DateTime(2025, 2, 28));
  });

  test('schedule accepts its end date and rejects later dates', () {
    final endDate = DateTime(2026, 6, 30, 8);

    expect(
      isRecurringDateWithinSchedule(DateTime(2026, 6, 30, 20), endDate),
      isTrue,
    );
    expect(
      isRecurringDateWithinSchedule(DateTime(2026, 7, 1), endDate),
      isFalse,
    );
  });
}
