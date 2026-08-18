import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/medications/ui/add_medication_sheet.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  final alice = FamilyMember(id: 'fm-1', name: 'Alice', colorValue: 0xFFFF0000);

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        familyProvider.overrideWith((_) => FakeFamilyNotifier([alice])),
        medicationProvider.overrideWith((_) => FakeMedicationNotifier([])),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('AddMedicationSheet', () {
    testWidgets('lays out on a narrow phone without overflowing',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(const Scaffold(body: AddMedicationSheet())));
      await tester.pumpAndSettle();

      // The date/time rows used to push their buttons off the right edge.
      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Pick'), findsNWidgets(2));
    });

    testWidgets('keeps its content scrollable while the keyboard is open',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        const MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
          child: Scaffold(body: AddMedicationSheet()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final warningField =
          find.widgetWithText(TextField, 'Warning (optional)');
      expect(warningField, findsOneWidget);
      expect(
        find.ancestor(
          of: warningField,
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
        reason: 'fields must sit inside a scroll view so they can be scrolled '
            'out from behind the keyboard',
      );
    });
  });
}
