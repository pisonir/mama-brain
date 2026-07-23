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

// The taken-log DateTime for [med] on [date], or null if it wasn't taken that
// day. A medication has at most one log per calendar day.
DateTime? _takenLogForDay(Medication med, DateTime date) {
  return med.takenLogs
      .where((log) =>
          log.year == date.year &&
          log.month == date.month &&
          log.day == date.day)
      .firstOrNull;
}

String _typeLabel(MedicationType type) {
  switch (type) {
    case MedicationType.oneOff:
      return 'One-off';
    case MedicationType.temporary:
      return 'Temporary';
    case MedicationType.permanent:
      return 'Permanent';
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

    // Group by (family member, medicine name) so the same medicine logged
    // several times for the same person collapses into a single block.
    final groups = <String, List<Medication>>{};
    for (final med in meds) {
      groups.putIfAbsent('${med.familyMemberId}###${med.name}', () => []).add(med);
    }

    // Chronological order (issue #2): within each block, sort entries by taken
    // time; untaken entries sink to the bottom.
    for (final entries in groups.values) {
      entries.sort((a, b) => _compareByTakenTime(a, b, selectedDate));
    }

    // Order the blocks the same way — earliest taken time first, blocks with
    // nothing taken yet at the end (alphabetical among themselves).
    final blocks = groups.values.toList()
      ..sort((a, b) {
        final ta = _earliestTaken(a, selectedDate);
        final tb = _earliestTaken(b, selectedDate);
        if (ta == null && tb == null) return a.first.name.compareTo(b.first.name);
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        return _MedicationBlock(
          entries: blocks[index],
          selectedDate: selectedDate,
          familyMembers: familyMembers,
        );
      },
    );
  }

  int _compareByTakenTime(Medication a, Medication b, DateTime date) {
    final ta = _takenLogForDay(a, date);
    final tb = _takenLogForDay(b, date);
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return ta.compareTo(tb);
  }

  DateTime? _earliestTaken(List<Medication> entries, DateTime date) {
    final times = entries
        .map((m) => _takenLogForDay(m, date))
        .whereType<DateTime>()
        .toList()
      ..sort();
    return times.firstOrNull;
  }
}

// A block groups every entry of the same medicine for the same person on the
// selected day: one header (member + medicine name + an overall edit), then a
// row per logged dose, each with its own taken time (tap to edit) and a delete.
class _MedicationBlock extends ConsumerWidget {
  final List<Medication> entries;
  final DateTime selectedDate;
  final List<FamilyMember> familyMembers;

  const _MedicationBlock({
    required this.entries,
    required this.selectedDate,
    required this.familyMembers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final med0 = entries.first;
    final member = familyMembers.firstWhere(
      (m) => m.id == med0.familyMemberId,
      orElse: () =>
          FamilyMember(id: '', name: 'Unknown', colorValue: 0xFF9E9E9E),
    );
    final allTaken =
        entries.every((m) => _takenLogForDay(m, selectedDate) != null);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: allTaken ? Colors.green.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: member dot + name, and the block-wide edit (edits the
            // medicine's details for the whole block).
            Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: Color(member.colorValue),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  tooltip: 'Edit medication',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddMedicationSheet(medicationToEdit: med0),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                med0.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: allTaken ? TextDecoration.lineThrough : null,
                  color: allTaken ? Colors.grey : Colors.black,
                ),
              ),
            ),
            for (final med in entries) _buildEntryRow(context, ref, med),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, WidgetRef ref, Medication med) {
    final takenLog = _takenLogForDay(med, selectedDate);
    final isTaken = takenLog != null;

    return Row(
      children: [
        Checkbox(
          visualDensity: VisualDensity.compact,
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
        Expanded(
          child: isTaken
              ? GestureDetector(
                  onTap: () => _showEditTakenTimeDialog(
                    context, ref, med, selectedDate, takenLog,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Taken at ${DateFormat.Hm().format(takenLog)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 12, color: Colors.green),
                    ],
                  ),
                )
              : Text(_typeLabel(med.type)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
          tooltip: 'Delete this entry',
          onPressed: () => _confirmDelete(context, ref, med),
        ),
      ],
    );
  }
}
