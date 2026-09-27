import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/expense_list_view_model.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({super.key});

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
