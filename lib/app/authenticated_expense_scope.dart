import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/repositories/firebase_expense_repository.dart';
import 'package:expense_tracker/viewmodels/auth_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/views/main/main_screen.dart';
import 'package:expense_tracker/views/shared/widgets/app_loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthenticatedExpenseScope extends StatelessWidget {
  const AuthenticatedExpenseScope({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    if (user == null) {
      return const AppLoadingSkeleton();
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
