import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_date_scope.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:expense_tracker/views/shared/widgets/empty_state.dart';
import 'package:expense_tracker/views/shared/widgets/error_state.dart';
import 'package:expense_tracker/views/shared/widgets/expense_list.dart';
import 'package:expense_tracker/views/shared/widgets/month_selector.dart';
import 'package:expense_tracker/views/transactions/widgets/category_filter.dart';
import 'package:expense_tracker/views/transactions/widgets/date_scope_selector.dart';
import 'package:expense_tracker/views/transactions/widgets/selected_date_selector.dart';
import 'package:expense_tracker/views/transactions/widgets/transaction_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  Future<void> _openAddExpense(BuildContext context) async {
    final expenseRepository = context.read<ExpenseRepository>();

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) =>
              ExpenseFormViewModel(expenseRepository: expenseRepository),
          child: const ExpenseFormScreen(),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    final viewModel = context.read<ExpenseListViewModel>();
    if (viewModel.dateScope == ExpenseDateScope.allTime) {
      await viewModel.refreshAllTime();
    }
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

    if (!context.mounted) {
      return;
    }

    final viewModel = context.read<ExpenseListViewModel>();
    if (viewModel.dateScope == ExpenseDateScope.allTime) {
      await viewModel.refreshAllTime();
    }

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

  Future<void> _selectDate(
    BuildContext context,
    ExpenseListViewModel viewModel,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select expense date',
    );

    if (selectedDate == null || !context.mounted) {
      return;
    }

    context.read<ExpenseListViewModel>().setSelectedDate(selectedDate);
  }

  String _emptyStateTitle(ExpenseListViewModel viewModel) {
    if (viewModel.hasSearchQuery) {
      return viewModel.dateScope == ExpenseDateScope.allTime &&
              viewModel.hasMoreAllTime
          ? 'No matches in loaded transactions'
          : 'No search results';
    }

    if (viewModel.selectedCategory != null) {
      return 'No ${viewModel.selectedCategory!.label} expenses';
    }

    return switch (viewModel.dateScope) {
      ExpenseDateScope.month => 'No expenses this month',
      ExpenseDateScope.specificDate => 'No expenses on this date',
      ExpenseDateScope.allTime => 'No expenses yet',
    };
  }

  String _emptyStateMessage(
    BuildContext context,
    ExpenseListViewModel viewModel,
  ) {
    if (viewModel.hasSearchQuery) {
      if (viewModel.dateScope == ExpenseDateScope.allTime &&
          viewModel.hasMoreAllTime) {
        return 'No loaded transactions match "${viewModel.searchQuery.trim()}". Load more to search older transactions.';
      }

      return 'No transactions match "${viewModel.searchQuery.trim()}".';
    }

    if (viewModel.selectedCategory != null) {
      final categoryLabel = viewModel.selectedCategory!.label;
      return switch (viewModel.dateScope) {
        ExpenseDateScope.month =>
          'There are no $categoryLabel expenses for the selected month.',
        ExpenseDateScope.specificDate =>
          'There are no $categoryLabel expenses on the selected date.',
        ExpenseDateScope.allTime =>
          'There are no $categoryLabel expenses in your history.',
      };
    }

    return switch (viewModel.dateScope) {
      ExpenseDateScope.month => 'There are no expenses for the selected month.',
      ExpenseDateScope.specificDate =>
        'There are no expenses on ${MaterialLocalizations.of(context).formatMediumDate(viewModel.selectedDate)}.',
      ExpenseDateScope.allTime => 'Add your first expense to get started.',
    };
  }

  Widget _buildEmptyState(
    BuildContext context,
    ExpenseListViewModel viewModel,
  ) {
    final canSearchOlderTransactions =
        viewModel.dateScope == ExpenseDateScope.allTime &&
        viewModel.hasSearchQuery &&
        viewModel.hasMoreAllTime;

    if (!canSearchOlderTransactions) {
      return EmptyState(
        title: _emptyStateTitle(viewModel),
        message: _emptyStateMessage(context, viewModel),
      );
    }

    return Column(
      children: [
        Expanded(
          child: EmptyState(
            title: _emptyStateTitle(viewModel),
            message: _emptyStateMessage(context, viewModel),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: viewModel.isLoadingMoreAllTime
                  ? null
                  : viewModel.loadMoreAllTime,
              icon: viewModel.isLoadingMoreAllTime
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.expand_more, size: 20.r),
              label: const Text('Search older transactions'),
            ),
          ),
        ),
      ],
    );
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
          if (viewModel.isTransactionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasTransactionsError) {
            return ErrorState(
              message: viewModel.transactionsErrorMessage!,
              onRetry: viewModel.retry,
            );
          }

          final filteredExpenses = viewModel.filteredExpenses;
          final isAllTime = viewModel.dateScope == ExpenseDateScope.allTime;

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
                    DateScopeSelector(
                      selectedScope: viewModel.dateScope,
                      onSelected: viewModel.setDateScope,
                    ),
                    SizedBox(height: 12.h),
                    if (viewModel.dateScope == ExpenseDateScope.month) ...[
                      MonthSelector(
                        selectedMonth: viewModel.selectedMonth,
                        isCurrentMonth: viewModel.isCurrentMonth,
                        onPrevious: viewModel.goToPreviousMonth,
                        onNext: viewModel.goToNextMonth,
                      ),
                      SizedBox(height: 12.h),
                    ] else if (viewModel.dateScope ==
                        ExpenseDateScope.specificDate) ...[
                      SelectedDateSelector(
                        selectedDate: viewModel.selectedDate,
                        onTap: () => _selectDate(context, viewModel),
                      ),
                      SizedBox(height: 12.h),
                    ],
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
                          isAllTime
                              ? '${filteredExpenses.length} shown'
                              : '${filteredExpenses.length}',
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
                    ? _buildEmptyState(context, viewModel)
                    : ExpenseList(
                        expenses: filteredExpenses,
                        onExpenseTap: (expense) {
                          _openExpense(context, expense);
                        },
                        hasMore: isAllTime && viewModel.hasMoreAllTime,
                        isLoadingMore:
                            isAllTime && viewModel.isLoadingMoreAllTime,
                        loadMoreErrorMessage: isAllTime
                            ? viewModel.allTimeLoadMoreErrorMessage
                            : null,
                        onLoadMore: isAllTime
                            ? viewModel.loadMoreAllTime
                            : null,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
