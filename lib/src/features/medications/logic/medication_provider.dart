import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/medication.dart';

final medicationProvider = StateNotifierProvider<MedicationNotifier, List<Medication>>((ref) {
  return MedicationNotifier();
});

class MedicationNotifier extends StateNotifier<List<Medication>> {
  MedicationNotifier() : super([]) {
    loadMedications();
  }

  Box<Medication> get _box => Hive.box<Medication>('medications');

  void loadMedications() {
    state = _box.values.toList();
  }

  Future<void> deleteMedication(String id) async {
    await _box.delete(id);
    state = state.where((med) => med.id != id).toList();
  }

  Future<void> addMedication({
    required String name,
    required String familyMemberId,
    required MedicationType type,
    required DateTime startDate,
    int? durationInDays, // Nullable, because 'Permanent' and 'OneOff' types don't need it
  }) async {
    final id = const Uuid().v4();

    final newMed = Medication(
      id: id,
      name: name,
      familyMemberId: familyMemberId,
      type: type,
      startDate: startDate,
      durationInDays: durationInDays,
    );
    await _box.put(id, newMed);
    state = [...state, newMed];
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
    await _box.put(id, updatedMed);
    state = [
      for (final med in state)
        if (med.id == id) updatedMed else med,
    ];
  }

  Future<void> toggleTaken(String id, DateTime date) async {
    final med = state.firstWhere((med) => med.id == id);
    final targetDay = DateTime(date.year, date.month, date.day);

    final existingLogIndex = med.takenLogs.indexWhere((log) =>
        log.year == targetDay.year &&
        log.month == targetDay.month &&
        log.day == targetDay.day);

    List<DateTime> newLogs = [...med.takenLogs];

    if (existingLogIndex >= 0) {
      // Log exists, untoggle it
      newLogs.removeAt(existingLogIndex);
    } else {
      newLogs.add(DateTime.now());
    }

    final updatedMed = med.copyWith(takenLogs: newLogs);
    await _box.put(id, updatedMed);

    state = [
      for (final m in state)
        if (m.id == id) updatedMed else m,
    ];
  }
}