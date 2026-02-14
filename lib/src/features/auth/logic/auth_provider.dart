import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/models/app_user.dart';

/// Streams the Firebase Auth state (signed-in user or null).
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Reads the /users/{uid} doc to get the app-level user (with groupId).
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (!doc.exists) return null;

  return AppUser.fromMap(user.uid, doc.data()!);
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
