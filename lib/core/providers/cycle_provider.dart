import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences instance.
/// Must be overridden in main.dart on startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider is not overridden');
});

/// Provider for the monthly cycle start day setting.
final cycleStartDayProvider =
    StateNotifierProvider<CycleStartDayNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CycleStartDayNotifier(prefs);
});

/// Notifier to persist and update the cycle start day.
class CycleStartDayNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;
  static const String _key = 'cycle_start_day';

  CycleStartDayNotifier(this._prefs) : super(_prefs.getInt(_key) ?? 1);

  /// Update the cycle start day (value must be between 1 and 28).
  Future<void> setCycleStartDay(int day) async {
    if (day < 1 || day > 28) return;
    await _prefs.setInt(_key, day);
    state = day;
  }
}
