import 'package:flutter_test/flutter_test.dart';
import 'package:mama_brain/src/core/prefs/last_tab_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastTabStore', () {
    test('falls back when nothing has been stored', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await LastTabStore.load(tabCount: 3), 0);
      expect(await LastTabStore.load(tabCount: 3, fallback: 2), 2);
    });

    test('round-trips the saved tab index', () async {
      SharedPreferences.setMockInitialValues({});

      await LastTabStore.save(2);

      expect(await LastTabStore.load(tabCount: 3), 2);
    });

    test('reads an index stored by a previous launch', () async {
      SharedPreferences.setMockInitialValues({LastTabStore.key: 1});

      expect(await LastTabStore.load(tabCount: 3), 1);
    });

    test('ignores an out-of-range index instead of crashing the tab list',
        () async {
      // e.g. saved by an older build that had more tabs.
      SharedPreferences.setMockInitialValues({LastTabStore.key: 7});

      expect(await LastTabStore.load(tabCount: 3), 0);
    });

    test('ignores a negative index', () async {
      SharedPreferences.setMockInitialValues({LastTabStore.key: -1});

      expect(await LastTabStore.load(tabCount: 3), 0);
    });

    test('the last save wins', () async {
      SharedPreferences.setMockInitialValues({});

      await LastTabStore.save(1);
      await LastTabStore.save(2);
      await LastTabStore.save(0);

      expect(await LastTabStore.load(tabCount: 3), 0);
    });
  });
}
