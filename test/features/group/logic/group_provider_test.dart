import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/features/auth/logic/auth_provider.dart';
import 'package:mama_brain/src/features/group/logic/group_provider.dart';

void main() {
  late FakeFirebaseFirestore db;
  const uid = 'user-1';

  setUp(() {
    db = FakeFirebaseFirestore();
  });

  Future<Map<String, dynamic>?> readUser() async {
    final doc = await db.collection('users').doc(uid).get();
    return doc.data();
  }

  group('createFamilyGroup', () {
    test('returns the invite code and wires up group, code and user docs',
        () async {
      final code = await createFamilyGroup(uid, db: db);

      expect(code, isNotEmpty);
      expect(code.length, 6);

      final groups = await db.collection('familyGroups').get();
      expect(groups.docs.length, 1);
      final groupId = groups.docs.first.id;
      expect(groups.docs.first.data()['inviteCode'], code);
      expect(groups.docs.first.data()['createdBy'], uid);

      final codeDoc = await db.collection('inviteCodes').doc(code).get();
      expect(codeDoc.data()!['groupId'], groupId);

      expect((await readUser())!['groupId'], groupId);
    });

    test('works when the user profile doc does not exist yet', () async {
      // Regression: this used to call update(), which throws on a missing doc
      // and left a user who lost their profile unable to start a family.
      expect((await readUser()), isNull);

      final code = await createFamilyGroup(uid, db: db);

      expect(code, isNotEmpty);
      expect((await readUser())!['groupId'], isNotNull);
    });

    test('preserves existing profile fields', () async {
      await db
          .collection('users')
          .doc(uid)
          .set({'email': 'a@b.com', 'displayName': 'Ricardo'});

      await createFamilyGroup(uid, db: db);

      final data = (await readUser())!;
      expect(data['email'], 'a@b.com');
      expect(data['displayName'], 'Ricardo');
      expect(data['groupId'], isNotNull);
    });
  });

  group('joinFamilyGroup', () {
    test('attaches the user to the group behind a valid code', () async {
      await db.collection('inviteCodes').doc('ABC123').set({'groupId': 'g-1'});

      final ok = await joinFamilyGroup(uid, 'ABC123', db: db);

      expect(ok, isTrue);
      expect((await readUser())!['groupId'], 'g-1');
    });

    test('returns false and changes nothing for an unknown code', () async {
      final ok = await joinFamilyGroup(uid, 'NOPE00', db: db);

      expect(ok, isFalse);
      expect(await readUser(), isNull);
    });

    test('rejoining works when the profile doc is missing (access recovery)',
        () async {
      // The recovery path: a user whose /users/{uid} doc vanished re-joins the
      // family with the invite code. This used to throw because of update().
      await db.collection('inviteCodes').doc('FAM777').set({'groupId': 'g-9'});
      expect(await readUser(), isNull);

      final ok = await joinFamilyGroup(uid, 'FAM777', db: db);

      expect(ok, isTrue);
      expect((await readUser())!['groupId'], 'g-9');
    });

    test('switching families keeps other profile fields intact', () async {
      await db.collection('users').doc(uid).set({
        'email': 'a@b.com',
        'displayName': 'Ricardo',
        'groupId': 'old-group',
      });
      await db.collection('inviteCodes').doc('NEW111').set({'groupId': 'g-new'});

      await joinFamilyGroup(uid, 'NEW111', db: db);

      final data = (await readUser())!;
      expect(data['groupId'], 'g-new');
      expect(data['email'], 'a@b.com');
      expect(data['displayName'], 'Ricardo');
    });
  });

  group('ensureUserDocument', () {
    test('creates the profile doc when missing', () async {
      await ensureUserDocument(
        uid: uid,
        email: 'a@b.com',
        displayName: 'Ricardo',
        firestore: db,
      );

      final data = (await readUser())!;
      expect(data['email'], 'a@b.com');
      expect(data['displayName'], 'Ricardo');
    });

    test('never clobbers an existing groupId', () async {
      // This is what keeps a returning user attached to their family when they
      // sign in again.
      await db.collection('users').doc(uid).set({
        'email': 'old@b.com',
        'displayName': 'Old',
        'groupId': 'g-existing',
      });

      await ensureUserDocument(
        uid: uid,
        email: 'new@b.com',
        displayName: 'New',
        firestore: db,
      );

      final data = (await readUser())!;
      expect(data['groupId'], 'g-existing');
      expect(data['email'], 'new@b.com');
      expect(data['displayName'], 'New');
    });
  });
}
