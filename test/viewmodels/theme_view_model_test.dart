import 'package:expense_tracker/models/app_theme_mode.dart';
import 'package:expense_tracker/services/theme_preference_service.dart';
import 'package:expense_tracker/viewmodels/theme_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeViewModel', () {
    test('maps system preference to ThemeMode.system', () {
      final preferenceService = _FakeThemePreferenceService();
      final viewModel = ThemeViewModel(
        themePreferenceService: preferenceService,
        initialThemeMode: AppThemeMode.system,
      );

      expect(viewModel.selectedThemeMode, AppThemeMode.system);
      expect(viewModel.themeMode, ThemeMode.system);
    });

    test('updates and persists selected theme mode', () async {
      final preferenceService = _FakeThemePreferenceService();
      final viewModel = ThemeViewModel(
        themePreferenceService: preferenceService,
        initialThemeMode: AppThemeMode.system,
      );

      await viewModel.setThemeMode(AppThemeMode.dark);

      expect(viewModel.selectedThemeMode, AppThemeMode.dark);
      expect(viewModel.themeMode, ThemeMode.dark);
      expect(preferenceService.savedThemeMode, AppThemeMode.dark);
      expect(preferenceService.saveCallCount, 1);
    });

    test('does not persist when selected mode has not changed', () async {
      final preferenceService = _FakeThemePreferenceService();
      final viewModel = ThemeViewModel(
        themePreferenceService: preferenceService,
        initialThemeMode: AppThemeMode.light,
      );

      await viewModel.setThemeMode(AppThemeMode.light);

      expect(viewModel.themeMode, ThemeMode.light);
      expect(preferenceService.savedThemeMode, isNull);
      expect(preferenceService.saveCallCount, 0);
    });
  });
}

class _FakeThemePreferenceService extends ThemePreferenceService {
  AppThemeMode? savedThemeMode;
  int saveCallCount = 0;

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    savedThemeMode = themeMode;
    saveCallCount++;
  }
}
