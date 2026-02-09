import 'package:hive/hive.dart';

part 'symptom.g.dart';

@HiveType(typeId: 3)
enum SymptomType {
  @HiveField(0)
  fever,
  @HiveField(1)
  cough,
  @HiveField(2)
  vomit,
  @HiveField(3)
  pain,
  @HiveField(4)
  rash,
  @HiveField(5)
  other,
}

@HiveType(typeId: 4) // Unique typeId for this model across the app
class Symptom {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String familyMemberId;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final SymptomType type;

  // Flexible data storage.
  // For Fever: {'temp': 38.5}
  // For Cough: {'style': 'wet'}
  @HiveField(4)
  final Map<String, dynamic> data;

  @HiveField(5)
  final String? note;

  Symptom({
    required this.id,
    required this.familyMemberId,
    required this.timestamp,
    required this.type,
    this.data = const {},
    this.note,
  });
}