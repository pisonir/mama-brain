import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/symptom.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/symptoms/logic/symptom_provider.dart';
import 'package:mama_brain/src/features/symptoms/ui/add_symptom_sheet.dart';
import 'package:mama_brain/src/features/symptoms/ui/symptoms_page.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  final alice = FamilyMember(id: 'fm-1', name: 'Alice', colorValue: 0xFFFF0000);
  final bob = FamilyMember(id: 'fm-2', name: 'Bob', colorValue: 0xFF0000FF);

  final now = DateTime.now();
  DateTime at(int hour) => DateTime(now.year, now.month, now.day, hour);

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Widget wrap(Widget child, {
    required List<FamilyMember> family,
    List<Symptom> symptoms = const [],
  }) {
    return ProviderScope(
      overrides: [
        familyProvider.overrideWith((_) => FakeFamilyNotifier(family)),
        symptomProvider.overrideWith((_) => FakeSymptomNotifier(symptoms)),
      ],
      child: MaterialApp(home: child),
    );
  }

  Symptom symptom(String id, String memberId, SymptomType type, int hour,
      {Map<String, dynamic> data = const {}}) {
    return Symptom(
      id: id,
      familyMemberId: memberId,
      timestamp: at(hour),
      type: type,
      data: data,
    );
  }

  group('SymptomsPage', () {
    testWidgets('shows an empty message when nothing is logged', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(const SymptomsPage(), family: [alice]));
      await tester.pumpAndSettle();

      expect(find.text('No symptoms recorded.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('groups the day under one header per person', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        const SymptomsPage(),
        family: [alice, bob],
        symptoms: [
          symptom('s1', 'fm-1', SymptomType.fever, 8, data: {'temp': 38.5}),
          symptom('s2', 'fm-2', SymptomType.cough, 9, data: {'style': 'Dry'}),
          symptom('s3', 'fm-1', SymptomType.rash, 10),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // One header per person, not one per symptom.
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Fever'), findsOneWidget);
      expect(find.text('Rash'), findsOneWidget);
      expect(find.text('Cough'), findsOneWidget);
    });

    testWidgets('collapses a repeated symptom into one block with a count',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        const SymptomsPage(),
        family: [alice],
        symptoms: [
          symptom('s1', 'fm-1', SymptomType.fever, 8, data: {'temp': 38.5}),
          symptom('s2', 'fm-1', SymptomType.fever, 14, data: {'temp': 39.0}),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // A single "Fever" block carrying both readings.
      expect(find.text('Fever'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.text('38.5 °C'), findsOneWidget);
      expect(find.text('39.0 °C'), findsOneWidget);
    });

    testWidgets('uses Title Case labels, never all-caps', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        const SymptomsPage(),
        family: [alice],
        symptoms: [
          symptom('s1', 'fm-1', SymptomType.diarrhea, 8),
          symptom('s2', 'fm-1', SymptomType.pain, 9),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Diarrhea'), findsOneWidget);
      expect(find.text('Pain'), findsOneWidget);
      expect(find.text('DIARRHEA'), findsNothing);
      expect(find.text('PAIN'), findsNothing);
    });
  });

  group('AddSymptomSheet keyboard handling', () {
    // Regression for the note field being hidden behind the keyboard: the sheet
    // content must live inside a scroll view, so Flutter can bring the focused
    // field into view when the keyboard shrinks the viewport.
    testWidgets('keeps its content scrollable while the keyboard is open',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        // A 300px keyboard inset, as the platform reports when it opens.
        const MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
          child: Scaffold(body: AddSymptomSheet()),
        ),
        family: [alice],
      ));
      await tester.pumpAndSettle();

      // No RenderFlex overflow even with the keyboard taking 300px.
      expect(tester.takeException(), isNull);

      final noteField = find.widgetWithText(TextField, 'Note (Optional)');
      expect(noteField, findsOneWidget);
      expect(
        find.ancestor(
          of: noteField,
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
        reason: 'the note field must sit inside a scroll view so it can be '
            'scrolled out from behind the keyboard',
      );
    });

    testWidgets('offers a Diarrhea chip', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(const Scaffold(body: AddSymptomSheet()), family: [alice]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diarrhea'), findsOneWidget);
    });
  });
}
