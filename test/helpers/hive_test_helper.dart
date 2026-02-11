import 'dart:io';

import 'package:hive/hive.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/core/models/symptom.dart';

/// Creates a temp directory, initializes Hive, and registers all adapters.
/// Returns the temp directory so it can be cleaned up in tearDown.
Future<Directory> setUpHive() async {
  final tempDir = Directory.systemTemp.createTempSync('hive_test_');
  Hive.init(tempDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FamilyMemberAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MedicationTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MedicationAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SymptomTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(SymptomAdapter());
  }

  return tempDir;
}

/// Closes all Hive boxes and deletes the temp directory.
Future<void> tearDownHive(Directory tempDir) async {
  await Hive.close();
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}

Future<Box<FamilyMember>> openFamilyBox() =>
    Hive.openBox<FamilyMember>('family_members');

Future<Box<Medication>> openMedicationBox() =>
    Hive.openBox<Medication>('medications');

Future<Box<Symptom>> openSymptomBox() => Hive.openBox<Symptom>('symptoms');
