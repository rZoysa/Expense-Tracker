import 'package:expense_tracker/models/app_theme_mode.dart';
import 'package:expense_tracker/services/theme_preference_service.dart';
import 'package:flutter/material.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel({
    required this._themePreferenceService,
    required AppThemeMode initialThemeMode,
  }) : _selectedThemeMode = initialThemeMode;

  final ThemePreferenceStore _themePreferenceService;

  AppThemeMode _selectedThemeMode;

  AppThemeMode get selectedThemeMode => _selectedThemeMode;

  ThemeMode get themeMode {
    return switch (_selectedThemeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    if (_selectedThemeMode == themeMode) {
      return;
    }

    _selectedThemeMode = themeMode;
    notifyListeners();

    await _themePreferenceService.saveThemeMode(themeMode);
  }
}
