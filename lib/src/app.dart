import 'package:flutter/material.dart';
import 'package:mama_brain/src/main_screen.dart';
import 'core/theme/app_theme.dart';

class MamaBrainApp extends StatelessWidget {
  const MamaBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mama Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}