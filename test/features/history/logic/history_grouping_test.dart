import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/features/history/logic/history_event.dart';
import 'package:mama_brain/src/features/history/logic/history_grouping.dart';

void main() {
  final alice = FamilyMember(id: 'fm-1', name: 'Alice', colorValue: 0xFFFF0000);
  final bob = FamilyMember(id: 'fm-2', name: 'Bob', colorValue: 0xFF0000FF);

  HistoryEvent event(
    String id,
    String memberId,
    String title,
    EventType type, {
    String memberName = 'Someone',
    int count = 1,
  }) {
    return HistoryEvent(
      id: id,
      title: title,
      date: DateTime(2025, 6, 15),
      color: Colors.grey,
      type: type,
      familyMemberId: memberId,
      memberName: memberName,
      count: count,
    );
  }

  group('groupEventsByPerson', () {
    test('returns an empty list for a day with no events', () {
      expect(groupEventsByPerson([], [alice, bob]), isEmpty);
    });

    test('collects each person\'s events into one section', () {
      final events = [
        event('m1', 'fm-1', 'Paracetamol', EventType.medication),
        event('s1', 'fm-2', 'Fever', EventType.symptom),
        event('s2', 'fm-1', 'Cough', EventType.symptom),
      ];

      final sections = groupEventsByPerson(events, [alice, bob]);

      expect(sections.length, 2);
      expect(sections[0].familyMemberId, 'fm-1');
      expect(sections[0].events.length, 2);
      expect(sections[1].familyMemberId, 'fm-2');
      expect(sections[1].events.length, 1);
    });

    test('sections follow the family list order', () {
      final events = [
        event('s1', 'fm-2', 'Fever', EventType.symptom),
        event('s2', 'fm-1', 'Fever', EventType.symptom),
      ];

      expect(
        groupEventsByPerson(events, [alice, bob])
            .map((s) => s.familyMemberId)
            .toList(),
        ['fm-1', 'fm-2'],
      );
      expect(
        groupEventsByPerson(events, [bob, alice])
            .map((s) => s.familyMemberId)
            .toList(),
        ['fm-2', 'fm-1'],
      );
    });

    test('preserves incoming order within a person (medications first)', () {
      // historyEventsProvider already sorts medications before symptoms; the
      // grouping must not disturb that.
      final events = [
        event('m1', 'fm-1', 'Paracetamol', EventType.medication),
        event('m2', 'fm-1', 'Ibuprofen', EventType.medication),
        event('s1', 'fm-1', 'Fever', EventType.symptom),
      ];

      final section = groupEventsByPerson(events, [alice]).single;

      expect(section.events.map((e) => e.id).toList(), ['m1', 'm2', 's1']);
      expect(section.events.first.type, EventType.medication);
      expect(section.events.last.type, EventType.symptom);
    });

    test('uses the live family name and color', () {
      final events = [
        event('s1', 'fm-1', 'Fever', EventType.symptom, memberName: 'Stale'),
      ];

      final section = groupEventsByPerson(events, [alice]).single;

      expect(section.memberName, 'Alice');
      expect(section.color, const Color(0xFFFF0000));
    });

    test('falls back to event data for a member no longer in the family', () {
      final events = [
        event('s1', 'ghost', 'Fever', EventType.symptom, memberName: 'Ghost'),
        event('s2', 'fm-1', 'Fever', EventType.symptom),
      ];

      final sections = groupEventsByPerson(events, [alice]);

      // Known members first, departed members last — never dropped.
      expect(sections.map((s) => s.familyMemberId).toList(), ['fm-1', 'ghost']);
      expect(sections.last.memberName, 'Ghost');
    });

    test('carries the repeat count through untouched', () {
      final events = [
        event('m1', 'fm-1', 'Paracetamol', EventType.medication, count: 3),
      ];

      expect(groupEventsByPerson(events, [alice]).single.events.single.count, 3);
    });
  });
}
