import 'package:flutter/material.dart';

/// The palette offered when creating or editing a family member's avatar.
///
/// A single shared list so the "add member" and "edit member" flows always
/// present exactly the same choices. Grouped loosely by hue, with a light and
/// a deeper shade of each so members are easy to tell apart at a glance.
const List<Color> kFamilyColorOptions = [
  // Reds & pinks
  Color(0xFFE05C5C), // Coral
  Color(0xFFC62828), // Deep red
  Color(0xFFF06292), // Pink
  Color(0xFFAD1457), // Magenta
  // Oranges & ambers
  Color(0xFFE0923A), // Amber
  Color(0xFFEF6C00), // Deep orange
  Color(0xFFFFB74D), // Light amber
  // Yellows & limes
  Color(0xFFFBC02D), // Golden
  Color(0xFF9E9D24), // Olive
  Color(0xFFAED581), // Lime
  // Greens
  Color(0xFF4CAF87), // Emerald
  Color(0xFF2E7D32), // Forest
  Color(0xFF66BB6A), // Green
  // Teals & cyans
  Color(0xFF2AADBA), // Teal
  Color(0xFF00838F), // Deep teal
  Color(0xFF4DD0E1), // Cyan
  // Blues
  Color(0xFF5B8DEF), // Blue
  Color(0xFF1565C0), // Deep blue
  Color(0xFF64B5F6), // Sky
  // Purples & indigos
  Color(0xFF9067C6), // Purple
  Color(0xFF6A1B9A), // Deep purple
  Color(0xFF7986CB), // Indigo
  // Neutrals
  Color(0xFF8D6E63), // Brown
  Color(0xFF78909C), // Slate
];
