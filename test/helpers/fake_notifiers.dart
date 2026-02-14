import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

/// A fake FamilyNotifier that accepts initial state and never touches Firestore.
class FakeFamilyNotifier extends FamilyNotifier {
  final List<FamilyMember> _initialState;
  FakeFamilyNotifier(this._initialState) : super.empty() {
    state = _initialState;
  }

  void setState(List<FamilyMember> newState) {
    state = newState;
  }
}

/// A fake MedicationNotifier that accepts initial state and never touches Firestore.
class FakeMedicationNotifier extends MedicationNotifier {
  final List<Medication> _initialState;
  FakeMedicationNotifier(this._initialState) : super.empty() {
    state = _initialState;
  }

  void setState(List<Medication> newState) {
    state = newState;
  }
}

/// A fake SymptomNotifier that accepts initial state and never touches Firestore.
class FakeSymptomNotifier extends SymptomNotifier {
  final List<Symptom> _initialState;
  FakeSymptomNotifier(this._initialState) : super.empty() {
    state = _initialState;
  }

  void setState(List<Symptom> newState) {
    state = newState;
  }
}
