import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/features/medications/logic/daily_medications_provider.dart';
import 'package:mama_brain/src/features/medications/logic/date_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  /// Helper to build a ProviderContainer with fake medications and a selected date.
  ProviderContainer makeContainer({
    required List<Medication> medications,
    required DateTime selectedDate,
  }) {
    final container = ProviderContainer(
      overrides: [
        medicationProvider.overrideWith(
          (_) => FakeMedicationNotifier(medications),
        ),
        selectedDateProvider.overrideWith((_) => selectedDate),
      ],
    );
    return container;
  }

  group('dailyMedicationsProvider', () {
    group('oneOff medications', () {
      test('shows only on exact start date', () {
        final med = Medication(
          id: '1',
          name: 'Aspirin',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );

        // On start date — visible
        var container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 15));
        expect(container.read(dailyMedicationsProvider).length, 1);
        container.dispose();

        // Day before — hidden
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 14));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();

        // Day after — hidden
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 16));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();
      });
    });

    group('permanent medications', () {
      test('shows from start date onwards', () {
        final med = Medication(
          id: '2',
          name: 'Vitamin D',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: DateTime(2025, 6, 10),
        );

        // On start date
        var container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 10));
        expect(container.read(dailyMedicationsProvider).length, 1);
        container.dispose();

        // After start date
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 12, 25));
        expect(container.read(dailyMedicationsProvider).length, 1);
        container.dispose();

        // Before start date — hidden
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 9));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();
      });
    });

    group('temporary medications', () {
      test('shows within duration range', () {
        final med = Medication(
          id: '3',
          name: 'Amoxicillin',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 10),
          durationInDays: 5,
        );

        // Day 0 (start) — visible
        var container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 10));
        expect(container.read(dailyMedicationsProvider).length, 1);
        container.dispose();

        // Day 4 (last day) — visible
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 14));
        expect(container.read(dailyMedicationsProvider).length, 1);
        container.dispose();

        // Day 5 (end = start+5, exclusive) — hidden
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 15));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();

        // Before start — hidden
        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 9));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();
      });

      test('duration=1 shows only on start date', () {
        final med = Medication(
          id: '4',
          name: 'Single day temp',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 10),
          durationInDays: 1,
        );

        var container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 10));
        expect(container.read(dailyMedicationsProvider).length, 1);
        container.dispose();

        container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 11));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();
      });

      test('duration=0 shows on no days', () {
        final med = Medication(
          id: '5',
          name: 'Zero duration',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 10),
          durationInDays: 0,
        );

        final container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 10));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();
      });

      test('null duration treated as 0', () {
        final med = Medication(
          id: '6',
          name: 'Null duration',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 10),
          durationInDays: null,
        );

        final container =
            makeContainer(medications: [med], selectedDate: DateTime(2025, 6, 10));
        expect(container.read(dailyMedicationsProvider), isEmpty);
        container.dispose();
      });
    });

    test('mixed types are filtered correctly for a given date', () {
      final meds = [
        Medication(
          id: '1',
          name: 'OneOff Today',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        ),
        Medication(
          id: '2',
          name: 'OneOff Yesterday',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 14),
        ),
        Medication(
          id: '3',
          name: 'Permanent',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: DateTime(2025, 6, 1),
        ),
        Medication(
          id: '4',
          name: 'Temp Expired',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 1),
          durationInDays: 5,
        ),
        Medication(
          id: '5',
          name: 'Temp Active',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 13),
          durationInDays: 5,
        ),
      ];

      final container =
          makeContainer(medications: meds, selectedDate: DateTime(2025, 6, 15));
      final result = container.read(dailyMedicationsProvider);

      final names = result.map((m) => m.name).toSet();
      expect(names, contains('OneOff Today'));
      expect(names, isNot(contains('OneOff Yesterday')));
      expect(names, contains('Permanent'));
      expect(names, isNot(contains('Temp Expired')));
      expect(names, contains('Temp Active'));
      expect(result.length, 3);
      container.dispose();
    });
  });
}
