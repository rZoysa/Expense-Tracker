import 'dart:async';

import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/repositories/firebase_expense_repository.dart';
import 'package:expense_tracker/viewmodels/auth_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/views/main/main_screen.dart';
import 'package:expense_tracker/views/shared/widgets/app_loading_skeleton.dart';
import 'package:expense_tracker/views/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthenticatedExpenseScope extends StatelessWidget {
  const AuthenticatedExpenseScope({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.user;

    if (user == null) {
      if (authViewModel.isInitializingSession ||
          authViewModel.errorMessage == null) {
        return const AppLoadingSkeleton();
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Expense Tracker')),
        body: SafeArea(
          child: ErrorState(
            message: authViewModel.errorMessage!,
            onRetry: () {
              unawaited(authViewModel.ensureUserSession());
            },
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey(user.uid),
      child: MultiProvider(
        providers: [
          Provider<ExpenseRepository>(
            create: (_) => FirebaseExpenseRepository(userId: user.uid),
          ),
          ChangeNotifierProvider(
            create: (context) => ExpenseListViewModel(
              expenseRepository: context.read<ExpenseRepository>(),
            ),
          ),
        ],
        child: const MainScreen(),
      ),
    );
  }
}
