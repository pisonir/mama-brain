import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await setUpHive();
    await openSymptomBox();
  });

  tearDown(() async {
    await tearDownHive(tempDir);
  });

  group('SymptomNotifier', () {
    group('addSymptom', () {
      test('adds symptom with data map and note', () async {
        final notifier = SymptomNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.fever,
          timestamp: DateTime(2025, 6, 15, 10, 30),
          data: {'temp': 38.5},
          note: 'After lunch',
        );

        expect(notifier.debugState.length, 1);
        final s = notifier.debugState.first;
        expect(s.type, SymptomType.fever);
        expect(s.data['temp'], 38.5);
        expect(s.note, 'After lunch');
      });

      test('generates a UUID', () async {
        final notifier = SymptomNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.cough,
          timestamp: DateTime(2025, 6, 15),
        );

        expect(notifier.debugState.first.id.length, 36);
      });

      test('persists to Hive', () async {
        final notifier = SymptomNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.rash,
          timestamp: DateTime(2025, 6, 15),
        );

        final box = Hive.box<Symptom>('symptoms');
        expect(box.length, 1);
        expect(box.values.first.type, SymptomType.rash);
      });
    });

    group('editSymptom', () {
      test('updates fields and persists', () async {
        final notifier = SymptomNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.fever,
          timestamp: DateTime(2025, 6, 15, 10, 0),
          data: {'temp': 37.5},
        );
        final id = notifier.debugState.first.id;

        await notifier.editSymptom(
          id: id,
          familyMemberId: 'fm-1',
          type: SymptomType.fever,
          timestamp: DateTime(2025, 6, 15, 14, 0),
          data: {'temp': 39.0},
          note: 'Getting worse',
        );

        final s = notifier.debugState.first;
        expect(s.data['temp'], 39.0);
        expect(s.note, 'Getting worse');
        expect(s.timestamp.hour, 14);

        final box = Hive.box<Symptom>('symptoms');
        expect(box.get(id)!.data['temp'], 39.0);
      });

      test('preserves position in list', () async {
        final notifier = SymptomNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.cough,
          timestamp: DateTime(2025, 6, 15),
        );
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.pain,
          timestamp: DateTime(2025, 6, 16),
        );
        final secondId = notifier.debugState[1].id;

        await notifier.editSymptom(
          id: secondId,
          familyMemberId: 'fm-1',
          type: SymptomType.vomit,
          timestamp: DateTime(2025, 6, 16),
        );

        expect(notifier.debugState[0].type, SymptomType.cough);
        expect(notifier.debugState[1].type, SymptomType.vomit);
      });
    });

    group('deleteSymptom', () {
      test('removes from state and Hive', () async {
        final notifier = SymptomNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.other,
          timestamp: DateTime(2025, 6, 15),
        );
        final id = notifier.debugState.first.id;

        await notifier.deleteSymptom(id);

        expect(notifier.debugState, isEmpty);
        final box = Hive.box<Symptom>('symptoms');
        expect(box.length, 0);
      });
    });
  });
}
