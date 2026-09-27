import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:expense_tracker/views/shared/widgets/empty_state.dart';
import 'package:expense_tracker/views/shared/widgets/error_state.dart';
import 'package:expense_tracker/views/shared/widgets/expense_list.dart';
import 'package:expense_tracker/views/shared/widgets/month_selector.dart';
import 'package:expense_tracker/views/transactions/widgets/category_filter.dart';
import 'package:expense_tracker/views/transactions/widgets/transaction_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  void _openAddExpense(BuildContext context) {
    final expenseRepository = context.read<ExpenseRepository>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) =>
              ExpenseFormViewModel(expenseRepository: expenseRepository),
          child: const ExpenseFormScreen(),
        ),
      ),
    );
  }

  Future<void> _openExpense(BuildContext context, Expense expense) async {
    final expenseRepository = context.read<ExpenseRepository>();

    final deletedExpense = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ExpenseFormViewModel(
            expenseRepository: expenseRepository,
            expense: expense,
          ),
          child: ExpenseFormScreen(expense: expense),
        ),
      ),
    );

    if (!context.mounted || deletedExpense == null) {
      return;
    }

    _showDeletedSnackBar(context, deletedExpense);
  }

  void _showDeletedSnackBar(BuildContext context, Expense deletedExpense) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
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
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  String _emptyStateTitle(ExpenseListViewModel viewModel) {
    if (viewModel.expenses.isEmpty) {
      return 'No expenses yet';
    }

    if (viewModel.hasSearchQuery) {
      return 'No search results';
    }

    if (viewModel.selectedMonthExpenses.isEmpty) {
      return 'No expenses this month';
    }

    return 'No matching expenses';
  }

  String _emptyStateMessage(ExpenseListViewModel viewModel) {
    if (viewModel.expenses.isEmpty) {
      return 'Add your first expense to get started.';
    }

    if (viewModel.hasSearchQuery) {
      return 'No transactions match "${viewModel.searchQuery.trim()}".';
    }

    if (viewModel.selectedMonthExpenses.isEmpty) {
      return 'There are no expenses for the selected month.';
    }

    return 'There are no expenses matching the selected category.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpense(context),
        icon: Icon(Icons.add, size: 24.r),
        label: const Text('Add Expense'),
      ),
      body: Consumer<ExpenseListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return ErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.retry,
            );
          }

          final filteredExpenses = viewModel.filteredExpenses;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Column(
                  children: [
                    TransactionSearchBar(
                      searchQuery: viewModel.searchQuery,
                      onChanged: viewModel.setSearchQuery,
                      onClear: viewModel.clearSearchQuery,
                    ),
                    SizedBox(height: 16.h),
                    MonthSelector(
                      selectedMonth: viewModel.selectedMonth,
                      isCurrentMonth: viewModel.isCurrentMonth,
                      onPrevious: viewModel.goToPreviousMonth,
                      onNext: viewModel.goToNextMonth,
                    ),
                    SizedBox(height: 12.h),
                    CategoryFilter(
                      selectedCategory: viewModel.selectedCategory,
                      onSelected: viewModel.setCategoryFilter,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Text(
                          'Expense history',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredExpenses.length}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: filteredExpenses.isEmpty
                    ? EmptyState(
                        title: _emptyStateTitle(viewModel),
                        message: _emptyStateMessage(viewModel),
                      )
                    : ExpenseList(
                        expenses: filteredExpenses,
                        onExpenseTap: (expense) {
                          _openExpense(context, expense);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
