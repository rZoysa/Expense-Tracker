import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/repositories/firebase_expense_repository.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/views/expense_dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = AuthService();
  final user = await authService.signInAnonymouslyIfNeeded();

  final expenseRepository = FirebaseExpenseRepository(userId: user.uid);

  runApp(ExpenseTrackerApp(expenseRepository: expenseRepository));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({required this.expenseRepository, super.key});

  final ExpenseRepository expenseRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ExpenseRepository>.value(value: expenseRepository),
        ChangeNotifierProvider(
          create: (context) => ExpenseListViewModel(
            expenseRepository: context.read<ExpenseRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const ExpenseDashboardScreen(),
      ),
    );
  }
}
