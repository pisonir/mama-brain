import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

import 'src/app.dart';
// Import the data models so we can register the adapters
import 'src/core/models/family_member.dart';
import 'src/core/models/medication.dart';
import 'src/core/models/symptom.dart';

// We make the main function async so we can wait for the database to start
void main() async {
  // 1. Ensure Flutter bindings are initialized (required before async code)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive
  await Hive.initFlutter();

  // 3. Registed the Adapters (the generated code)
  // This teaches Hive how to read/write our custom classes.
  Hive.registerAdapter(FamilyMemberAdapter());
  Hive.registerAdapter(MedicationTypeAdapter()); // Register Enum Adapter
  Hive.registerAdapter(MedicationAdapter());
  Hive.registerAdapter(SymptomTypeAdapter()); // Register Enum Adapter
  Hive.registerAdapter(SymptomAdapter());

  // 4. Open the "Boxes" (Like tables in SQL)
  // We open them now so they are available instantly throughout the app
  await Hive.openBox<FamilyMember>('family_members');
  await Hive.openBox<Medication>('medications');
  await Hive.openBox<Symptom>('symptoms');

  // 5. Run the app. ProviderScope is required by Riverpod to store state
  runApp(const ProviderScope(child: MamaBrainApp()));
}