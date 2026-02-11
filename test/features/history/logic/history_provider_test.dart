import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/history/logic/history_event.dart';
import 'package:mama_brain/src/features/history/logic/history_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  final familyMember = FamilyMember(
    id: 'fm-1',
    name: 'Alice',
    colorValue: 0xFFFF0000,
  );

  ProviderContainer makeContainer({
    List<FamilyMember>? family,
    List<Medication> medications = const [],
    List<Symptom> symptoms = const [],
  }) {
    return ProviderContainer(
      overrides: [
        familyProvider.overrideWith(
          (_) => FakeFamilyNotifier(family ?? [familyMember]),
        ),
        medicationProvider.overrideWith(
          (_) => FakeMedicationNotifier(medications),
        ),
        symptomProvider.overrideWith(
          (_) => FakeSymptomNotifier(symptoms),
        ),
      ],
    );
  }

  DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  group('historyEventsProvider', () {
    group('symptom events', () {
      test('creates one event per symptom', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 10, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's2',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 14, 0),
            type: SymptomType.cough,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final dayEvents = events[normalize(DateTime(2025, 6, 15))]!;

        expect(dayEvents.length, 2);
        expect(dayEvents.every((e) => e.type == EventType.symptom), isTrue);
        container.dispose();
      });

      test('title is type name uppercased', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15),
            type: SymptomType.fever,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final event = events[normalize(DateTime(2025, 6, 15))]!.first;

        expect(event.title, 'FEVER');
        container.dispose();
      });

      test('uses family member color', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15),
            type: SymptomType.rash,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final event = events[normalize(DateTime(2025, 6, 15))]!.first;

        expect(event.color, const Color(0xFFFF0000));
        container.dispose();
      });
    });

    group('oneOff medication events', () {
      test('creates single event on start date', () {
        final meds = [
          Medication(
            id: 'm1',
            name: 'Ibuprofen',
            familyMemberId: 'fm-1',
            type: MedicationType.oneOff,
            startDate: DateTime(2025, 6, 15),
          ),
        ];

        final container = makeContainer(medications: meds);
        final events = container.read(historyEventsProvider);

        expect(events.length, 1);
        final dayEvents = events[normalize(DateTime(2025, 6, 15))]!;
        expect(dayEvents.length, 1);
        expect(dayEvents.first.title, 'Ibuprofen');
        expect(dayEvents.first.type, EventType.medication);
        container.dispose();
      });
    });

    group('temporary medication events', () {
      test('creates one event per day for duration', () {
        final meds = [
          Medication(
            id: 'm2',
            name: 'Amoxicillin',
            familyMemberId: 'fm-1',
            type: MedicationType.temporary,
            startDate: DateTime(2025, 6, 10),
            durationInDays: 3,
          ),
        ];

        final container = makeContainer(medications: meds);
        final events = container.read(historyEventsProvider);

        expect(events[normalize(DateTime(2025, 6, 10))], isNotNull);
        expect(events[normalize(DateTime(2025, 6, 11))], isNotNull);
        expect(events[normalize(DateTime(2025, 6, 12))], isNotNull);
        expect(events[normalize(DateTime(2025, 6, 13))], isNull);

        // Total medication events across all days
        final allMedEvents = events.values
            .expand((list) => list)
            .where((e) => e.type == EventType.medication);
        expect(allMedEvents.length, 3);
        container.dispose();
      });
    });

    group('permanent medication events', () {
      test('creates events from start date to today', () {
        // Use a recent start date (3 days ago) for determinism
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 2));

        final meds = [
          Medication(
            id: 'm3',
            name: 'Vitamin D',
            familyMemberId: 'fm-1',
            type: MedicationType.permanent,
            startDate: startDate,
          ),
        ];

        final container = makeContainer(medications: meds);
        final events = container.read(historyEventsProvider);

        // Should have 3 days: startDate, startDate+1, today
        final allMedEvents = events.values
            .expand((list) => list)
            .where((e) => e.type == EventType.medication);
        expect(allMedEvents.length, 3);

        // Verify start date has an event
        expect(events[normalize(startDate)], isNotNull);
        // Verify today has an event
        expect(events[normalize(now)], isNotNull);
        container.dispose();
      });
    });

    group('mixed events', () {
      test('groups events under normalized date keys', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 10, 30),
            type: SymptomType.fever,
          ),
        ];
        final meds = [
          Medication(
            id: 'm1',
            name: 'Aspirin',
            familyMemberId: 'fm-1',
            type: MedicationType.oneOff,
            startDate: DateTime(2025, 6, 15, 8, 0),
          ),
        ];

        final container =
            makeContainer(medications: meds, symptoms: symptoms);
        final events = container.read(historyEventsProvider);

        final dayEvents = events[normalize(DateTime(2025, 6, 15))]!;
        expect(dayEvents.length, 2);

        final types = dayEvents.map((e) => e.type).toSet();
        expect(types, {EventType.symptom, EventType.medication});
        container.dispose();
      });

      test('events on different days go to different keys', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15),
            type: SymptomType.cough,
          ),
        ];
        final meds = [
          Medication(
            id: 'm1',
            name: 'Aspirin',
            familyMemberId: 'fm-1',
            type: MedicationType.oneOff,
            startDate: DateTime(2025, 6, 16),
          ),
        ];

        final container =
            makeContainer(medications: meds, symptoms: symptoms);
        final events = container.read(historyEventsProvider);

        expect(events.length, 2);
        expect(events[normalize(DateTime(2025, 6, 15))]!.length, 1);
        expect(events[normalize(DateTime(2025, 6, 16))]!.length, 1);
        container.dispose();
      });
    });
  });
}
