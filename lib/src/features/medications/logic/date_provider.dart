import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Return a list containing 5 days: 2 days ago, yesterday, today, tomorrow, the day after tomorrow
List<DateTime> getWeekDatesFrom(DateTime centerDate) {
  return [
    centerDate.subtract(const Duration(days: 2)),
    centerDate.subtract(const Duration(days: 1)),
    centerDate,
    centerDate.add(const Duration(days: 1)),
    centerDate.add(const Duration(days: 2)),
  ];
}

final dateStripCenterProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
