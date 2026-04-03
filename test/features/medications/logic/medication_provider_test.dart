import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  const groupId = 'test-group';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  MedicationNotifier createNotifier() {
    return MedicationNotifier(groupId: groupId, firestore: fakeFirestore);
  }

  CollectionReference medsCol() => fakeFirestore
      .collection('familyGroups')
      .doc(groupId)
      .collection('medications');

  group('MedicationNotifier', () {
    group('addMedication', () {
      test('adds a oneOff medication', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Ibuprofen',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.length, 1);
        expect(notifier.state.first.name, 'Ibuprofen');
        expect(notifier.state.first.type, MedicationType.oneOff);
      });

      test('auto-checks a oneOff medication on creation', () async {
        final notifier = createNotifier();
        final startDate = DateTime(2025, 6, 15);
        await notifier.addMedication(
          name: 'Ibuprofen',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: startDate,
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs.length, 1);
        final log = notifier.state.first.takenLogs.first;
        expect(log.year, startDate.year);
        expect(log.month, startDate.month);
        expect(log.day, startDate.day);
      });

      test('does not auto-check a temporary medication', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Amoxicillin',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 15),
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs, isEmpty);
      });

      test('does not auto-check a permanent medication', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Vitamin D',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: DateTime(2025, 1, 1),
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs, isEmpty);
      });

      test('adds a temporary medication with duration', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Amoxicillin',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: DateTime(2025, 6, 10),
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.type, MedicationType.temporary);
        expect(notifier.state.first.durationInDays, 7);
      });

      test('adds a permanent medication', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Vitamin D',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: DateTime(2025, 1, 1),
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.type, MedicationType.permanent);
        expect(notifier.state.first.durationInDays, isNull);
      });

      test('generates a UUID', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Test',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.id.length, 36);
      });

      test('persists to Firestore', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Persisted Med',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );

        final snap = await medsCol().get();
        expect(snap.docs.length, 1);
        expect((snap.docs.first.data() as Map)['name'], 'Persisted Med');
      });
    });

    group('editMedication', () {
      test('updates name and persists', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Old Name',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.editMedication(
          id: id,
          name: 'New Name',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          originalStartDate: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.name, 'New Name');
        final doc = await medsCol().doc(id).get();
        expect((doc.data() as Map)['name'], 'New Name');
      });
    });

    group('deleteMedication', () {
      test('fully deletes a oneOff medication', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'To Delete',
          familyMemberId: 'fm-1',
          type: MedicationType.oneOff,
          startDate: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteMedication(id);

        final snap = await medsCol().get();
        expect(snap.docs, isEmpty);
      });

      test('preserves past history when deleting a permanent medication', () async {
        final notifier = createNotifier();
        final startDate = DateTime(2025, 1, 1);
        await notifier.addMedication(
          name: 'Vitamin D',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: startDate,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteMedication(id);
        await Future.delayed(Duration.zero);

        // Document must still exist (past history preserved)
        final snap = await medsCol().get();
        expect(snap.docs.length, 1);

        // Must be converted to temporary type
        final data = snap.docs.first.data() as Map<String, dynamic>;
        expect(data['type'], MedicationType.temporary.name);

        // Duration covers startDate up to (but not including) today
        final now = DateTime.now();
        final normalizedToday = DateTime(now.year, now.month, now.day);
        final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
        final expectedDays = normalizedToday.difference(normalizedStart).inDays;
        expect(data['durationInDays'], expectedDays);
      });

      test('preserves past history when deleting a temporary medication that extends into the future', () async {
        final notifier = createNotifier();
        final startDate = DateTime(2025, 1, 1);
        await notifier.addMedication(
          name: 'Antibiotic',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: startDate,
          durationInDays: 3650, // extends well into the future
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteMedication(id);
        await Future.delayed(Duration.zero);

        // Document must still exist
        final snap = await medsCol().get();
        expect(snap.docs.length, 1);

        // Duration must be truncated to past-only
        final data = snap.docs.first.data() as Map<String, dynamic>;
        expect(data['type'], MedicationType.temporary.name);
        final now = DateTime.now();
        final normalizedToday = DateTime(now.year, now.month, now.day);
        final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
        final expectedDays = normalizedToday.difference(normalizedStart).inDays;
        expect(data['durationInDays'], expectedDays);
      });

      test('does not extend an already-ended temporary medication on deletion', () async {
        final notifier = createNotifier();
        // Medication ran Jan 1–3 (3 days), deleted well after it ended
        final startDate = DateTime(2025, 1, 1);
        const originalDuration = 3;
        await notifier.addMedication(
          name: 'Short Course',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: startDate,
          durationInDays: originalDuration,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteMedication(id);
        await Future.delayed(Duration.zero);

        // Document must still exist
        final snap = await medsCol().get();
        expect(snap.docs.length, 1);

        // Duration must NOT exceed the original duration
        final data = snap.docs.first.data() as Map<String, dynamic>;
        expect(data['type'], MedicationType.temporary.name);
        expect(data['durationInDays'], originalDuration);
      });

      test('fully deletes a permanent medication that starts today or in the future', () async {
        final notifier = createNotifier();
        final today = DateTime.now();
        await notifier.addMedication(
          name: 'Vitamin D',
          familyMemberId: 'fm-1',
          type: MedicationType.permanent,
          startDate: today,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteMedication(id);

        final snap = await medsCol().get();
        expect(snap.docs, isEmpty);
      });
    });

    group('toggleTaken', () {
      late DateTime today;

      setUp(() {
        final now = DateTime.now();
        today = DateTime(now.year, now.month, now.day);
      });

      test('adds a log when none exists for that day', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: today,
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.toggleTaken(id, today);
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs.length, 1);
      });

      test('removes a log when one already exists for that day', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: today,
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.toggleTaken(id, today);
        await Future.delayed(Duration.zero);
        expect(notifier.state.first.takenLogs.length, 1);

        await notifier.toggleTaken(id, today);
        await Future.delayed(Duration.zero);
        expect(notifier.state.first.takenLogs.length, 0);
      });

      test('matches by year/month/day only, ignoring time', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: today,
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.toggleTaken(id, today.add(const Duration(hours: 8)));
        await Future.delayed(Duration.zero);
        expect(notifier.state.first.takenLogs.length, 1);

        await notifier.toggleTaken(id, today.add(const Duration(hours: 20)));
        await Future.delayed(Duration.zero);
        expect(notifier.state.first.takenLogs.length, 0);
      });

      test('stores the exact takenAt timestamp when provided', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Toggle Med',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: today,
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        final specificTime = DateTime(today.year, today.month, today.day, 14, 30);
        await notifier.toggleTaken(id, today, takenAt: specificTime);
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs.length, 1);
        expect(notifier.state.first.takenLogs.first, specificTime);
      });
    });

    group('setTakenTime', () {
      late DateTime today;

      setUp(() {
        final now = DateTime.now();
        today = DateTime(now.year, now.month, now.day);
      });

      test('updates the log entry to the new time', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Med',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: today,
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        final originalTime = DateTime(today.year, today.month, today.day, 9, 0);
        await notifier.toggleTaken(id, today, takenAt: originalTime);
        await Future.delayed(Duration.zero);
        expect(notifier.state.first.takenLogs.first, originalTime);

        final newTime = DateTime(today.year, today.month, today.day, 15, 45);
        await notifier.setTakenTime(id, today, newTime);
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs.length, 1);
        expect(notifier.state.first.takenLogs.first, newTime);
      });

      test('is a no-op when no log exists for the given date', () async {
        final notifier = createNotifier();
        await notifier.addMedication(
          name: 'Med',
          familyMemberId: 'fm-1',
          type: MedicationType.temporary,
          startDate: today,
          durationInDays: 7,
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        final newTime = DateTime(today.year, today.month, today.day, 10, 0);
        await notifier.setTakenTime(id, today, newTime);
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.takenLogs, isEmpty);
      });
    });
  });
}
