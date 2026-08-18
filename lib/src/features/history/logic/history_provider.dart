import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/family_member.dart';
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
  final String familyMemberId;
  final String memberName;

  // Position of this member in the family list, used to keep a day's events in
  // the same person order the rest of the app uses.
  final int memberOrder;

  int count = 1;

  _Agg({
    required this.id,
    required this.title,
    required this.color,
    required this.type,
    required this.familyMemberId,
    required this.memberName,
    required this.memberOrder,
  });
}

// Return a Map where key = Date (normalized), value = list of events
final historyEventsProvider = Provider<Map<DateTime, List<HistoryEvent>>>((ref) {
  final meds = ref.watch(medicationProvider);
  final symptoms = ref.watch(symptomProvider);
  final family = ref.watch(familyProvider);

  // Helper to look up a family member; null when they no longer exist.
  FamilyMember? findMember(String familyMemberId) {
    for (final m in family) {
      if (m.id == familyMemberId) return m;
    }
    return null;
  }

  int memberOrderOf(String familyMemberId) {
    final index = family.indexWhere((m) => m.id == familyMemberId);
    // Unknown members sort after everyone known.
    return index < 0 ? family.length : index;
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
    final title =
        s.type == SymptomType.other && s.note != null && s.note!.isNotEmpty
            ? s.note!
            : s.type.label;
    final member = findMember(s.familyMemberId);
    addOccurrence(
      s.timestamp,
      'symptom|${s.familyMemberId}|$title',
      () => _Agg(
        id: s.id,
        title: title,
        color: Color(member?.colorValue ?? 0xFF9E9E9E),
        type: EventType.symptom,
        familyMemberId: s.familyMemberId,
        memberName: member?.name ?? 'Unknown',
        memberOrder: memberOrderOf(s.familyMemberId),
      ),
    );
  }

  // 2. Process Medications — only on days actually marked as taken. Multiple
  // doses of the same medicine on one day collapse into a single entry.
  for (final m in meds) {
    final member = findMember(m.familyMemberId);
    for (final takenDate in m.takenLogs) {
      addOccurrence(
        takenDate,
        'medication|${m.familyMemberId}|${m.name}',
        () => _Agg(
          id: m.id,
          title: m.name,
          color: Color(member?.colorValue ?? 0xFF9E9E9E),
          type: EventType.medication,
          familyMemberId: m.familyMemberId,
          memberName: member?.name ?? 'Unknown',
          memberOrder: memberOrderOf(m.familyMemberId),
        ),
      );
    }
  }

  // Freeze into immutable events, ordered medications first and symptoms after
  // (issue #3), then by the family list's person order, then by title so the
  // output is stable.
  final events = <DateTime, List<HistoryEvent>>{};
  perDay.forEach((day, group) {
    final aggs = group.values.toList()
      ..sort((a, b) {
        if (a.type != b.type) {
          return a.type == EventType.medication ? -1 : 1;
        }
        if (a.memberOrder != b.memberOrder) {
          return a.memberOrder.compareTo(b.memberOrder);
        }
        return a.title.compareTo(b.title);
      });

    events[day] = [
      for (final agg in aggs)
        HistoryEvent(
          id: agg.id,
          title: agg.title,
          date: day,
          color: agg.color,
          type: agg.type,
          familyMemberId: agg.familyMemberId,
          memberName: agg.memberName,
          count: agg.count,
        ),
    ];
  });

  return events;
});
