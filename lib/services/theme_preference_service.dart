import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferenceService {
  ThemePreferenceService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _darkModeKey = 'dark_mode';

  final SharedPreferencesAsync _preferences;

  Future<bool> loadDarkMode() async {
    return await _preferences.getBool(_darkModeKey) ?? false;
  }

  Future<void> saveDarkMode(bool isDarkMode) async {
    await _preferences.setBool(_darkModeKey, isDarkMode);
  }
}
