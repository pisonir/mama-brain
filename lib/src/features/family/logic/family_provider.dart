import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/family_member.dart';

// 1. The Provider Definition
// This is the variable the UI will listen to. 
// In Riverpod, we use a StateNotifier to manage a list of data. This class acts as the "Brain" for the family feature.
// It will:
// 1) Read from Hive when the app starts.
// 2) Add a new person to Hive when the UI asks.
// 3) Automatically tell the UI to refresh when the list changes.
final familyProvider = StateNotifierProvider<FamilyNotifier, List<FamilyMember>>((ref) {
  return FamilyNotifier();
});

// 2. The Notifier Class
class FamilyNotifier extends StateNotifier<List<FamilyMember>> {
  FamilyNotifier() : super([]) {
    // On initialization, load existing members
    loadMembers();
  }

  // Helper to access the database box
  Box<FamilyMember> get _box => Hive.box<FamilyMember>('family_members');

  void loadMembers() {
    // .values gives us an Iterable, we convert to List
    state = _box.values.toList();
  }

  // Method to ass a new person
  Future<void> addMember({required String name, required int colorValue}) async {
    final id = const Uuid().v4(); // Generate unique ID

    final newMember = FamilyMember(
      id: id, 
      name: name, 
      colorValue: colorValue
      );

    // Save to Hive (Persist)
    await _box.put(id, newMember);

    // Update the State (Update UI)
    // We create a new list by adding the new member to the current list.
    // Riverpod relies on "Immutable State". We don't add to state.
    // Instead, we replace the entire list with a new list containing the old items
    // + the new item.
    state = [...state, newMember];
  }

  Future<void> deleteMember(String id) async {
    await _box.delete(id);
    // Reload state from the box to be safe, or filter the current list
    state = state.where((m) => m.id != id).toList();
  }
}