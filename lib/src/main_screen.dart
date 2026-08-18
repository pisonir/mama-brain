import 'package:flutter/material.dart';
import 'package:mama_brain/src/features/symptoms/ui/symptoms_page.dart';
import 'core/prefs/last_tab_store.dart';
import 'features/home/ui/home_page.dart';
import 'features/history/ui/history_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Null until the stored tab has been read, so we never flash the first tab
  // before jumping to the one the user was actually last on.
  int? _currentIndex;

  final List<Widget> _pages = [
    const HomePage(), // Medications
    const SymptomsPage(),
    const HistoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _restoreLastTab();
  }

  Future<void> _restoreLastTab() async {
    final index = await LastTabStore.load(tabCount: _pages.length);
    if (mounted) setState(() => _currentIndex = index);
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    // Best-effort persist so the next launch reopens this tab.
    LastTabStore.save(index);
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex;
    if (index == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTabSelected,
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
