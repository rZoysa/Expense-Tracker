import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/viewmodels/theme_view_model.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/category_spending_card.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/monthly_total_card.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/recent_expenses_list.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:expense_tracker/views/shared/widgets/empty_state.dart';
import 'package:expense_tracker/views/shared/widgets/error_state.dart';
import 'package:expense_tracker/views/shared/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({
    required this.onViewAllTransactions,
    super.key,
  });

  final VoidCallback onViewAllTransactions;

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
            return ErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.retry,
            );
          }

          final recentExpenses = viewModel.recentExpenses;
          final selectedMonthExpenses = viewModel.selectedMonthExpenses;

          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 104.h),
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
              CategorySpendingCard(
                summaries: viewModel.categorySummary,
                total: viewModel.monthlyTotal,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Text(
                    'Recent expenses',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onViewAllTransactions,
                    child: const Text('View all'),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              if (recentExpenses.isEmpty)
                SizedBox(
                  height: 220.h,
                  child: EmptyState(
                    title: viewModel.expenses.isEmpty
                        ? 'No expenses yet'
                        : 'No expenses this month',
                    message: viewModel.expenses.isEmpty
                        ? 'Add your first expense to get started.'
                        : 'Choose another month or add a new expense.',
                  ),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: RecentExpensesList(expenses: recentExpenses),
                ),
              if (selectedMonthExpenses.length > recentExpenses.length) ...[
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${selectedMonthExpenses.length - recentExpenses.length} more transaction${selectedMonthExpenses.length - recentExpenses.length == 1 ? '' : 's'} this month',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
