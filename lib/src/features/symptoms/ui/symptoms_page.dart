import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mama_brain/src/features/symptoms/ui/add_symptom_sheet.dart';

import '../../medications/ui/date_strip.dart';
import '../logic/symptom_provider.dart';
import '../../../core/models/symptom.dart';
import '../../../core/models/family_member.dart';
import '../../family/logic/family_provider.dart';

/// Symptom identity used for grouping: 'other' symptoms group by their note
/// text (so different free-text symptoms stay separate); the rest group by type.
String symptomIdentity(Symptom s) =>
    s.type == SymptomType.other ? 'other:${s.note ?? ''}' : s.type.name;

/// One person's symptoms for the selected day, already collapsed into blocks
/// of repeated symptoms.
class PersonSymptoms {
  final String familyMemberId;
  final List<List<Symptom>> blocks;

  PersonSymptoms({required this.familyMemberId, required this.blocks});
}

/// Groups a day's symptoms by person, then collapses repeats of the same
/// symptom within each person into a block. People are returned in the family
/// list's own order, so the tab reads person-by-person (issue #1).
List<PersonSymptoms> groupSymptomsByPerson(
  List<Symptom> symptoms,
  List<FamilyMember> family,
) {
  // Person -> symptom identity -> occurrences
  final byPerson = <String, Map<String, List<Symptom>>>{};
  for (final s in symptoms) {
    byPerson
        .putIfAbsent(s.familyMemberId, () => {})
        .putIfAbsent(symptomIdentity(s), () => [])
        .add(s);
  }

  // Family order first; any member no longer in the family list goes last so
  // their history never silently disappears.
  final orderedIds = [
    ...family.map((m) => m.id).where(byPerson.containsKey),
    ...byPerson.keys.where((id) => !family.any((m) => m.id == id)),
  ];

  return [
    for (final id in orderedIds)
      PersonSymptoms(
        familyMemberId: id,
        blocks: byPerson[id]!.values.map((entries) {
          final sorted = [...entries]
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return sorted;
        }).toList()
          ..sort((a, b) => a.first.timestamp.compareTo(b.first.timestamp)),
      ),
  ];
}

class SymptomsPage extends ConsumerWidget {
  const SymptomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptoms = ref.watch(dailySymptomProvider);
    final family = ref.watch(familyProvider);
    final sections = groupSymptomsByPerson(symptoms, family);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptoms Log'),
        centerTitle: true,
        backgroundColor: Colors.pink.shade50,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const DateStrip(),
          const SizedBox(height: 10),
          Expanded(
            child: symptoms.isEmpty
                ? const Center(child: Text('No symptoms recorded.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      return _PersonSection(
                        section: sections[index],
                        family: family,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink.shade100,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddSymptomSheet(),
          );
        },
        child: const Icon(Icons.add_reaction),
      ),
    );
  }
}

// All of one person's symptoms for the day, under a single person header, so
// you can read through one person before moving on to the next.
class _PersonSection extends StatelessWidget {
  final PersonSymptoms section;
  final List<FamilyMember> family;

  const _PersonSection({required this.section, required this.family});

  @override
  Widget build(BuildContext context) {
    final member = family.firstWhere(
      (m) => m.id == section.familyMemberId,
      orElse: () =>
          FamilyMember(id: '', name: 'Unknown', colorValue: 0xFF9E9E9E),
    );
    final color = Color(member.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Text(
                  member.name.isNotEmpty
                      ? member.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                member.name,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
            ],
          ),
        ),
        for (final block in section.blocks)
          _SymptomBlock(entries: block, color: color),
        const SizedBox(height: 12),
      ],
    );
  }
}

// One block per repeated symptom. The person is already named by the section
// header above, so the block only shows the symptom and its occurrences.
class _SymptomBlock extends ConsumerWidget {
  final List<Symptom> entries;
  final Color color;

  const _SymptomBlock({required this.entries, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s0 = entries.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title(s0),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (entries.length > 1)
                Text(
                  '${entries.length}×',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (final s in entries) _entryRow(context, ref, s),
        ],
      ),
    );
  }

  Widget _entryRow(BuildContext context, WidgetRef ref, Symptom s) {
    final detail = _detail(s);
    // Show the note here only for typed symptoms — for 'other' the note IS the
    // block title, so repeating it in the row would be redundant.
    final note =
        (s.type != SymptomType.other && s.note != null && s.note!.isNotEmpty)
            ? s.note
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              DateFormat('HH:mm').format(s.timestamp),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail != null) Text(detail),
                if (note != null)
                  Text(
                    note,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
            tooltip: 'Edit',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => AddSymptomSheet(symptomToEdit: s),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () =>
                ref.read(symptomProvider.notifier).deleteSymptom(s.id),
          ),
        ],
      ),
    );
  }

  String _title(Symptom s) {
    if (s.type == SymptomType.other) {
      return (s.note != null && s.note!.isNotEmpty) ? s.note! : 'Other';
    }
    return s.type.label;
  }

  // Extra per-occurrence detail shown next to the time (e.g. the temperature
  // for a fever, or the cough style). Null when there's nothing to add.
  String? _detail(Symptom s) {
    switch (s.type) {
      case SymptomType.fever:
        final temp = s.data['temp'];
        return temp != null ? '$temp °C' : null;
      case SymptomType.cough:
        final style = s.data['style'];
        return style != null ? '$style' : null;
      default:
        return null;
    }
  }
}
