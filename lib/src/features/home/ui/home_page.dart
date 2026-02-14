import 'package:flutter/material.dart';
import '../../family/ui/family_avatar_row.dart';
import '../../medications/ui/date_strip.dart';
import '../../medications/ui/add_medication_sheet.dart';
import '../../medications/ui/daily_medication_list.dart';
import '../../../features/settings/ui/settings_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mama Brain"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const SettingsSheet(),
              );
            },
          ),
        ],
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to left
        children: [
          SizedBox(height: 20), // Add some top spacing
          DateStrip(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Family Members",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10), // Spacing between title and avatars
          FamilyAvatarRow(),

          Expanded(child: DailyMedicationList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddMedicationSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
