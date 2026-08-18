import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/models/app_user.dart';

/// Streams the Firebase Auth state (signed-in user or null).
///
/// Firebase Auth persists the session on device, so this re-emits the same user
/// on every app start without another interactive sign-in.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Watches the /users/{uid} doc in real-time to get the app-level user (with groupId).
/// Using a StreamProvider (instead of FutureProvider) ensures:
///   - automatic updates when auth state or user doc changes
///   - Firestore offline cache is used on app restart (no network needed)
///   - no manual ref.invalidate needed after sign-in
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      // Self-heal: the user is authenticated but has no profile doc — it was
      // never created (an earlier sign-in failed partway) or has since been
      // removed. Recreate it in the background so they land on family setup
      // rather than being bounced back to the login screen forever.
      unawaited(ensureUserDocumentFor(user));
      return null;
    }
    return AppUser.fromMap(user.uid, doc.data()!);
  });
});

/// Creates or refreshes the /users/{uid} profile doc.
///
/// Uses a merging set (never `update`) so it works whether or not the doc
/// already exists, and never clobbers an existing `groupId` — which is what
/// keeps a returning user attached to their family.
Future<void> ensureUserDocument({
  required String uid,
  required String email,
  required String displayName,
  FirebaseFirestore? firestore,
}) async {
  final db = firestore ?? FirebaseFirestore.instance;
  await db.collection('users').doc(uid).set(
    {
      'email': email,
      'displayName': displayName,
    },
    SetOptions(merge: true),
  );
}

/// Convenience wrapper around [ensureUserDocument] for a Firebase [User].
Future<void> ensureUserDocumentFor(User user) {
  return ensureUserDocument(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? '',
  );
}

Future<void> signInWithGoogle() async {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) return; // user cancelled

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

  // Ensure a /users/{uid} doc exists. Merging means a returning user keeps the
  // groupId they already had, so signing in again never detaches them from
  // their family.
  await ensureUserDocumentFor(userCredential.user!);
}

Future<void> signOut() async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}
