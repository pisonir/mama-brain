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
Future<void> createFamilyGroup(String uid) async {
  final firestore = FirebaseFirestore.instance;
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

  // 3. Update the user doc with the groupId
  await firestore.collection('users').doc(uid).update({
    'groupId': groupRef.id,
  });
}

/// Joins an existing family group using an invite code.
/// Returns true on success, false if the code is invalid.
Future<bool> joinFamilyGroup(String uid, String code) async {
  final firestore = FirebaseFirestore.instance;

  final codeDoc = await firestore.collection('inviteCodes').doc(code).get();
  if (!codeDoc.exists) return false;

  final groupId = codeDoc.data()!['groupId'] as String;

  await firestore.collection('users').doc(uid).update({
    'groupId': groupId,
  });

  return true;
}

String _generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
  final rng = Random.secure();
  return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
}
