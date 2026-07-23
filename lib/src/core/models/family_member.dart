import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String name;
  final int colorValue; // We store color as an integer (0xFF...)

  // Position in the family list. Members are sorted by this ascending, so the
  // user can drag them into whatever order they like. Defaults to 0 for legacy
  // members saved before ordering existed.
  final int order;

  FamilyMember({
    required this.id,
    required this.name,
    required this.colorValue,
    this.order = 0,
  });

  FamilyMember copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? order,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colorValue': colorValue,
      'order': order,
    };
  }

  factory FamilyMember.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      name: data['name'] as String,
      colorValue: data['colorValue'] as int,
      // Tolerate legacy docs that predate the ordering field.
      order: (data['order'] as int?) ?? 0,
    );
  }
}
