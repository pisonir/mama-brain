import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/symptoms/ui/symptoms_page.dart';

void main() {
  final alice = FamilyMember(id: 'fm-1', name: 'Alice', colorValue: 0xFFFF0000);
  final bob = FamilyMember(id: 'fm-2', name: 'Bob', colorValue: 0xFF0000FF);

  Symptom s(
    String id,
    String memberId,
    SymptomType type,
    DateTime timestamp, {
    String? note,
  }) {
    return Symptom(
      id: id,
      familyMemberId: memberId,
      timestamp: timestamp,
      type: type,
      note: note,
    );
  }

  group('groupSymptomsByPerson', () {
    test('returns an empty list when there are no symptoms', () {
      expect(groupSymptomsByPerson([], [alice, bob]), isEmpty);
    });

    test('groups every symptom under its own person', () {
      final symptoms = [
        s('s1', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 8)),
        s('s2', 'fm-2', SymptomType.cough, DateTime(2025, 6, 15, 9)),
        s('s3', 'fm-1', SymptomType.rash, DateTime(2025, 6, 15, 10)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice, bob]);

      expect(sections.length, 2);
      expect(sections[0].familyMemberId, 'fm-1');
      expect(sections[0].blocks.length, 2);
      expect(sections[1].familyMemberId, 'fm-2');
      expect(sections[1].blocks.length, 1);
    });

    test('people come back in family list order, not first-seen order', () {
      // Bob logs first, but Alice is first in the family list.
      final symptoms = [
        s('s1', 'fm-2', SymptomType.fever, DateTime(2025, 6, 15, 7)),
        s('s2', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 9)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice, bob]);

      expect(sections.map((x) => x.familyMemberId).toList(), ['fm-1', 'fm-2']);
    });

    test('reordering the family reorders the sections', () {
      final symptoms = [
        s('s1', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 9)),
        s('s2', 'fm-2', SymptomType.fever, DateTime(2025, 6, 15, 7)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [bob, alice]);

      expect(sections.map((x) => x.familyMemberId).toList(), ['fm-2', 'fm-1']);
    });

    test('collapses repeats of the same symptom into one block, time-sorted',
        () {
      final symptoms = [
        s('s1', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 20)),
        s('s2', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 8)),
        s('s3', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 14)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice]);

      expect(sections.single.blocks.length, 1);
      final block = sections.single.blocks.single;
      expect(block.length, 3);
      expect(block.map((x) => x.id).toList(), ['s2', 's3', 's1']);
    });

    test('keeps different symptom types in separate blocks', () {
      final symptoms = [
        s('s1', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 8)),
        s('s2', 'fm-1', SymptomType.cough, DateTime(2025, 6, 15, 9)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice]);

      expect(sections.single.blocks.length, 2);
    });

    test("separates 'other' symptoms by their note text", () {
      final symptoms = [
        s('s1', 'fm-1', SymptomType.other, DateTime(2025, 6, 15, 8),
            note: 'Stomach ache'),
        s('s2', 'fm-1', SymptomType.other, DateTime(2025, 6, 15, 9),
            note: 'Stomach ache'),
        s('s3', 'fm-1', SymptomType.other, DateTime(2025, 6, 15, 10),
            note: 'Dizzy'),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice]);

      expect(sections.single.blocks.length, 2);
      final sizes = sections.single.blocks.map((b) => b.length).toList()..sort();
      expect(sizes, [1, 2]);
    });

    test('blocks within a person are ordered by their first occurrence', () {
      final symptoms = [
        s('s1', 'fm-1', SymptomType.rash, DateTime(2025, 6, 15, 18)),
        s('s2', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 6)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice]);

      expect(sections.single.blocks.first.first.type, SymptomType.fever);
      expect(sections.single.blocks.last.first.type, SymptomType.rash);
    });

    test('keeps symptoms of a member no longer in the family, listed last', () {
      final symptoms = [
        s('s1', 'ghost', SymptomType.fever, DateTime(2025, 6, 15, 7)),
        s('s2', 'fm-1', SymptomType.fever, DateTime(2025, 6, 15, 9)),
      ];

      final sections = groupSymptomsByPerson(symptoms, [alice]);

      expect(sections.map((x) => x.familyMemberId).toList(), ['fm-1', 'ghost']);
    });
  });
}
