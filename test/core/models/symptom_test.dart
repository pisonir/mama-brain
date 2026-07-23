import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/symptom.dart';

void main() {
  group('SymptomTypeLabel', () {
    test('every symptom type has a Title Case label', () {
      const expected = {
        SymptomType.fever: 'Fever',
        SymptomType.cough: 'Cough',
        SymptomType.vomit: 'Vomit',
        SymptomType.diarrhea: 'Diarrhea',
        SymptomType.pain: 'Pain',
        SymptomType.rash: 'Rash',
        SymptomType.other: 'Other',
      };

      // Guards against adding a new SymptomType without a label.
      expect(expected.keys.toSet(), SymptomType.values.toSet());

      for (final entry in expected.entries) {
        expect(entry.key.label, entry.value);
      }
    });

    test('labels start with an uppercase letter and are not all-caps', () {
      for (final type in SymptomType.values) {
        final label = type.label;
        expect(label[0], label[0].toUpperCase(),
            reason: '${type.name} label should start uppercase');
        expect(label == label.toUpperCase() && label.length > 1, isFalse,
            reason: '${type.name} label should not be ALL CAPS');
      }
    });
  });
}
