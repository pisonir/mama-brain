import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String name;
  final int colorValue; // We store color as an integer (0xFF...)

  FamilyMember({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colorValue': colorValue,
    };
  }

  factory FamilyMember.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      name: data['name'] as String,
      colorValue: data['colorValue'] as int,
    );
  }
}
