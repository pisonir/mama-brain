import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/symptom.dart';
import '../../medications/logic/date_provider.dart';

final dailySymptomProvider = Provider<List<Symptom>>((ref) {
  final allSymptoms = ref.watch(symptomProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return allSymptoms.where((symptom) {
    return symptom.timestamp.year == selectedDate.year &&
        symptom.timestamp.month == selectedDate.month &&
        symptom.timestamp.day == selectedDate.day;
  }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by time (AM -> PM)
});

final symptomProvider = StateNotifierProvider<SymptomNotifier, List<Symptom>>((ref) {
  return SymptomNotifier();
});

class SymptomNotifier extends StateNotifier<List<Symptom>> {
  SymptomNotifier() : super([]) {
    loadSymptoms();
  }

  Box<Symptom> get _box => Hive.box<Symptom>('symptoms');

  void loadSymptoms() {
    state = _box.values.toList();
  }

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

    await _box.put(newSymptom.id, newSymptom);
    state = [...state, newSymptom];
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

    await _box.put(id, updatedSymptom);
    state = [
      for (final s in state)
        if (s.id == id) updatedSymptom else s,
    ];
  }

  Future<void> deleteSymptom(String id) async {
    await _box.delete(id);
    state = state.where((symptom) => symptom.id != id).toList();
  }
}