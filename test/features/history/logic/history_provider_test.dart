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

      test('title is type name in sentence case', () {
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

        expect(event.title, 'Fever');
        container.dispose();
      });

      test('other symptom with note uses note as title', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15),
            type: SymptomType.other,
            note: 'Stomach ache',
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final event = events[normalize(DateTime(2025, 6, 15))]!.first;

        expect(event.title, 'Stomach ache');
        container.dispose();
      });

      test('other symptom without note falls back to sentence-case type name', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15),
            type: SymptomType.other,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final event = events[normalize(DateTime(2025, 6, 15))]!.first;

        expect(event.title, 'Other');
        container.dispose();
      });

      test('collapses repeated symptoms of the same type for the same family member into one event', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 8, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's2',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 14, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's3',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 20, 0),
            type: SymptomType.fever,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final dayEvents = events[normalize(DateTime(2025, 6, 15))]!;

        expect(dayEvents.length, 1);
        expect(dayEvents.first.title, 'Fever');
        container.dispose();
      });

      test('keeps separate events for different symptom types on the same day', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 8, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's2',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 14, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's3',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 20, 0),
            type: SymptomType.cough,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);
        final dayEvents = events[normalize(DateTime(2025, 6, 15))]!;

        expect(dayEvents.length, 2);
        expect(dayEvents.map((e) => e.title).toSet(), {'Fever', 'Cough'});
        container.dispose();
      });

      test('keeps separate events for the same symptom type logged by different family members', () {
        final otherMember = FamilyMember(
          id: 'fm-2',
          name: 'Bob',
          colorValue: 0xFF0000FF,
        );
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 8, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's2',
            familyMemberId: 'fm-2',
            timestamp: DateTime(2025, 6, 15, 14, 0),
            type: SymptomType.fever,
          ),
        ];

        final container = makeContainer(
          family: [familyMember, otherMember],
          symptoms: symptoms,
        );
        final events = container.read(historyEventsProvider);
        final dayEvents = events[normalize(DateTime(2025, 6, 15))]!;

        expect(dayEvents.length, 2);
        expect(dayEvents.map((e) => e.color).toSet(),
            {const Color(0xFFFF0000), const Color(0xFF0000FF)});
        container.dispose();
      });

      test('keeps separate events for the same symptom on different days', () {
        final symptoms = [
          Symptom(
            id: 's1',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 15, 8, 0),
            type: SymptomType.fever,
          ),
          Symptom(
            id: 's2',
            familyMemberId: 'fm-1',
            timestamp: DateTime(2025, 6, 16, 8, 0),
            type: SymptomType.fever,
          ),
        ];

        final container = makeContainer(symptoms: symptoms);
        final events = container.read(historyEventsProvider);

        expect(events[normalize(DateTime(2025, 6, 15))]!.length, 1);
        expect(events[normalize(DateTime(2025, 6, 16))]!.length, 1);
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
      test('creates an event on the day it was marked as taken', () {
        final meds = [
          Medication(
            id: 'm1',
            name: 'Ibuprofen',
            familyMemberId: 'fm-1',
            type: MedicationType.oneOff,
            startDate: DateTime(2025, 6, 15),
            takenLogs: [DateTime(2025, 6, 15, 9, 0)],
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

      test('creates no event when it has not been marked as taken', () {
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

        expect(events.isEmpty, isTrue);
        container.dispose();
      });
    });

    group('temporary medication events', () {
      test('creates an event only for the days marked as taken, not the full duration', () {
        final meds = [
          Medication(
            id: 'm2',
            name: 'Amoxicillin',
            familyMemberId: 'fm-1',
            type: MedicationType.temporary,
            startDate: DateTime(2025, 6, 10),
            durationInDays: 7,
            takenLogs: [
              DateTime(2025, 6, 10, 9, 0),
              DateTime(2025, 6, 12, 9, 0),
            ],
          ),
        ];

        final container = makeContainer(medications: meds);
        final events = container.read(historyEventsProvider);

        expect(events[normalize(DateTime(2025, 6, 10))], isNotNull);
        expect(events[normalize(DateTime(2025, 6, 11))], isNull);
        expect(events[normalize(DateTime(2025, 6, 12))], isNotNull);
        expect(events[normalize(DateTime(2025, 6, 13))], isNull);

        // Only the two taken days should appear, not all 7 scheduled days
        final allMedEvents = events.values
            .expand((list) => list)
            .where((e) => e.type == EventType.medication);
        expect(allMedEvents.length, 2);
        container.dispose();
      });

      test('creates no events for a medication that has never been taken', () {
        final meds = [
          Medication(
            id: 'm2',
            name: 'Amoxicillin',
            familyMemberId: 'fm-1',
            type: MedicationType.temporary,
            startDate: DateTime(2025, 6, 10),
            durationInDays: 7,
          ),
        ];

        final container = makeContainer(medications: meds);
        final events = container.read(historyEventsProvider);

        expect(events.isEmpty, isTrue);
        container.dispose();
      });
    });

    group('permanent medication events', () {
      test('creates an event only for the days marked as taken', () {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 2));
        final takenDay = startDate.add(const Duration(days: 1));

        final meds = [
          Medication(
            id: 'm3',
            name: 'Vitamin D',
            familyMemberId: 'fm-1',
            type: MedicationType.permanent,
            startDate: startDate,
            takenLogs: [takenDay.add(const Duration(hours: 9))],
          ),
        ];

        final container = makeContainer(medications: meds);
        final events = container.read(historyEventsProvider);

        final allMedEvents = events.values
            .expand((list) => list)
            .where((e) => e.type == EventType.medication);
        expect(allMedEvents.length, 1);
        expect(events[normalize(takenDay)], isNotNull);
        expect(events[normalize(startDate)], isNull);
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
            takenLogs: [DateTime(2025, 6, 15, 8, 0)],
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
            takenLogs: [DateTime(2025, 6, 16)],
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
