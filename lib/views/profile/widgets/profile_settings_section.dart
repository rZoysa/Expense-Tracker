import 'package:expense_tracker/models/app_theme_mode.dart';
import 'package:expense_tracker/viewmodels/theme_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  String _themeModeLabel(AppThemeMode themeMode) {
    return switch (themeMode) {
      AppThemeMode.system => 'System default',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }

  IconData _themeModeIcon(AppThemeMode themeMode) {
    return switch (themeMode) {
      AppThemeMode.system => Icons.brightness_auto_outlined,
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode_outlined,
    };
  }

  Future<void> _showThemeModePicker(BuildContext context) async {
    final themeViewModel = context.read<ThemeViewModel>();
    final selectedThemeMode = themeViewModel.selectedThemeMode;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 8.h,
                  ),
                  child: Text(
                    'Choose theme',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ...AppThemeMode.values.map(
                  (themeMode) => ListTile(
                    leading: Icon(_themeModeIcon(themeMode), size: 24.r),
                    title: Text(_themeModeLabel(themeMode)),
                    trailing: selectedThemeMode == themeMode
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await themeViewModel.setThemeMode(themeMode);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  _themeModeIcon(themeViewModel.selectedThemeMode),
                  size: 24.r,
                ),
                title: const Text('Theme'),
                subtitle: Text(
                  _themeModeLabel(themeViewModel.selectedThemeMode),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeModePicker(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.payments_outlined, size: 24.r),
                title: const Text('Currency'),
                subtitle: const Text('LKR — Sri Lankan Rupee'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
