import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/family_member.dart';
import '../../group/logic/group_provider.dart';

final familyProvider =
    StateNotifierProvider<FamilyNotifier, List<FamilyMember>>((ref) {
  final groupId = ref.watch(groupIdProvider);
  if (groupId == null) return FamilyNotifier.empty();
  return FamilyNotifier(groupId: groupId);
});

class FamilyNotifier extends StateNotifier<List<FamilyMember>> {
  final String? _groupId;
  late final FirebaseFirestore _firestore;

  FamilyNotifier({
    required String groupId,
    FirebaseFirestore? firestore,
  })  : _groupId = groupId,
        super([]) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _listen();
  }

  FamilyNotifier.empty()
      : _groupId = null,
        super([]);

  CollectionReference get _col => _firestore
      .collection('familyGroups')
      .doc(_groupId)
      .collection('members');

  void _listen() {
    _col.snapshots().listen((snap) {
      state = snap.docs.map((d) => FamilyMember.fromDoc(d)).toList();
    });
  }

  // Kept for tests that call loadMembers — no-op in Firestore version
  void loadMembers() {}

  Future<void> addMember({required String name, required int colorValue}) async {
    final id = const Uuid().v4();
    final member = FamilyMember(id: id, name: name, colorValue: colorValue);
    await _col.doc(id).set(member.toMap());
  }

  Future<void> deleteMember(String id) async {
    await _col.doc(id).delete();
  }
}
