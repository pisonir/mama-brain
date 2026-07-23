import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/symptom.dart';
import '../../family/logic/family_provider.dart';
import '../../medications/logic/medication_provider.dart';
import '../../symptoms/logic/symptom_provider.dart';
import 'history_event.dart';

// Mutable accumulator used while tallying repeats, before we freeze each group
// into an immutable HistoryEvent with its final count.
class _Agg {
  final String id;
  final String title;
  final Color color;
  final EventType type;
  int count = 1;

  _Agg({
    required this.id,
    required this.title,
    required this.color,
    required this.type,
  });
}

// Return a Map where key = Date (normalized), value = list of events
final historyEventsProvider = Provider<Map<DateTime, List<HistoryEvent>>>((ref) {
  final meds = ref.watch(medicationProvider);
  final symptoms = ref.watch(symptomProvider);
  final family = ref.watch(familyProvider);

  // Helper to find family color
  Color getFamilyColor(String familyMemberId) {
    final member = family.firstWhere((m) => m.id == familyMemberId,
        orElse: () => family.first);
    return Color(member.colorValue);
  }

  // Helper to normalize date (remove time)
  DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // Per day, per dedupe-key aggregation. Repeats of the same medication/symptom
  // for the same person on the same day collapse into one entry whose `count`
  // tracks how many times it happened.
  final Map<DateTime, Map<String, _Agg>> perDay = {};

  void addOccurrence(DateTime date, String key, _Agg Function() build) {
    final day = normalize(date);
    final group = perDay.putIfAbsent(day, () => {});
    final existing = group[key];
    if (existing == null) {
      group[key] = build();
    } else {
      existing.count++;
    }
  }

  // 1. Process Symptoms — collapse repeats of the same symptom (by family
  // member, title and day) into a single calendar entry.
  for (final s in symptoms) {
    final title = s.type == SymptomType.other &&
            s.note != null &&
            s.note!.isNotEmpty
        ? s.note!
        : s.type.label;
    addOccurrence(
      s.timestamp,
      'symptom|${s.familyMemberId}|$title',
      () => _Agg(
        id: s.id,
        title: title,
        color: getFamilyColor(s.familyMemberId),
        type: EventType.symptom,
      ),
    );
  }

  // 2. Process Medications — only on days actually marked as taken. Multiple
  // doses of the same medicine on one day collapse into a single entry.
  for (final m in meds) {
    for (final takenDate in m.takenLogs) {
      addOccurrence(
        takenDate,
        'medication|${m.familyMemberId}|${m.name}',
        () => _Agg(
          id: m.id,
          title: m.name,
          color: getFamilyColor(m.familyMemberId),
          type: EventType.medication,
        ),
      );
    }
  }

  // Freeze into immutable events.
  final events = <DateTime, List<HistoryEvent>>{};
  perDay.forEach((day, group) {
    events[day] = [
      for (final agg in group.values)
        HistoryEvent(
          id: agg.id,
          title: agg.title,
          date: day,
          color: agg.color,
          type: agg.type,
          count: agg.count,
        ),
    ];
  });

  return events;
});
