import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/models/app_user.dart';

/// Streams the Firebase Auth state (signed-in user or null).
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
    if (!doc.exists) return null;
    return AppUser.fromMap(user.uid, doc.data()!);
  });
});

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

  // Ensure a /users/{uid} doc exists
  final uid = userCredential.user!.uid;
  final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
  final snapshot = await userDoc.get();

  if (!snapshot.exists) {
    await userDoc.set({
      'email': userCredential.user!.email ?? '',
      'displayName': userCredential.user!.displayName ?? '',
      'groupId': null,
    });
  }
}

Future<void> signOut() async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}
