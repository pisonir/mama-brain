import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/medication.dart';
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
  for (final s in symptoms) {
    addEvent(s.timestamp, HistoryEvent(
      id: s.id,
      title: s.type.name.toUpperCase(),
      date: s.timestamp,
      color: getFamilyColor(s.familyMemberId),
      type: EventType.symptom,
      ),
    );
  }

  // 2. Process Medications
  for (final m in meds) {
    final color = getFamilyColor(m.familyMemberId);
    if (m.type == MedicationType.oneOff){
      addEvent(
        m.startDate, HistoryEvent(
          id: m.id, 
          title: m.name, 
          date: m.startDate, 
          color: color, 
          type: EventType.medication,
          )
      );
    }
    else if (m.type == MedicationType.temporary && m.durationInDays != null) {
      // Loop through each day of the medication duration
      for (int i = 0; i < m.durationInDays!; i++) {
        final date = m.startDate.add(Duration(days: i));
        addEvent(
          date, HistoryEvent(
            id: m.id, 
            title: m.name, 
            date: date, 
            color: color, 
            type: EventType.medication,
            )
        );
      }
    }
    else if (m.type == MedicationType.permanent) {
      // Show from start date until today (limit to 365 days to avoid infinte loops)
      final today = DateTime.now();
      DateTime current = m.startDate;
      int safetyCounter = 0;

      while (normalize(current).isBefore(today) || normalize(current).isAtSameMomentAs(today)) {
        if (safetyCounter > 365) break; // Safety break to prevent infinite loop
        addEvent(
          current, HistoryEvent(
            id: m.id, 
            title: m.name, 
            date: current, 
            color: color, 
            type: EventType.medication,
            )
        );
        current = current.add(const Duration(days: 1));
        safetyCounter++;
      }
    }
  }

  return events;
});