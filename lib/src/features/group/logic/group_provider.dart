import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/auth_provider.dart';

/// Extracts the groupId from the current appUser. Null if not in a group yet.
final groupIdProvider = Provider<String?>((ref) {
  final appUser = ref.watch(appUserProvider).valueOrNull;
  return appUser?.groupId;
});

/// Creates a new family group and assigns the user to it.
/// Returns the invite code so it can be shown to the user straight away.
Future<String> createFamilyGroup(String uid, {FirebaseFirestore? db}) async {
  final firestore = db ?? FirebaseFirestore.instance;
  final code = _generateInviteCode();

  // 1. Create the group doc
  final groupRef = firestore.collection('familyGroups').doc();
  await groupRef.set({
    'createdBy': uid,
    'inviteCode': code,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 2. Create the invite code lookup doc
  await firestore.collection('inviteCodes').doc(code).set({
    'groupId': groupRef.id,
  });

  // 3. Attach the group to the user doc. A merging set (not `update`) so this
  // still works when the profile doc is missing — otherwise a user whose doc
  // was lost could never re-attach to a family.
  await firestore.collection('users').doc(uid).set(
    {'groupId': groupRef.id},
    SetOptions(merge: true),
  );

  return code;
}

/// Joins an existing family group using an invite code.
/// Returns true on success, false if the code is invalid.
Future<bool> joinFamilyGroup(
  String uid,
  String code, {
  FirebaseFirestore? db,
}) async {
  final firestore = db ?? FirebaseFirestore.instance;

  final codeDoc = await firestore.collection('inviteCodes').doc(code).get();
  if (!codeDoc.exists) return false;

  final groupId = codeDoc.data()!['groupId'] as String;

  // Merging set (not `update`) so rejoining works even if the profile doc went
  // missing — this is the recovery path for a user who lost access.
  await firestore.collection('users').doc(uid).set(
    {'groupId': groupId},
    SetOptions(merge: true),
  );

  return true;
}

String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
  final rng = Random.secure();
  return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
}
