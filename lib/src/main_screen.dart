import 'package:flutter/material.dart';
import 'package:mama_brain/src/features/symptoms/ui/symptoms_page.dart';
import 'features/home/ui/home_page.dart';
import 'features/history/ui/history_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(), // Medications
    const SymptomsPage(),
    const HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.medication_liquid),
            label: 'Meds',
          ),
          NavigationDestination(
            icon: Icon(Icons.thermostat),
            label: 'Symptoms',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'History',
          ),
        ],
      ),
    );
  }
}