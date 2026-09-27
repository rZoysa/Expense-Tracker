import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/viewmodels/theme_view_model.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/category_filter.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/dashboard_empty_state.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/dashboard_error_state.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/expense_list.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/month_selector.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/monthly_total_card.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<ThemeViewModel>().toggleTheme();
            },
            tooltip: 'Toggle theme',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 24.r,
            ),
          ),
        ],
      ),
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
            return DashboardErrorState(
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
                    MonthSelector(
                      selectedMonth: viewModel.selectedMonth,
                      isCurrentMonth: viewModel.isCurrentMonth,
                      onPrevious: viewModel.goToPreviousMonth,
                      onNext: viewModel.goToNextMonth,
                    ),
                    SizedBox(height: 8.h),
                    MonthlyTotalCard(total: viewModel.monthlyTotal),
                    SizedBox(height: 16.h),
                    CategoryFilter(
                      selectedCategory: viewModel.selectedCategory,
                      onSelected: viewModel.setCategoryFilter,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Text(
                          'Expenses',
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
                    ? DashboardEmptyState(
                        title: viewModel.expenses.isEmpty
                            ? 'No expenses yet'
                            : 'No matching expenses',
                        message: viewModel.expenses.isEmpty
                            ? 'Add your first expense to get started.'
                            : 'There are no expenses matching the selected month and category.',
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
