import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/medications/logic/date_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/medications/ui/add_medication_sheet.dart';
import '../logic/daily_medications_provider.dart';
import 'package:intl/intl.dart';

void _confirmDelete(BuildContext context, WidgetRef ref, Medication med) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Medication?'),
        content: Text("Are you sure you want to delete '${med.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(medicationProvider.notifier).deleteMedication(med.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

bool _isTaken(Medication med, DateTime date) {
  return med.takenLogs.any(
    (log) =>
        log.year == date.year && log.month == date.month && log.day == date.day,
  );
}

class DailyMedicationList extends ConsumerWidget {
  const DailyMedicationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(dailyMedicationsProvider);
    final familyMembers = ref.watch(familyProvider);

    if (meds.isEmpty) {
      return const Center(child: Text('No medications for the selected date.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        final selectedDate = ref.watch(selectedDateProvider);
        final isTaken = _isTaken(med, selectedDate);
        String subtitleText = med.type.name;
        if (med.type == MedicationType.oneOff) {
          if (isTaken) {
            final takenLog = med.takenLogs.firstWhere(
              (log) =>
                  log.year == selectedDate.year &&
                  log.month == selectedDate.month &&
                  log.day == selectedDate.day,
            );
            subtitleText = 'Taken at ${DateFormat.Hm().format(takenLog)}';
          } else {
            subtitleText = 'One-off';
          }
        }

        final member = familyMembers.firstWhere(
          (m) => m.id == med.familyMemberId,
          orElse: () => FamilyMember(id: '', name: 'Unknown', colorValue: 0xFF9E9E9E),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isTaken ? Colors.green.shade50 : Colors.white,
          child: ListTile(
            leading: Checkbox(
              value: isTaken,
              onChanged: (val) {
                ref
                    .read(medicationProvider.notifier)
                    .toggleTaken(med.id, ref.watch(selectedDateProvider));
              },
            ),
            title: Text(
              med.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isTaken ? TextDecoration.lineThrough : null,
                color: isTaken ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 6,
                      backgroundColor: Color(member.colorValue),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      member.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Text(subtitleText),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // <-- CRITICAL
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          AddMedicationSheet(medicationToEdit: med),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    _confirmDelete(context, ref, med);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
