import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_date_scope.dart';
import 'package:expense_tracker/models/expense_form_result.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:expense_tracker/views/shared/widgets/empty_state.dart';
import 'package:expense_tracker/views/shared/widgets/error_state.dart';
import 'package:expense_tracker/views/shared/widgets/expense_list.dart';
import 'package:expense_tracker/views/shared/widgets/expense_list_skeleton.dart';
import 'package:expense_tracker/views/shared/widgets/month_selector.dart';
import 'package:expense_tracker/views/transaction_details/transaction_details_screen.dart';
import 'package:expense_tracker/views/transactions/widgets/category_filter.dart';
import 'package:expense_tracker/views/transactions/widgets/date_scope_selector.dart';
import 'package:expense_tracker/views/transactions/widgets/selected_date_selector.dart';
import 'package:expense_tracker/views/transactions/widgets/transaction_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isFabExtended = true;

  Future<void> _openAddExpense(BuildContext context) async {
    final expenseRepository = context.read<ExpenseRepository>();

    await Navigator.of(context).push<ExpenseFormResult>(
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

  Future<void> _openExpenseDetails(
    BuildContext context,
    Expense expense,
  ) async {
    final expenseRepository = context.read<ExpenseRepository>();

    final result = await Navigator.of(context).push<ExpenseFormResult>(
      MaterialPageRoute(
        builder: (_) => Provider<ExpenseRepository>.value(
          value: expenseRepository,
          child: TransactionDetailsScreen(expense: expense),
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

    if (!context.mounted || result == null || !result.wasDeleted) {
      return;
    }

    _showDeletedSnackBar(context, result.expense);
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

  Future<void> _handleRefresh(ExpenseListViewModel viewModel) async {
    if (viewModel.dateScope == ExpenseDateScope.allTime) {
      await viewModel.refreshAllTime();
    } else {
      await viewModel.retry();
    }
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
              icon: Icon(
                viewModel.isLoadingMoreAllTime
                    ? Icons.more_horiz
                    : Icons.expand_more,
                size: 20.r,
              ),
              label: Text(
                viewModel.isLoadingMoreAllTime
                    ? 'Loading older transactions...'
                    : 'Search older transactions',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountIndicator(
    BuildContext context,
    ExpenseListViewModel viewModel,
    bool isAllTime,
    bool isLoading,
  ) {
    if (isLoading) {
      return Skeletonizer.zone(child: Bone.text(width: 48.w));
    }

    final count = viewModel.filteredExpenses.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        isAllTime ? '$count shown' : '$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateScopeExtra(
    BuildContext context,
    ExpenseListViewModel viewModel,
  ) {
    return switch (viewModel.dateScope) {
      ExpenseDateScope.month => Padding(
        key: const ValueKey('month'),
        padding: EdgeInsets.only(top: 12.h),
        child: MonthSelector(
          selectedMonth: viewModel.selectedMonth,
          isCurrentMonth: viewModel.isCurrentMonth,
          onPrevious: viewModel.goToPreviousMonth,
          onNext: viewModel.goToNextMonth,
        ),
      ),
      ExpenseDateScope.specificDate => Padding(
        key: const ValueKey('date'),
        padding: EdgeInsets.only(top: 12.h),
        child: SelectedDateSelector(
          selectedDate: viewModel.selectedDate,
          onTap: () => _selectDate(context, viewModel),
        ),
      ),
      ExpenseDateScope.allTime => const SizedBox.shrink(key: ValueKey('all')),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transactions_add_expense',
        isExtended: _isFabExtended,
        onPressed: () => _openAddExpense(context),
        icon: Icon(Icons.add, size: 24.r),
        label: const Text('Add Expense'),
      ),
      body: Consumer<ExpenseListViewModel>(
        builder: (context, viewModel, child) {
          final filteredExpenses = viewModel.filteredExpenses;
          final isAllTime = viewModel.dateScope == ExpenseDateScope.allTime;
          final isLoading = viewModel.isTransactionsLoading;

          return Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20.r),
                ),
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
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildDateScopeExtra(context, viewModel),
                      ),
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
                        _buildCountIndicator(
                          context,
                          viewModel,
                          isAllTime,
                          isLoading,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: isLoading
                    ? const ExpenseListSkeleton(itemCount: 7)
                    : viewModel.hasTransactionsError
                    ? ErrorState(
                        message: viewModel.transactionsErrorMessage!,
                        onRetry: viewModel.retry,
                      )
                    : filteredExpenses.isEmpty
                    ? _buildEmptyState(context, viewModel)
                    : NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          if (notification.direction ==
                                  ScrollDirection.reverse &&
                              _isFabExtended) {
                            setState(() => _isFabExtended = false);
                          } else if (notification.direction ==
                                  ScrollDirection.forward &&
                              !_isFabExtended) {
                            setState(() => _isFabExtended = true);
                          }
                          return false;
                        },
                        child: RefreshIndicator(
                          onRefresh: () => _handleRefresh(viewModel),
                          child: ExpenseList(
                            expenses: filteredExpenses,
                            onExpenseTap: (expense) {
                              _openExpenseDetails(context, expense);
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
