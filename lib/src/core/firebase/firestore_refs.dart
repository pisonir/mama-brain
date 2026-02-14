import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/group/logic/group_provider.dart';

/// Provides typed collection references scoped to the current family group.
class FirestoreRefs {
  final String groupId;
  final FirebaseFirestore _firestore;

  FirestoreRefs(this.groupId, [FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get members =>
      _firestore.collection('familyGroups').doc(groupId).collection('members');

  CollectionReference get medications =>
      _firestore.collection('familyGroups').doc(groupId).collection('medications');

  CollectionReference get symptoms =>
      _firestore.collection('familyGroups').doc(groupId).collection('symptoms');
}

final firestoreRefsProvider = Provider<FirestoreRefs?>((ref) {
  final groupId = ref.watch(groupIdProvider);
  if (groupId == null) return null;
  return FirestoreRefs(groupId);
});
