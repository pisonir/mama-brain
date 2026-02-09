import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme{
  // 1. Define your Palette
  static const Color pastelBlue = Color(0xFFA7C7E7);
  static const Color pastelPink = Color(0xFFFFB7B2);
  static const Color pastelYellow = Color(0xFFFFDAC1);
  static const Color pastelGreen = Color(0xFFB5EAD7);
  static const Color pastelPurple = Color(0xFFC7CEEA);
  static const Color background = Color(0xFFF9F9F9);
  static const Color darkText = Color(0xFF4A4A4A);

  // 2. The Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Global color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: pastelBlue,
        surface: Colors.white,
        primary: const Color(0xFF88D8B0),
        secondary: pastelPink
        ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: pastelBlue,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0
        ),
        iconTheme: IconThemeData(color: darkText),
      ),

      // Card Theme (Soft shadows)
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: pastelPink,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      textTheme: GoogleFonts.nunitoTextTheme(),
    );
  }
}