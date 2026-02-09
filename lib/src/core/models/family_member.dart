import 'package:hive/hive.dart';

// This file tells the generator to write code for this class
part 'family_member.g.dart';

@HiveType(typeId: 0) // Unique typeId for this model across the app
class FamilyMember {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue; // We store color as an integer (0xFF...)

  FamilyMember({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}