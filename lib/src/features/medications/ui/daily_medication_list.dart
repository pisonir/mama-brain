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


/// Dialog shown when marking a medication as taken, allowing the user to set
/// an exact time with a "Now" shortcut and a manual time picker.
class _TakenTimeDialog extends StatefulWidget {
  final DateTime date;
  final TimeOfDay? initialTime;

  const _TakenTimeDialog({required this.date, this.initialTime});

  @override
  State<_TakenTimeDialog> createState() => _TakenTimeDialogState();
}

class _TakenTimeDialogState extends State<_TakenTimeDialog> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime ?? TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('When was it taken?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _time.format(context),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => setState(() => _time = TimeOfDay.now()),
                child: const Text('Now'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            icon: const Icon(Icons.access_time),
            label: const Text('Pick a different time'),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final result = DateTime(
              widget.date.year,
              widget.date.month,
              widget.date.day,
              _time.hour,
              _time.minute,
            );
            Navigator.pop(context, result);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

Future<void> _showToggleTakenDialog(
  BuildContext context,
  WidgetRef ref,
  Medication med,
  DateTime selectedDate,
) async {
  final takenAt = await showDialog<DateTime>(
    context: context,
    builder: (ctx) => _TakenTimeDialog(date: selectedDate),
  );
  if (takenAt != null && context.mounted) {
    ref
        .read(medicationProvider.notifier)
        .toggleTaken(med.id, selectedDate, takenAt: takenAt);
  }
}

Future<void> _showEditTakenTimeDialog(
  BuildContext context,
  WidgetRef ref,
  Medication med,
  DateTime selectedDate,
  DateTime currentTakenAt,
) async {
  final newTakenAt = await showDialog<DateTime>(
    context: context,
    builder: (ctx) => _TakenTimeDialog(
      date: selectedDate,
      initialTime: TimeOfDay.fromDateTime(currentTakenAt),
    ),
  );
  if (newTakenAt != null && context.mounted) {
    ref
        .read(medicationProvider.notifier)
        .setTakenTime(med.id, selectedDate, newTakenAt);
  }
}

class DailyMedicationList extends ConsumerWidget {
  const DailyMedicationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(dailyMedicationsProvider);
    final familyMembers = ref.watch(familyProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    if (meds.isEmpty) {
      return const Center(child: Text('No medications for the selected date.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        final takenLog = med.takenLogs.where(
          (log) =>
              log.year == selectedDate.year &&
              log.month == selectedDate.month &&
              log.day == selectedDate.day,
        ).firstOrNull;
        final isTaken = takenLog != null;

        String subtitleText;
        if (isTaken) {
          subtitleText = 'Taken at ${DateFormat.Hm().format(takenLog)}';
        } else {
          switch (med.type) {
            case MedicationType.oneOff:
              subtitleText = 'One-off';
            case MedicationType.temporary:
              subtitleText = 'Temporary';
            case MedicationType.permanent:
              subtitleText = 'Permanent';
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
                if (val == true) {
                  _showToggleTakenDialog(context, ref, med, selectedDate);
                } else {
                  ref
                      .read(medicationProvider.notifier)
                      .toggleTaken(med.id, selectedDate);
                }
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
                if (isTaken)
                  GestureDetector(
                    onTap: () => _showEditTakenTimeDialog(
                      context, ref, med, selectedDate, takenLog,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subtitleText,
                          style: const TextStyle(color: Colors.green),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: Colors.green),
                      ],
                    ),
                  )
                else
                  Text(subtitleText),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
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
