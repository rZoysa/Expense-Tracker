import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/expense_list_view_model.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({super.key});

  void _showDeletedSnackBar(BuildContext context, Expense deletedExpense) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        duration: const Duration(seconds: 5),
        behavior: .floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final wasRestored = await context
                .read<ExpenseListViewModel>()
                .restoreExpense(deletedExpense);

            if (!context.mounted || wasRestored) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to restore expense.'),
                behavior: .floating,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final expenseRepository = context.read<ExpenseRepository>();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                return ChangeNotifierProvider(
                  create: (_) => ExpenseFormViewModel(
                    expenseRepository: expenseRepository,
                  ),
                  child: const ExpenseFormScreen(),
                );
              },
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: Consumer<ExpenseListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return _ErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.retry,
            );
          }

          if (viewModel.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            itemCount: viewModel.expenses.length,
            itemBuilder: (context, index) {
              final expense = viewModel.expenses[index];

              return ListTile(
                title: Text(expense.title),
                subtitle: Text(expense.category.name),
                trailing: Text(expense.amount.toStringAsFixed(2)),
                onTap: () async {
                  final expenseRepository = context.read<ExpenseRepository>();

                  final deletedExpense = await Navigator.of(context)
                      .push<Expense>(
                        MaterialPageRoute(
                          builder: (_) {
                            return ChangeNotifierProvider(
                              create: (_) => ExpenseFormViewModel(
                                expenseRepository: expenseRepository,
                                expense: expense,
                              ),
                              child: ExpenseFormScreen(expense: expense),
                            );
                          },
                        ),
                      );

                  if (!context.mounted || deletedExpense == null) {
                    return;
                  }

                  _showDeletedSnackBar(context, deletedExpense);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56),
          SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('Your expenses will appear here.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
