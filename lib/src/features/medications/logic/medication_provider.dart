import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/medication.dart';
import '../../group/logic/group_provider.dart';

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, List<Medication>>((ref) {
  final groupId = ref.watch(groupIdProvider);
  if (groupId == null) return MedicationNotifier.empty();
  return MedicationNotifier(groupId: groupId);
});

class MedicationNotifier extends StateNotifier<List<Medication>> {
  final String? _groupId;
  late final FirebaseFirestore _firestore;

  MedicationNotifier({
    required String groupId,
    FirebaseFirestore? firestore,
  })  : _groupId = groupId,
        super([]) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _listen();
  }

  MedicationNotifier.empty()
      : _groupId = null,
        super([]);

  CollectionReference get _col => _firestore
      .collection('familyGroups')
      .doc(_groupId)
      .collection('medications');

  void _listen() {
    _col.snapshots().listen((snap) {
      state = snap.docs.map((d) => Medication.fromDoc(d)).toList();
    });
  }

  // Kept for tests — no-op in Firestore version
  void loadMedications() {}

  Future<void> addMedication({
    required String name,
    required String familyMemberId,
    required MedicationType type,
    required DateTime startDate,
    int? durationInDays,
    DateTime? takenAt,
  }) async {
    final id = const Uuid().v4();
    // Auto-check one-off medications immediately on creation
    final takenLogs = type == MedicationType.oneOff
        ? [takenAt ?? DateTime(startDate.year, startDate.month, startDate.day)]
        : <DateTime>[];
    final newMed = Medication(
      id: id,
      name: name,
      familyMemberId: familyMemberId,
      type: type,
      startDate: startDate,
      durationInDays: durationInDays,
      takenLogs: takenLogs,
    );
    await _col.doc(id).set(newMed.toMap());
  }

  Future<void> editMedication({
    required String id,
    required String name,
    required String familyMemberId,
    required MedicationType type,
    int? durationInDays,
    required DateTime originalStartDate,
  }) async {
    final updatedMed = Medication(
      id: id,
      name: name,
      familyMemberId: familyMemberId,
      type: type,
      startDate: originalStartDate,
      durationInDays: durationInDays,
    );
    await _col.doc(id).set(updatedMed.toMap());
  }

  Future<void> deleteMedication(String id) async {
    final med = state.firstWhere((m) => m.id == id);

    // One-off medications are always fully deleted
    if (med.type == MedicationType.oneOff) {
      await _col.doc(id).delete();
      return;
    }

    // For temporary/permanent: preserve past history, delete only future
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStart = DateTime(
      med.startDate.year,
      med.startDate.month,
      med.startDate.day,
    );

    // No past days to preserve — fully delete
    if (!normalizedStart.isBefore(normalizedToday)) {
      await _col.doc(id).delete();
      return;
    }

    // Keep only taken logs from before today. Any log for today is intentionally
    // excluded because the preserved document ends yesterday (the deletion point),
    // so including a today-log would reference a day outside the medication's new range.
    final pastLogs = med.takenLogs.where((log) {
      final normalizedLog = DateTime(log.year, log.month, log.day);
      return normalizedLog.isBefore(normalizedToday);
    }).toList();

    // Truncate the medication to cover only past days (startDate to yesterday).
    // For temporary medications cap to the original duration so we never extend
    // a medication that had already ended before the deletion date.
    final diff = normalizedToday.difference(normalizedStart).inDays;
    final daysToPreserve =
        (med.type == MedicationType.temporary && med.durationInDays != null)
            ? (diff < med.durationInDays! ? diff : med.durationInDays!)
            : diff;
    final preserved = med.copyWith(
      type: MedicationType.temporary,
      durationInDays: daysToPreserve,
      takenLogs: pastLogs,
    );
    await _col.doc(id).set(preserved.toMap());
  }

  Future<void> toggleTaken(String id, DateTime date, {DateTime? takenAt}) async {
    final med = state.firstWhere((med) => med.id == id);
    final targetDay = DateTime(date.year, date.month, date.day);

    final existingLogIndex = med.takenLogs.indexWhere((log) =>
        log.year == targetDay.year &&
        log.month == targetDay.month &&
        log.day == targetDay.day);

    List<DateTime> newLogs = [...med.takenLogs];

    if (existingLogIndex >= 0) {
      newLogs.removeAt(existingLogIndex);
    } else {
      newLogs.add(takenAt ?? DateTime.now());
    }

    final updatedMed = med.copyWith(takenLogs: newLogs);
    await _col.doc(id).set(updatedMed.toMap());
  }

  Future<void> setTakenTime(String id, DateTime date, DateTime newTakenAt) async {
    assert(
      newTakenAt.year == date.year &&
          newTakenAt.month == date.month &&
          newTakenAt.day == date.day,
      'newTakenAt must be on the same calendar day as date',
    );
    final med = state.firstWhere((med) => med.id == id);

    final existingLogIndex = med.takenLogs.indexWhere((log) =>
        log.year == date.year &&
        log.month == date.month &&
        log.day == date.day);

    if (existingLogIndex < 0) return;

    List<DateTime> newLogs = [...med.takenLogs];
    newLogs[existingLogIndex] = newTakenAt;

    final updatedMed = med.copyWith(takenLogs: newLogs);
    await _col.doc(id).set(updatedMed.toMap());
  }
}
