import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await setUpHive();
    await openMedicationBox();
  });

  tearDown(() async {
    await tearDownHive(tempDir);
  });

  group('MedicationNotifier', () {
    group('addMedication', () {
      test('adds a oneOff medication', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Ibuprofen',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );

        expect(notifier.debugState.length, 1);
        expect(notifier.debugState.first.name, 'Ibuprofen');
        expect(notifier.debugState.first.type, MedicationType.oneOff);
      });

      test('adds a temporary medication with duration', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Amoxicillin',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 10),
          durationInDays: 7,
        );

        expect(notifier.debugState.first.type, MedicationType.temporary);
        expect(notifier.debugState.first.durationInDays, 7);
      });

      test('adds a permanent medication', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Vitamin D',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: DateTime(2025, 1, 1),
        );

        expect(notifier.debugState.first.type, MedicationType.permanent);
        expect(notifier.debugState.first.durationInDays, isNull);
      });

      test('generates a UUID', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Test',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );

        expect(notifier.debugState.first.id.length, 36);
      });

      test('persists to Hive', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Persisted Med',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );

        final box = Hive.box<Medication>('medications');
        expect(box.length, 1);
        expect(box.values.first.name, 'Persisted Med');
      });
    });

    group('editMedication', () {
      test('updates name and persists', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Old Name',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        final id = notifier.debugState.first.id;

        await notifier.editMedication(
          id: id,
          name: 'New Name',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          originalStartDate: DateTime(2025, 6, 15),
        );

        expect(notifier.debugState.first.name, 'New Name');
        final box = Hive.box<Medication>('medications');
        expect(box.get(id)!.name, 'New Name');
      });

      test('preserves position in list', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'First',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        await notifier.addMedication(
          name: 'Second',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 16),
        );
        final secondId = notifier.debugState[1].id;

        await notifier.editMedication(
          id: secondId,
          name: 'Second Edited',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          originalStartDate: DateTime(2025, 6, 16),
        );

        expect(notifier.debugState[0].name, 'First');
        expect(notifier.debugState[1].name, 'Second Edited');
      });
    });

    group('deleteMedication', () {
      test('removes from state and Hive', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'To Delete',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        final id = notifier.debugState.first.id;

        await notifier.deleteMedication(id);

        expect(notifier.debugState, isEmpty);
        final box = Hive.box<Medication>('medications');
        expect(box.length, 0);
      });
    });

    group('toggleTaken', () {
      // NOTE: toggleTaken adds DateTime.now() as the log timestamp, so we must
      // use today's date when toggling so the day-match comparison works.
      late DateTime today;

      setUp(() {
        final now = DateTime.now();
        today = DateTime(now.year, now.month, now.day);
      });

      test('adds a log when none exists for that day', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: today,
        );
        final id = notifier.debugState.first.id;

        await notifier.toggleTaken(id, today);

        expect(notifier.debugState.first.takenLogs.length, 1);
      });

      test('removes a log when one already exists for that day', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: today,
        );
        final id = notifier.debugState.first.id;

        // Toggle on
        await notifier.toggleTaken(id, today);
        expect(notifier.debugState.first.takenLogs.length, 1);

        // Toggle off — matches the log added by DateTime.now()
        await notifier.toggleTaken(id, today);
        expect(notifier.debugState.first.takenLogs.length, 0);
      });

      test('matches by year/month/day only, ignoring time', () async {
        final notifier = MedicationNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: today,
        );
        final id = notifier.debugState.first.id;

        // Toggle on with morning time
        await notifier.toggleTaken(id, today.add(const Duration(hours: 8)));
        expect(notifier.debugState.first.takenLogs.length, 1);

        // Toggle off with evening time on the same day
        await notifier.toggleTaken(id, today.add(const Duration(hours: 20)));
        expect(notifier.debugState.first.takenLogs.length, 0);
      });
    });
  });
}
