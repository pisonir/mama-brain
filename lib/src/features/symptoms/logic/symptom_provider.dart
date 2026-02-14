import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/symptom.dart';
import '../../group/logic/group_provider.dart';
import '../../medications/logic/date_provider.dart';

final dailySymptomProvider = Provider<List<Symptom>>((ref) {
  final allSymptoms = ref.watch(symptomProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return allSymptoms.where((symptom) {
    return symptom.timestamp.year == selectedDate.year &&
        symptom.timestamp.month == selectedDate.month &&
        symptom.timestamp.day == selectedDate.day;
  }).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

final symptomProvider =
    StateNotifierProvider<SymptomNotifier, List<Symptom>>((ref) {
  final groupId = ref.watch(groupIdProvider);
  if (groupId == null) return SymptomNotifier.empty();
  return SymptomNotifier(groupId: groupId);
});

class SymptomNotifier extends StateNotifier<List<Symptom>> {
  final String? _groupId;
  late final FirebaseFirestore _firestore;

  SymptomNotifier({
    required String groupId,
    FirebaseFirestore? firestore,
  })  : _groupId = groupId,
        super([]) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _listen();
  }

  SymptomNotifier.empty()
      : _groupId = null,
        super([]);

  CollectionReference get _col => _firestore
      .collection('familyGroups')
      .doc(_groupId)
      .collection('symptoms');

  void _listen() {
    _col.snapshots().listen((snap) {
      state = snap.docs.map((d) => Symptom.fromDoc(d)).toList();
    });
  }

  // Kept for tests — no-op in Firestore version
  void loadSymptoms() {}

  Future<void> addSymptom({
    required String familyMemberId,
    required SymptomType type,
    required DateTime timestamp,
    Map<String, dynamic> data = const {},
    String? note,
  }) async {
    final newSymptom = Symptom(
      id: const Uuid().v4(),
      familyMemberId: familyMemberId,
      timestamp: timestamp,
      type: type,
      data: data,
      note: note,
    );
    await _col.doc(newSymptom.id).set(newSymptom.toMap());
  }

  Future<void> editSymptom({
    required String id,
    required String familyMemberId,
    required SymptomType type,
    required DateTime timestamp,
    Map<String, dynamic> data = const {},
    String? note,
  }) async {
    final updatedSymptom = Symptom(
      id: id,
      familyMemberId: familyMemberId,
      timestamp: timestamp,
      type: type,
      data: data,
      note: note,
    );
    await _col.doc(id).set(updatedSymptom.toMap());
  }

  Future<void> deleteSymptom(String id) async {
    await _col.doc(id).delete();
  }
}
