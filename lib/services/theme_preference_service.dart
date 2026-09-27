import 'package:expense_tracker/models/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferenceService {
  ThemePreferenceService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _themeModeKey = 'theme_mode';
  static const String _legacyDarkModeKey = 'dark_mode';

  final SharedPreferencesAsync _preferences;

  Future<AppThemeMode> loadThemeMode() async {
    final savedThemeMode = await _preferences.getString(_themeModeKey);

    if (savedThemeMode != null) {
      for (final themeMode in AppThemeMode.values) {
        if (themeMode.name == savedThemeMode) {
          return themeMode;
        }
      }
    }

    final legacyDarkMode = await _preferences.getBool(_legacyDarkModeKey);

    if (legacyDarkMode != null) {
      final migratedThemeMode = legacyDarkMode
          ? AppThemeMode.dark
          : AppThemeMode.light;

      await saveThemeMode(migratedThemeMode);
      await _preferences.remove(_legacyDarkModeKey);

      return migratedThemeMode;
    }

    return AppThemeMode.system;
  }

  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    await _preferences.setString(_themeModeKey, themeMode.name);
  }
}
