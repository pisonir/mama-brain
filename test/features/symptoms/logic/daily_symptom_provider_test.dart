import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/medications/logic/date_provider.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  ProviderContainer makeContainer({
    required List<Symptom> symptoms,
    required DateTime selectedDate,
  }) {
    return ProviderContainer(
      overrides: [
        symptomProvider.overrideWith(
          (_) => FakeSymptomNotifier(symptoms),
        ),
        selectedDateProvider.overrideWith((_) => selectedDate),
      ],
    );
  }

  group('dailySymptomProvider', () {
    test('filters symptoms by matching year/month/day', () {
      final symptoms = [
        Symptom(
          id: '1',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 15, 10, 0),
          type: SymptomType.fever,
        ),
        Symptom(
          id: '2',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 15, 14, 0),
          type: SymptomType.cough,
        ),
        Symptom(
          id: '3',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 16, 9, 0),
          type: SymptomType.pain,
        ),
      ];

      final container =
          makeContainer(symptoms: symptoms, selectedDate: DateTime(2025, 6, 15));
      final result = container.read(dailySymptomProvider);

      expect(result.length, 2);
      expect(result.map((s) => s.type).toSet(),
          {SymptomType.fever, SymptomType.cough});
      container.dispose();
    });

    test('sorts descending by timestamp (latest first)', () {
      final symptoms = [
        Symptom(
          id: '1',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 15, 8, 0),
          type: SymptomType.fever,
        ),
        Symptom(
          id: '2',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 15, 16, 0),
          type: SymptomType.cough,
        ),
        Symptom(
          id: '3',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 15, 12, 0),
          type: SymptomType.pain,
        ),
      ];

      final container =
          makeContainer(symptoms: symptoms, selectedDate: DateTime(2025, 6, 15));
      final result = container.read(dailySymptomProvider);

      expect(result[0].id, '2'); // 16:00
      expect(result[1].id, '3'); // 12:00
      expect(result[2].id, '1'); // 08:00
      container.dispose();
    });

    test('returns empty list when no symptoms match', () {
      final symptoms = [
        Symptom(
          id: '1',
          familyMemberId: 'fm-1',
          timestamp: DateTime(2025, 6, 14),
          type: SymptomType.rash,
        ),
      ];

      final container =
          makeContainer(symptoms: symptoms, selectedDate: DateTime(2025, 6, 15));
      expect(container.read(dailySymptomProvider), isEmpty);
      container.dispose();
    });

    test('returns empty list when symptoms list is empty', () {
      final container =
          makeContainer(symptoms: [], selectedDate: DateTime(2025, 6, 15));
      expect(container.read(dailySymptomProvider), isEmpty);
      container.dispose();
    });
  });
}
