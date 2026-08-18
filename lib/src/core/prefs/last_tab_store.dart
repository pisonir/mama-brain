import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which bottom-navigation tab the user was last on, so reopening the
/// app returns them to where they left off instead of always the first tab.
///
/// Persisting is best-effort: if preferences are unavailable (for example in a
/// unit test with no platform channels) we silently fall back rather than
/// breaking navigation.
class LastTabStore {
  static const String key = 'last_tab_index';

  const LastTabStore._();

  /// Reads the stored tab index, or [fallback] when nothing valid is stored.
  /// An out-of-range value (e.g. saved by an older build with more tabs) is
  /// ignored so we can never index past the end of the tab list.
  static Future<int> load({required int tabCount, int fallback = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(key);
      if (stored == null || stored < 0 || stored >= tabCount) return fallback;
      return stored;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> save(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, index);
    } catch (_) {
      // Best-effort only.
    }
  }
}
