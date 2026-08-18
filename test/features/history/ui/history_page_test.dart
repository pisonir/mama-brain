import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/history/ui/history_page.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  final alice = FamilyMember(id: 'fm-1', name: 'Alice', colorValue: 0xFFFF0000);
  final bob = FamilyMember(id: 'fm-2', name: 'Bob', colorValue: 0xFF0000FF);

  // A day inside the calendar's supported range that is also the focused month,
  // so the cells under test are actually laid out.
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);

  // The default 800x600 test surface is shorter than a real phone, so the
  // content under the calendar would never be laid out. Use a typical phone
  // viewport (400x800 logical pixels) instead.
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  // Brings the day-detail section under the calendar into view.
  Future<void> scrollToDetails(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
  }

  Widget wrap({
    required List<FamilyMember> family,
    List<Medication> medications = const [],
    List<Symptom> symptoms = const [],
  }) {
    return ProviderScope(
      overrides: [
        familyProvider.overrideWith((_) => FakeFamilyNotifier(family)),
        medicationProvider
            .overrideWith((_) => FakeMedicationNotifier(medications)),
        symptomProvider.overrideWith((_) => FakeSymptomNotifier(symptoms)),
      ],
      child: const MaterialApp(home: HistoryPage()),
    );
  }

  Medication med(String id, String name, String memberId) => Medication(
        id: id,
        name: name,
        familyMemberId: memberId,
        type: MedicationType.oneOff,
        startDate: day,
        takenLogs: [day.add(const Duration(hours: 9))],
      );

  Symptom symptom(String id, SymptomType type, String memberId) => Symptom(
        id: id,
        familyMemberId: memberId,
        timestamp: day.add(const Duration(hours: 10)),
        type: type,
      );

  group('HistoryPage calendar', () {
    testWidgets('renders an empty month without layout errors', (tester) async {
      await tester.pumpWidget(wrap(family: [alice]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a busy day with more events than fit does not overflow',
        (tester) async {
      // Taller rows show up to three labels plus a "+N" line. Five events
      // exercises the overflow path — a RenderFlex overflow would fail here.
      await tester.pumpWidget(wrap(
        family: [alice, bob],
        medications: [
          med('m1', 'Paracetamol', 'fm-1'),
          med('m2', 'Ibuprofen', 'fm-1'),
          med('m3', 'Antibiotic', 'fm-2'),
        ],
        symptoms: [
          symptom('s1', SymptomType.fever, 'fm-1'),
          symptom('s2', SymptomType.cough, 'fm-2'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The day number stays visible above the event labels.
      expect(find.text('${day.day}'), findsWidgets);
    });

    testWidgets('long medication names do not overflow a cell', (tester) async {
      await tester.pumpWidget(wrap(
        family: [alice],
        medications: [
          med('m1', 'A very long medication name that cannot fit', 'fm-1'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HistoryPage day details', () {
    testWidgets('prompts to pick a day before anything is selected',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(family: [alice]));
      await tester.pumpAndSettle();
      await scrollToDetails(tester);

      expect(find.text('Select a day to see details.'), findsOneWidget);
    });

    testWidgets('selecting a day groups its entries under each person',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        family: [alice, bob],
        medications: [med('m1', 'Paracetamol', 'fm-1')],
        symptoms: [symptom('s1', SymptomType.fever, 'fm-2')],
      ));
      await tester.pumpAndSettle();

      // Tap today's cell to select it.
      await tester.tap(find.text('${day.day}').first);
      await tester.pumpAndSettle();
      await scrollToDetails(tester);

      expect(tester.takeException(), isNull);

      // Both people get a header, and their entries are listed by name only —
      // the SYMPTOM / MEDICATION category label is intentionally gone.
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
      expect(find.text('Paracetamol'), findsWidgets);
      expect(find.text('SYMPTOM'), findsNothing);
      expect(find.text('MEDICATION'), findsNothing);
    });

    testWidgets('a day with no entries says so', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(family: [alice]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('${day.day}').first);
      await tester.pumpAndSettle();
      await scrollToDetails(tester);

      expect(find.text('No events for this day.'), findsOneWidget);
    });
  });
}
