import 'package:cloud_firestore/cloud_firestore.dart';

enum SymptomType {
  fever,
  cough,
  vomit,
  diarrhea,
  pain,
  rash,
  other,
}

/// A single source of truth for how each symptom type is written in the UI,
/// so the label reads the same (Title Case) everywhere — chips, the daily
/// list, and the history calendar — instead of a mix of UPPERCASE and
/// lowercase spellings.
extension SymptomTypeLabel on SymptomType {
  String get label {
    switch (this) {
      case SymptomType.fever:
        return 'Fever';
      case SymptomType.cough:
        return 'Cough';
      case SymptomType.vomit:
        return 'Vomit';
      case SymptomType.diarrhea:
        return 'Diarrhea';
      case SymptomType.pain:
        return 'Pain';
      case SymptomType.rash:
        return 'Rash';
      case SymptomType.other:
        return 'Other';
    }
  }
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
