import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsRepository {
  static const String _keyPerformanceMode = 'performance_mode';
  static const String _keyThemeMode = 'theme_mode';

  Future<bool> getPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPerformanceMode) ?? false;
  }

  Future<void> setPerformanceMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPerformanceMode, enabled);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }
}
