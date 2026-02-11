import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

/// A fake FamilyNotifier that accepts initial state and never touches Hive.
/// Dart evaluates field initializers before the super constructor, so
/// [_initialState] is available when [loadMembers] is called from the
/// FamilyNotifier constructor.
class FakeFamilyNotifier extends FamilyNotifier {
  final List<FamilyMember> _initialState;
  FakeFamilyNotifier(this._initialState);

  @override
  void loadMembers() {
    state = _initialState;
  }
}

/// A fake MedicationNotifier that accepts initial state and never touches Hive.
class FakeMedicationNotifier extends MedicationNotifier {
  final List<Medication> _initialState;
  FakeMedicationNotifier(this._initialState);

  @override
  void loadMedications() {
    state = _initialState;
  }
}

/// A fake SymptomNotifier that accepts initial state and never touches Hive.
class FakeSymptomNotifier extends SymptomNotifier {
  final List<Symptom> _initialState;
  FakeSymptomNotifier(this._initialState);

  @override
  void loadSymptoms() {
    state = _initialState;
  }
}
