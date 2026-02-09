import 'package:hive/hive.dart';

part 'medication.g.dart';

// Enums also need adapters to be stored
@HiveType(typeId: 1)
enum MedicationType {
  @HiveField(0)
  oneOff,

  @HiveField(1)
  temporary,

  @HiveField(2)
  permanent,
}

@HiveType(typeId: 2) // Unique typeId for this model across the app
class Medication {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String familyMemberId;

  @HiveField(3)
  final MedicationType type;

  @HiveField(4)
  final DateTime startDate;

  // Only for temporary medications
  @HiveField(5)
  final int? durationInDays;

  // A history of when this specific medication was taken. We store DateTimes here
  @HiveField(6)
  final List<DateTime> takenLogs;

  Medication({
    required this.id,
    required this.name,
    required this.familyMemberId,
    required this.type,
    required this.startDate,
    this.durationInDays,
    this.takenLogs = const [],
  });

  // A helper method to create a copy of the objext with modified fields
  // (Since our class is immutable/final, we can't just set variables)
  Medication copyWith({
    String? id,
    String? name,
    String? familyMemberId,
    MedicationType? type,
    DateTime? startDate,
    int? durationInDays,
    List<DateTime>? takenLogs,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      durationInDays: durationInDays ?? this.durationInDays,
      takenLogs: takenLogs ?? this.takenLogs,
    );
  }
}