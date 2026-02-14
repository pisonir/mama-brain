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
      test('removes from Firestore', () async {
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
          type: MedicationType.oneOff,
          startDate: today,
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
          type: MedicationType.oneOff,
          startDate: today,
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
          type: MedicationType.oneOff,
          startDate: today,
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
    });
  });
}
