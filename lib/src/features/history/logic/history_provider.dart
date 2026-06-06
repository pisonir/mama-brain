import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/symptom.dart';
import '../../family/logic/family_provider.dart';
import '../../medications/logic/medication_provider.dart';
import '../../symptoms/logic/symptom_provider.dart';
import 'history_event.dart';

// Return a Map where key = Date (normalized), value = list of events
final historyEventsProvider = Provider<Map<DateTime, List<HistoryEvent>>>((ref) {
  final meds = ref.watch(medicationProvider);
  final symptoms = ref.watch(symptomProvider);
  final family = ref.watch(familyProvider);

  // Helper to find family color
  Color getFamilyColor(String familyMemberId) {
    final member = family.firstWhere((m) => m.id == familyMemberId, orElse: () => family.first);
    return Color(member.colorValue);
  }

  // Helper to normalize date (remove time)
  DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  final Map<DateTime, List<HistoryEvent>> events = {};

  void addEvent(DateTime date, HistoryEvent event) {
    final key = normalize(date);
    if (events[key] == null) events[key] = [];
    events[key]!.add(event);
  }

  // 1. Process Symptoms
  // Collapse repeats of the same symptom (by family member, title and day)
  // into a single calendar entry, e.g. measuring a fever 3 times in a day
  // should still show just one "Fever" marker on that day.
  final seenSymptoms = <String>{};
  for (final s in symptoms) {
    final title = s.type == SymptomType.other && s.note != null && s.note!.isNotEmpty
        ? s.note!
        : s.type.name[0].toUpperCase() + s.type.name.substring(1);
    final dedupeKey = '${normalize(s.timestamp)}|${s.familyMemberId}|$title';
    if (!seenSymptoms.add(dedupeKey)) continue;

    addEvent(s.timestamp, HistoryEvent(
      id: s.id,
      title: title,
      date: s.timestamp,
      color: getFamilyColor(s.familyMemberId),
      type: EventType.symptom,
      ),
    );
  }

  // 2. Process Medications
  // Only show a medication on days it was actually marked as taken (checked
  // off in the medication view) — not for every day it was scheduled.
  for (final m in meds) {
    final color = getFamilyColor(m.familyMemberId);
    for (final takenDate in m.takenLogs) {
      addEvent(
        takenDate, HistoryEvent(
          id: m.id,
          title: m.name,
          date: takenDate,
          color: color,
          type: EventType.medication,
          )
      );
    }
  }

  return events;
});