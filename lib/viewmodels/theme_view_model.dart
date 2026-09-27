import 'package:expense_tracker/services/theme_preference_service.dart';
import 'package:flutter/material.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel({
    required this._themePreferenceService,
    required bool initialDarkMode,
  }) : _isDarkMode = initialDarkMode;

  final ThemePreferenceService _themePreferenceService;

  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    await _themePreferenceService.saveDarkMode(_isDarkMode);
  }
}
