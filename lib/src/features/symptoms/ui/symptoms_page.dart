import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mama_brain/src/features/symptoms/ui/add_symptom_sheet.dart';

import '../../medications/ui/date_strip.dart';
import '../logic/symptom_provider.dart';
import '../../../core/models/symptom.dart';
import '../../../core/models/family_member.dart';
import '../../family/logic/family_provider.dart';

class SymptomsPage extends ConsumerWidget {
  const SymptomsPage({super.key});

  // Symptom identity for grouping: 'other' symptoms group by their note text
  // (so different free-text symptoms stay separate); the rest group by type.
  static String _identity(Symptom s) =>
      s.type == SymptomType.other ? 'other:${s.note ?? ''}' : s.type.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptoms = ref.watch(dailySymptomProvider);
    final family = ref.watch(familyProvider);

    // Collapse repeats of the same symptom for the same person into one block,
    // with each occurrence shown as a row inside (issue #4).
    final groups = <String, List<Symptom>>{};
    for (final s in symptoms) {
      groups
          .putIfAbsent('${s.familyMemberId}###${_identity(s)}', () => [])
          .add(s);
    }
    for (final entries in groups.values) {
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    final blocks = groups.values.toList()
      ..sort((a, b) => a.first.timestamp.compareTo(b.first.timestamp));

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
                    padding: const EdgeInsets.all(16),
                    itemCount: blocks.length,
                    itemBuilder: (context, index) {
                      return _SymptomBlock(entries: blocks[index], family: family);
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

// One block per (person, symptom). Shows the member and symptom title once,
// then a row per occurrence with its time, details, and edit/delete actions.
class _SymptomBlock extends ConsumerWidget {
  final List<Symptom> entries;
  final List<FamilyMember> family;

  const _SymptomBlock({required this.entries, required this.family});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s0 = entries.first;
    final member = family.firstWhere(
      (m) => m.id == s0.familyMemberId,
      orElse: () => family.isNotEmpty
          ? family.first
          : FamilyMember(id: '', name: 'Unknown', colorValue: 0xFF9E9E9E),
    );
    final color = Color(member.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                member.name,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
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
          Text(
            _title(s0),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final note = (s.type != SymptomType.other &&
            s.note != null &&
            s.note!.isNotEmpty)
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
