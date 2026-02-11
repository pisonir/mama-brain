import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mama_brain/src/core/models/family_member.dart';
import 'package:mama_brain/src/features/family/logic/family_provider.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await setUpHive();
    await openFamilyBox();
  });

  tearDown(() async {
    await tearDownHive(tempDir);
  });

  group('FamilyNotifier', () {
    group('loadMembers', () {
      test('empty box produces empty state', () {
        final notifier = FamilyNotifier();
        expect(notifier.debugState, isEmpty);
      });

      test('pre-populated box loads into state', () async {
        final box = Hive.box<FamilyMember>('family_members');
        final member = FamilyMember(
          id: 'pre-1',
          name: 'Alice',
          colorValue: 0xFFFF0000,
        );
        await box.put(member.id, member);

        final notifier = FamilyNotifier();
        expect(notifier.debugState.length, 1);
        expect(notifier.debugState.first.name, 'Alice');
      });
    });

    group('addMember', () {
      test('appends member to state', () async {
        final notifier = FamilyNotifier();
        await notifier.addMember(name: 'Bob', colorValue: 0xFF00FF00);

        expect(notifier.debugState.length, 1);
        expect(notifier.debugState.first.name, 'Bob');
        expect(notifier.debugState.first.colorValue, 0xFF00FF00);
      });

      test('generates a UUID for the new member', () async {
        final notifier = FamilyNotifier();
        await notifier.addMember(name: 'Carol', colorValue: 0xFF0000FF);

        final id = notifier.debugState.first.id;
        expect(id, isNotEmpty);
        // UUID v4 has 36 characters with hyphens
        expect(id.length, 36);
      });

      test('persists to Hive', () async {
        final notifier = FamilyNotifier();
        await notifier.addMember(name: 'Dave', colorValue: 0xFF123456);

        final box = Hive.box<FamilyMember>('family_members');
        expect(box.length, 1);
        expect(box.values.first.name, 'Dave');
      });
    });

    group('deleteMember', () {
      test('removes member from state and Hive', () async {
        final notifier = FamilyNotifier();
        await notifier.addMember(name: 'Eve', colorValue: 0xFFABCDEF);
        final id = notifier.debugState.first.id;

        await notifier.deleteMember(id);

        expect(notifier.debugState, isEmpty);
        final box = Hive.box<FamilyMember>('family_members');
        expect(box.length, 0);
      });

      test('no-ops on missing ID', () async {
        final notifier = FamilyNotifier();
        await notifier.addMember(name: 'Frank', colorValue: 0xFF000000);

        await notifier.deleteMember('nonexistent-id');
        expect(notifier.debugState.length, 1);
      });
    });
  });
}
