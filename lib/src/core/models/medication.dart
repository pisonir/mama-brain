import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicationType {
  oneOff,
  temporary,
  permanent,
}

class Medication {
  final String id;
  final String name;
  final String familyMemberId;
  final MedicationType type;
  final DateTime startDate;

  // Only for temporary medications
  final int? durationInDays;

  // A history of when this specific medication was taken. We store DateTimes here
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

  // A helper method to create a copy of the object with modified fields
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'familyMemberId': familyMemberId,
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'durationInDays': durationInDays,
      'takenLogs': takenLogs.map((dt) => Timestamp.fromDate(dt)).toList(),
    };
  }

  factory Medication.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Medication(
      id: doc.id,
      name: data['name'] as String,
      familyMemberId: data['familyMemberId'] as String,
      type: MedicationType.values.byName(data['type'] as String),
      startDate: (data['startDate'] as Timestamp).toDate(),
      durationInDays: data['durationInDays'] as int?,
      takenLogs: (data['takenLogs'] as List<dynamic>?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ??
          [],
    );
  }
}
