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
      state = snap.docs.map((d) => FamilyMember.fromDoc(d)).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    });
  }

  // Kept for tests that call loadMembers — no-op in Firestore version
  void loadMembers() {}

  Future<void> addMember({required String name, required int colorValue}) async {
    final id = const Uuid().v4();
    // Append to the end of the current order.
    final nextOrder = state.isEmpty
        ? 0
        : state.map((m) => m.order).reduce((a, b) => a > b ? a : b) + 1;
    final member = FamilyMember(
      id: id,
      name: name,
      colorValue: colorValue,
      order: nextOrder,
    );
    await _col.doc(id).set(member.toMap());
  }

  /// Update an existing member's name and/or avatar color, preserving their
  /// position in the list.
  Future<void> editMember({
    required String id,
    required String name,
    required int colorValue,
  }) async {
    await _col.doc(id).update({'name': name, 'colorValue': colorValue});
  }

  /// Persist a drag-and-drop reorder by rewriting every member's `order` to
  /// match the new list position. Updates local state optimistically so the
  /// avatar row settles immediately, before the Firestore snapshot echoes back.
  Future<void> reorderMembers(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final reordered = [...state];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex.clamp(0, reordered.length), moved);

    state = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i),
    ];

    final batch = _firestore.batch();
    for (var i = 0; i < reordered.length; i++) {
      batch.update(_col.doc(reordered[i].id), {'order': i});
    }
    await batch.commit();
  }

  /// Delete a member and cascade-delete everything referencing them, so no
  /// orphaned medications or symptoms linger pointing at a member that no
  /// longer exists.
  Future<void> deleteMember(String id) async {
    final groupRef = _firestore.collection('familyGroups').doc(_groupId);
    final batch = _firestore.batch();

    batch.delete(_col.doc(id));

    final meds = await groupRef
        .collection('medications')
        .where('familyMemberId', isEqualTo: id)
        .get();
    for (final doc in meds.docs) {
      batch.delete(doc.reference);
    }

    final symptoms = await groupRef
        .collection('symptoms')
        .where('familyMemberId', isEqualTo: id)
        .get();
    for (final doc in symptoms.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
