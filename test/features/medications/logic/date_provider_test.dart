import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/features/medications/logic/date_provider.dart';

void main() {
  group('getWeekDatesFrom', () {
    test('returns exactly 5 dates', () {
      final dates = getWeekDatesFrom(DateTime(2025, 6, 15));
      expect(dates.length, 5);
    });

    test('center date is at index 2', () {
      final center = DateTime(2025, 6, 15);
      final dates = getWeekDatesFrom(center);
      expect(dates[2].year, center.year);
      expect(dates[2].month, center.month);
      expect(dates[2].day, center.day);
    });

    test('dates are in ascending order', () {
      final dates = getWeekDatesFrom(DateTime(2025, 6, 15));
      for (int i = 0; i < dates.length - 1; i++) {
        expect(dates[i].isBefore(dates[i + 1]), isTrue);
      }
    });

    test('handles month boundary (center = March 1)', () {
      final dates = getWeekDatesFrom(DateTime(2025, 3, 1));
      expect(dates[0], DateTime(2025, 2, 27));
      expect(dates[1], DateTime(2025, 2, 28));
      expect(dates[2], DateTime(2025, 3, 1));
      expect(dates[3], DateTime(2025, 3, 2));
      expect(dates[4], DateTime(2025, 3, 3));
    });

    test('handles year boundary (center = Jan 1)', () {
      final dates = getWeekDatesFrom(DateTime(2025, 1, 1));
      expect(dates[0].year, 2024);
      expect(dates[0].month, 12);
      expect(dates[0].day, 30);
      expect(dates[1], DateTime(2024, 12, 31));
      expect(dates[2], DateTime(2025, 1, 1));
    });
  });

  group('selectedDateProvider', () {
    test('initial value is today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selected = container.read(selectedDateProvider);
      final now = DateTime.now();
      expect(selected.year, now.year);
      expect(selected.month, now.month);
      expect(selected.day, now.day);
    });
  });

  group('dateStripCenterProvider', () {
    test('initial value is today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final center = container.read(dateStripCenterProvider);
      final now = DateTime.now();
      expect(center.year, now.year);
      expect(center.month, now.month);
      expect(center.day, now.day);
    });
  });
}
