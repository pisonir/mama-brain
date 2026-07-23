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

      test('cascade-deletes the member\'s medications and symptoms', () async {
        final groupRef = fakeFirestore.collection('familyGroups').doc(groupId);
        final notifier = createNotifier();
        await notifier.addMember(name: 'Target', colorValue: 0xFFABCDEF);
        await Future.delayed(Duration.zero);
        final memberId = notifier.state.first.id;

        // Seed data owned by this member and by someone else.
        await groupRef
            .collection('medications')
            .doc('med-own')
            .set({'familyMemberId': memberId});
        await groupRef
            .collection('medications')
            .doc('med-other')
            .set({'familyMemberId': 'someone-else'});
        await groupRef
            .collection('symptoms')
            .doc('sym-own')
            .set({'familyMemberId': memberId});
        await groupRef
            .collection('symptoms')
            .doc('sym-other')
            .set({'familyMemberId': 'someone-else'});

        await notifier.deleteMember(memberId);

        final meds = await groupRef.collection('medications').get();
        final symptoms = await groupRef.collection('symptoms').get();
        expect(meds.docs.map((d) => d.id), ['med-other']);
        expect(symptoms.docs.map((d) => d.id), ['sym-other']);
      });
    });

    group('ordering', () {
      test('addMember assigns increasing order values', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'A', colorValue: 0xFF111111);
        await Future.delayed(Duration.zero);
        await notifier.addMember(name: 'B', colorValue: 0xFF222222);
        await Future.delayed(Duration.zero);
        await notifier.addMember(name: 'C', colorValue: 0xFF333333);
        await Future.delayed(Duration.zero);

        final orders = {for (final m in notifier.state) m.name: m.order};
        expect(orders['A'], 0);
        expect(orders['B'], 1);
        expect(orders['C'], 2);
      });

      test('state is sorted by order ascending', () async {
        final col = fakeFirestore
            .collection('familyGroups')
            .doc(groupId)
            .collection('members');
        await col
            .doc('m1')
            .set({'name': 'Third', 'colorValue': 0xFF000000, 'order': 2});
        await col
            .doc('m2')
            .set({'name': 'First', 'colorValue': 0xFF000000, 'order': 0});
        await col
            .doc('m3')
            .set({'name': 'Second', 'colorValue': 0xFF000000, 'order': 1});

        final notifier = createNotifier();
        await Future.delayed(Duration.zero);

        expect(notifier.state.map((m) => m.name).toList(),
            ['First', 'Second', 'Third']);
      });

      test('reorderMembers moves a member and rewrites order', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'A', colorValue: 0xFF111111);
        await Future.delayed(Duration.zero);
        await notifier.addMember(name: 'B', colorValue: 0xFF222222);
        await Future.delayed(Duration.zero);
        await notifier.addMember(name: 'C', colorValue: 0xFF333333);
        await Future.delayed(Duration.zero);

        // Move C (index 2) to the front (index 0).
        await notifier.reorderMembers(2, 0);
        await Future.delayed(Duration.zero);

        expect(notifier.state.map((m) => m.name).toList(), ['C', 'A', 'B']);
        expect(notifier.state.map((m) => m.order).toList(), [0, 1, 2]);
      });
    });

    group('editMember', () {
      test('updates name and color while preserving order', () async {
        final notifier = createNotifier();
        await notifier.addMember(name: 'First', colorValue: 0xFF111111);
        await Future.delayed(Duration.zero);
        await notifier.addMember(name: 'Keep', colorValue: 0xFF222222);
        await Future.delayed(Duration.zero);
        final target = notifier.state.firstWhere((m) => m.name == 'Keep');
        final originalOrder = target.order;

        await notifier.editMember(
            id: target.id, name: 'Renamed', colorValue: 0xFF999999);
        await Future.delayed(Duration.zero);

        final updated = notifier.state.firstWhere((m) => m.id == target.id);
        expect(updated.name, 'Renamed');
        expect(updated.colorValue, 0xFF999999);
        expect(updated.order, originalOrder);
      });
    });
  });
}
