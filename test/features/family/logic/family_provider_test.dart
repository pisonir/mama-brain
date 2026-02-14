import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  const groupId = 'test-group';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  FamilyNotifier createNotifier() {
    return FamilyNotifier(groupId: groupId, firestore: fakeFirestore);
  }

  group('FamilyNotifier', () {
    group('loadMembers', () {
      test('empty collection produces empty state', () async {
        final notifier = createNotifier();
        await Future.delayed(Duration.zero);
        expect(notifier.state, isEmpty);
      });

      test('pre-populated collection loads into state', () async {
        await fakeFirestore
            .collection('familyGroups')
            .doc(groupId)
            .collection('members')
            .doc('pre-1')
            .set({'name': 'Alice', 'colorValue': 0xFFFF0000});

        final notifier = createNotifier();
        await Future.delayed(Duration.zero);

        expect(notifier.state.length, 1);
        expect(notifier.state.first.name, 'Alice');
      });
    });

    group('addMember', () {
      test('appends member to Firestore and state updates via snapshot', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'Bob', colorValue: 0xFF00FF00);
        await Future.delayed(Duration.zero);

        expect(notifier.state.length, 1);
        expect(notifier.state.first.name, 'Bob');
        expect(notifier.state.first.colorValue, 0xFF00FF00);
      });

      test('generates a UUID for the new member', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'Carol', colorValue: 0xFF0000FF);
        await Future.delayed(Duration.zero);

        final id = notifier.state.first.id;
        expect(id, isNotEmpty);
        expect(id.length, 36);
      });

      test('persists to Firestore', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'Dave', colorValue: 0xFF123456);

        final snap = await fakeFirestore
            .collection('familyGroups')
            .doc(groupId)
            .collection('members')
            .get();
        expect(snap.docs.length, 1);
        expect(snap.docs.first.data()['name'], 'Dave');
      });
    });

    group('deleteMember', () {
      test('removes member from Firestore', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'Eve', colorValue: 0xFFABCDEF);
        await Future.delayed(Duration.zero);
        final id = notifier.state.first.id;

        await notifier.deleteMember(id);

        final snap = await fakeFirestore
            .collection('familyGroups')
            .doc(groupId)
            .collection('members')
            .get();
        expect(snap.docs, isEmpty);
      });

      test('no-ops on missing ID', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'Frank', colorValue: 0xFF000000);
        await Future.delayed(Duration.zero);

        await notifier.deleteMember('nonexistent-id');
        await Future.delayed(Duration.zero);

        expect(notifier.state.length, 1);
      });
    });
  });
}
