import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/core/models/medication.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';
import 'package:mama_brain/src/features/medications/logic/medication_provider.dart';
import 'package:mama_brain/src/features/medications/ui/daily_medication_list.dart';

import '../../../helpers/fake_notifiers.dart';

void main() {
  final alice = FamilyMember(id: 'fm-1', name: 'Alice', colorValue: 0xFFFF0000);
  final bob = FamilyMember(id: 'fm-2', name: 'Bob', colorValue: 0xFF0000FF);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, today.day, hour, minute);

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Widget wrap({
    required List<FamilyMember> family,
    required List<Medication> medications,
  }) {
    return ProviderScope(
      overrides: [
        familyProvider.overrideWith((_) => FakeFamilyNotifier(family)),
        medicationProvider
            .overrideWith((_) => FakeMedicationNotifier(medications)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DailyMedicationList()),
      ),
    );
  }

  Medication med(
    String id,
    String name,
    String memberId, {
    List<DateTime> takenLogs = const [],
  }) {
    return Medication(
      id: id,
      name: name,
      familyMemberId: memberId,
      type: MedicationType.oneOff,
      startDate: today,
      takenLogs: takenLogs,
    );
  }

  group('DailyMedicationList', () {
    testWidgets('shows an empty message when nothing is scheduled',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(family: [alice], medications: []));
      await tester.pumpAndSettle();

      expect(find.text('No medications for the selected date.'), findsOneWidget);
    });

    testWidgets('collapses repeat doses of one medicine into a single block',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        family: [alice],
        medications: [
          med('m1', 'Paracetamol', 'fm-1', takenLogs: [at(8)]),
          med('m2', 'Paracetamol', 'fm-1', takenLogs: [at(14)]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // One heading for the medicine, one row per dose.
      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('Taken at 08:00'), findsOneWidget);
      expect(find.text('Taken at 14:00'), findsOneWidget);
      // Each dose keeps its own delete control.
      expect(find.byTooltip('Delete this entry'), findsNWidgets(2));
      // A single block-wide edit for the medicine itself.
      expect(find.byTooltip('Edit medication'), findsOneWidget);
    });

    testWidgets('doses are listed in chronological order', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        family: [alice],
        medications: [
          med('m1', 'Paracetamol', 'fm-1', takenLogs: [at(20)]),
          med('m2', 'Paracetamol', 'fm-1', takenLogs: [at(6)]),
          med('m3', 'Paracetamol', 'fm-1', takenLogs: [at(13)]),
        ],
      ));
      await tester.pumpAndSettle();

      final times = tester
          .widgetList<Text>(find.textContaining('Taken at'))
          .map((t) => t.data)
          .toList();
      expect(times, ['Taken at 06:00', 'Taken at 13:00', 'Taken at 20:00']);
    });

    testWidgets('keeps the same medicine separate for different people',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        family: [alice, bob],
        medications: [
          med('m1', 'Paracetamol', 'fm-1', takenLogs: [at(8)]),
          med('m2', 'Paracetamol', 'fm-2', takenLogs: [at(9)]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Paracetamol'), findsNWidgets(2));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('an untaken medicine shows its type and sinks below taken ones',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        family: [alice],
        medications: [
          med('m1', 'Ibuprofen', 'fm-1'),
          med('m2', 'Paracetamol', 'fm-1', takenLogs: [at(8)]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('One-off'), findsOneWidget);

      // The taken medicine's block is rendered above the untaken one.
      final takenY = tester.getTopLeft(find.text('Paracetamol')).dy;
      final untakenY = tester.getTopLeft(find.text('Ibuprofen')).dy;
      expect(takenY, lessThan(untakenY));
    });

    testWidgets('a long medicine name does not overflow the block',
        (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(wrap(
        family: [alice],
        medications: [
          med('m1', 'Amoxicillin clavulanate extended release suspension',
              'fm-1',
              takenLogs: [at(8)]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
