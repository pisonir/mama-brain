import 'package:flutter/material.dart';
import '../../../core/models/family_member.dart';
import 'history_event.dart';

/// One person's events for a single day.
class PersonHistory {
  final String familyMemberId;
  final String memberName;
  final Color color;
  final List<HistoryEvent> events;

  PersonHistory({
    required this.familyMemberId,
    required this.memberName,
    required this.color,
    required this.events,
  });
}

/// Groups a day's events per person so the history list reads person-by-person
/// (issue #3) instead of interleaving everyone.
///
/// People come back in the family list's own order — the same order used by the
/// avatar row and the forms. Anyone no longer in the family list is appended at
/// the end so their history never silently disappears.
///
/// Within a person, the incoming order is preserved: [historyEventsProvider]
/// already sorts medications before symptoms, so each person's medications are
/// listed first.
List<PersonHistory> groupEventsByPerson(
  List<HistoryEvent> dayEvents,
  List<FamilyMember> family,
) {
  final byPerson = <String, List<HistoryEvent>>{};
  for (final event in dayEvents) {
    byPerson.putIfAbsent(event.familyMemberId, () => []).add(event);
  }

  final orderedIds = [
    ...family.map((m) => m.id).where(byPerson.containsKey),
    ...byPerson.keys.where((id) => !family.any((m) => m.id == id)),
  ];

  return [
    for (final id in orderedIds)
      PersonHistory(
        familyMemberId: id,
        // Prefer the live family record; fall back to whatever the event
        // captured for members who have since been removed.
        memberName: family.where((m) => m.id == id).map((m) => m.name).firstOrNull ??
            byPerson[id]!.first.memberName,
        color: family
                .where((m) => m.id == id)
                .map((m) => Color(m.colorValue))
                .firstOrNull ??
            byPerson[id]!.first.color,
        events: byPerson[id]!,
      ),
  ];
}
