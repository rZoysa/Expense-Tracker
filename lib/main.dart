import 'package:expense_tracker/app/app_theme.dart';
import 'package:expense_tracker/app/authenticated_expense_scope.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/theme_preference_service.dart';
import 'package:expense_tracker/viewmodels/auth_view_model.dart';
import 'package:expense_tracker/viewmodels/theme_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = AuthService();
  await authService.signInAnonymouslyIfNeeded();

  final themePreferenceService = ThemePreferenceService();
  final initialDarkMode = await themePreferenceService.loadDarkMode();

  runApp(
    ExpenseTrackerApp(
      authService: authService,
      themePreferenceService: themePreferenceService,
      initialDarkMode: initialDarkMode,
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({
    required this.authService,
    required this.themePreferenceService,
    required this.initialDarkMode,
    super.key,
  });

  final AuthService authService;
  final ThemePreferenceService themePreferenceService;
  final bool initialDarkMode;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthViewModel(authService: authService),
            ),
            ChangeNotifierProvider(
              create: (_) => ThemeViewModel(
                themePreferenceService: themePreferenceService,
                initialDarkMode: initialDarkMode,
              ),
            ),
          ],
          child: Consumer<ThemeViewModel>(
            builder: (context, themeViewModel, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Expense Tracker',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeViewModel.themeMode,
                home: const AuthenticatedExpenseScope(),
              );
            },
          ),
        );
      },
    );
  }
}
