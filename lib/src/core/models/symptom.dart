import 'package:cloud_firestore/cloud_firestore.dart';

enum SymptomType {
  fever,
  cough,
  vomit,
  pain,
  rash,
  other,
}

class Symptom {
  final String id;
  final String familyMemberId;
  final DateTime timestamp;
  final SymptomType type;

  // Flexible data storage.
  // For Fever: {'temp': 38.5}
  // For Cough: {'style': 'wet'}
  final Map<String, dynamic> data;

  final String? note;

  Symptom({
    required this.id,
    required this.familyMemberId,
    required this.timestamp,
    required this.type,
    this.data = const {},
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyMemberId': familyMemberId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
      'data': data,
      'note': note,
    };
  }

  factory Symptom.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Symptom(
      id: doc.id,
      familyMemberId: d['familyMemberId'] as String,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      type: SymptomType.values.byName(d['type'] as String),
      data: (d['data'] as Map<String, dynamic>?) ?? {},
      note: d['note'] as String?,
    );
  }
}
