import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  const groupId = 'test-group';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  SymptomNotifier createNotifier() {
    return SymptomNotifier(groupId: groupId, firestore: fakeFirestore);
  }

  CollectionReference symptomsCol() => fakeFirestore
      .collection('familyGroups')
      .doc(groupId)
      .collection('symptoms');

  group('SymptomNotifier', () {
    group('addSymptom', () {
      test('adds symptom with data map and note', () async {
        final notifier = createNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.fever,
          timestamp: DateTime(2025, 6, 15, 10, 30),
          data: {'temp': 38.5},
          note: 'After lunch',
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.length, 1);
        final s = notifier.state.first;
        expect(s.type, SymptomType.fever);
        expect(s.data['temp'], 38.5);
        expect(s.note, 'After lunch');
      });

      test('generates a UUID', () async {
        final notifier = createNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.cough,
          timestamp: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);

        expect(notifier.state.first.id.length, 36);
      });

      test('persists to Firestore', () async {
        final notifier = createNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.rash,
          timestamp: DateTime(2025, 6, 15),
        );

        final snap = await symptomsCol().get();
        expect(snap.docs.length, 1);
        expect((snap.docs.first.data() as Map)['type'], 'rash');
      });
    });

    group('editSymptom', () {
      test('updates fields and persists', () async {
        final notifier = createNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.fever,
          timestamp: DateTime(2025, 6, 15, 10, 0),
          data: {'temp': 37.5},
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.editSymptom(
          id: id,
          familyMemberId: 'fm-1',
          type: SymptomType.fever,
          timestamp: DateTime(2025, 6, 15, 14, 0),
          data: {'temp': 39.0},
          note: 'Getting worse',
        );
        await Future.delayed(Duration.zero);

        final s = notifier.state.first;
        expect(s.data['temp'], 39.0);
        expect(s.note, 'Getting worse');

        final doc = await symptomsCol().doc(id).get();
        expect((doc.data() as Map)['data']['temp'], 39.0);
      });
    });

    group('deleteSymptom', () {
      test('removes from Firestore', () async {
        final notifier = createNotifier();
        await notifier.addSymptom(
          familyMemberId: 'fm-1',
          type: SymptomType.other,
          timestamp: DateTime(2025, 6, 15),
        );
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteSymptom(id);

        final snap = await symptomsCol().get();
        expect(snap.docs, isEmpty);
      });
    });
  });
}
