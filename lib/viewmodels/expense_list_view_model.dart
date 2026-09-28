import 'dart:async';

import 'package:expense_tracker/models/category_expense_summary.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_date_scope.dart';
import 'package:expense_tracker/models/expense_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseListViewModel extends ChangeNotifier {
  ExpenseListViewModel({required this._expenseRepository}) {
    _watchSelectedMonthExpenses();
  }

  static const int allTimePageSize = 20;

  final ExpenseRepository _expenseRepository;

  StreamSubscription<List<Expense>>? _monthExpenseSubscription;
  StreamSubscription<List<Expense>>? _dateExpenseSubscription;

  List<Expense> _monthExpenses = [];
  List<Expense> _specificDateExpenses = [];
  final List<Expense> _allTimeExpenses = [];

  bool _isMonthLoading = true;
  bool _isDateLoading = false;
  bool _isAllTimeLoading = false;

  String? _monthErrorMessage;
  String? _dateErrorMessage;
  String? _allTimeErrorMessage;

  ExpensePageCursor? _allTimeCursor;
  bool _hasMoreAllTime = true;
  int _allTimeQueryGeneration = 0;

  ExpenseCategory? _selectedCategory;
  ExpenseDateScope _dateScope = ExpenseDateScope.month;
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  ExpenseCategory? get selectedCategory => _selectedCategory;

  ExpenseDateScope get dateScope => _dateScope;

  String get searchQuery => _searchQuery;

  bool get hasSearchQuery => _searchQuery.trim().isNotEmpty;

  DateTime get selectedMonth => _selectedMonth;

  DateTime get selectedDate => _selectedDate;

  /// Expenses loaded by the month-scoped realtime query.
  List<Expense> get expenses => List.unmodifiable(_monthExpenses);

  bool get isLoading => _isMonthLoading;

  String? get errorMessage => _monthErrorMessage;

  bool get hasError => _monthErrorMessage != null;

  bool get isEmpty =>
      !_isMonthLoading && !hasError && selectedMonthExpenses.isEmpty;

  bool get isTransactionsLoading {
    return switch (_dateScope) {
      ExpenseDateScope.month => _isMonthLoading,
      ExpenseDateScope.specificDate => _isDateLoading,
      ExpenseDateScope.allTime => _isAllTimeLoading && _allTimeExpenses.isEmpty,
    };
  }

  String? get transactionsErrorMessage {
    return switch (_dateScope) {
      ExpenseDateScope.month => _monthErrorMessage,
      ExpenseDateScope.specificDate => _dateErrorMessage,
      ExpenseDateScope.allTime =>
        _allTimeExpenses.isEmpty ? _allTimeErrorMessage : null,
    };
  }

  bool get hasTransactionsError => transactionsErrorMessage != null;

  String? get allTimeLoadMoreErrorMessage =>
      _allTimeExpenses.isNotEmpty ? _allTimeErrorMessage : null;

  bool get isLoadingMoreAllTime =>
      _dateScope == ExpenseDateScope.allTime &&
      _isAllTimeLoading &&
      _allTimeExpenses.isNotEmpty;

  bool get hasMoreAllTime => _hasMoreAllTime;

  int get loadedAllTimeCount => _allTimeExpenses.length;

  bool get isCurrentMonth {
    final now = DateTime.now();

    return DateUtils.isSameMonth(_selectedMonth, now);
  }

  List<Expense> get selectedMonthExpenses {
    return _monthExpenses
        .where((expense) => DateUtils.isSameMonth(expense.date, _selectedMonth))
        .toList();
  }

  List<Expense> get recentExpenses {
    return selectedMonthExpenses.take(3).toList();
  }

  List<Expense> get dateScopedExpenses {
    return switch (_dateScope) {
      ExpenseDateScope.month => selectedMonthExpenses,
      ExpenseDateScope.specificDate =>
        _specificDateExpenses
            .where(
              (expense) => DateUtils.isSameDay(expense.date, _selectedDate),
            )
            .toList(),
      ExpenseDateScope.allTime => List.of(_allTimeExpenses),
    };
  }

  List<Expense> get filteredExpenses {
    final normalizedSearchQuery = _searchQuery.trim().toLowerCase();

    return dateScopedExpenses.where((expense) {
      final matchesCategory =
          _selectedCategory == null || expense.category == _selectedCategory;

      final matchesSearch =
          normalizedSearchQuery.isEmpty ||
          expense.title.toLowerCase().contains(normalizedSearchQuery) ||
          (expense.note?.toLowerCase().contains(normalizedSearchQuery) ??
              false) ||
          expense.category.name.toLowerCase().contains(normalizedSearchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  double get monthlyTotal {
    return selectedMonthExpenses.fold(
      0.0,
      (total, expense) => total + expense.amount,
    );
  }

  List<CategoryExpenseSummary> get categorySummary {
    final totalsByCategory = <ExpenseCategory, double>{};

    for (final expense in selectedMonthExpenses) {
      totalsByCategory.update(
        expense.category,
        (currentTotal) => currentTotal + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final summaries =
        totalsByCategory.entries
            .map(
              (entry) => CategoryExpenseSummary(
                category: entry.key,
                total: entry.value,
              ),
            )
            .toList()
          ..sort((first, second) => second.total.compareTo(first.total));

    return List.unmodifiable(summaries);
  }

  void _watchSelectedMonthExpenses() {
    _monthExpenseSubscription?.cancel();

    _isMonthLoading = true;
    _monthErrorMessage = null;
    notifyListeners();

    _monthExpenseSubscription = _expenseRepository
        .watchExpensesForMonth(_selectedMonth)
        .listen(
          (expenses) {
            _monthExpenses = expenses;
            _isMonthLoading = false;
            _monthErrorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            _isMonthLoading = false;
            _monthErrorMessage = 'Unable to load expenses.';

            _logExpenseError(
              'Failed to load monthly expenses',
              error,
              stackTrace,
            );
            notifyListeners();
          },
        );
  }

  void _watchSelectedDateExpenses() {
    _dateExpenseSubscription?.cancel();

    _specificDateExpenses = [];
    _isDateLoading = true;
    _dateErrorMessage = null;
    notifyListeners();

    _dateExpenseSubscription = _expenseRepository
        .watchExpensesForDate(_selectedDate)
        .listen(
          (expenses) {
            _specificDateExpenses = expenses;
            _isDateLoading = false;
            _dateErrorMessage = null;
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            _isDateLoading = false;
            _dateErrorMessage = 'Unable to load expenses for this date.';

            _logExpenseError(
              'Failed to load expenses for selected date',
              error,
              stackTrace,
            );
            notifyListeners();
          },
        );
  }

  Future<void> _resetAndLoadAllTime() async {
    _allTimeQueryGeneration++;
    _allTimeExpenses.clear();
    _allTimeCursor = null;
    _hasMoreAllTime = true;
    _isAllTimeLoading = false;
    _allTimeErrorMessage = null;
    notifyListeners();

    await loadMoreAllTime();
  }

  Future<void> loadMoreAllTime() async {
    if (_dateScope != ExpenseDateScope.allTime ||
        _isAllTimeLoading ||
        !_hasMoreAllTime) {
      return;
    }

    final requestGeneration = _allTimeQueryGeneration;

    _isAllTimeLoading = true;
    _allTimeErrorMessage = null;
    notifyListeners();

    try {
      final page = await _expenseRepository.fetchExpensePage(
        cursor: _allTimeCursor,
        category: _selectedCategory,
        pageSize: allTimePageSize,
      );

      if (requestGeneration != _allTimeQueryGeneration) {
        return;
      }

      final existingIds = _allTimeExpenses
          .map((expense) => expense.id)
          .whereType<String>()
          .toSet();

      _allTimeExpenses.addAll(
        page.expenses.where(
          (expense) => expense.id == null || !existingIds.contains(expense.id),
        ),
      );

      _allTimeCursor = page.nextCursor;
      _hasMoreAllTime = page.hasMore;
    } catch (error, stackTrace) {
      if (requestGeneration != _allTimeQueryGeneration) {
        return;
      }

      _allTimeErrorMessage = 'Unable to load older expenses.';

      _logExpenseError('Failed to load paginated expenses', error, stackTrace);
    } finally {
      if (requestGeneration == _allTimeQueryGeneration) {
        _isAllTimeLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshAllTime() async {
    if (_dateScope != ExpenseDateScope.allTime) {
      return;
    }

    await _resetAndLoadAllTime();
  }

  Future<bool> restoreExpense(Expense expense) async {
    try {
      await _expenseRepository.restoreExpense(expense);

      if (_dateScope == ExpenseDateScope.allTime) {
        await refreshAllTime();
      }

      return true;
    } catch (error, stackTrace) {
      _logExpenseError('Failed to restore expense', error, stackTrace);

      return false;
    }
  }

  void setCategoryFilter(ExpenseCategory? category) {
    if (_selectedCategory == category) {
      return;
    }

    _selectedCategory = category;

    if (_dateScope == ExpenseDateScope.allTime) {
      unawaited(_resetAndLoadAllTime());
      return;
    }

    notifyListeners();
  }

  void clearCategoryFilter() {
    setCategoryFilter(null);
  }

  void setDateScope(ExpenseDateScope scope) {
    if (_dateScope == scope) {
      return;
    }

    _dateScope = scope;

    switch (scope) {
      case ExpenseDateScope.month:
        _dateExpenseSubscription?.cancel();
        _allTimeQueryGeneration++;
        _isAllTimeLoading = false;
        notifyListeners();
        break;
      case ExpenseDateScope.specificDate:
        _allTimeQueryGeneration++;
        _isAllTimeLoading = false;
        _watchSelectedDateExpenses();
        break;
      case ExpenseDateScope.allTime:
        _dateExpenseSubscription?.cancel();
        unawaited(_resetAndLoadAllTime());
        break;
    }
  }

  void setSelectedDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (DateUtils.isSameDay(_selectedDate, normalizedDate)) {
      return;
    }

    _selectedDate = normalizedDate;

    if (_dateScope == ExpenseDateScope.specificDate) {
      _watchSelectedDateExpenses();
      return;
    }

    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) {
      return;
    }

    _searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    setSearchQuery('');
  }

  Future<void> retry() async {
    switch (_dateScope) {
      case ExpenseDateScope.month:
        _watchSelectedMonthExpenses();
        break;
      case ExpenseDateScope.specificDate:
        _watchSelectedDateExpenses();
        break;
      case ExpenseDateScope.allTime:
        await _resetAndLoadAllTime();
        break;
    }
  }

  void goToPreviousMonth() {
    _selectedMonth = DateUtils.addMonthsToMonthDate(_selectedMonth, -1);
    _watchSelectedMonthExpenses();
  }

  void goToNextMonth() {
    final nextMonth = DateUtils.addMonthsToMonthDate(_selectedMonth, 1);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    if (nextMonth.isAfter(currentMonth)) {
      return;
    }

    _selectedMonth = nextMonth;
    _watchSelectedMonthExpenses();
  }

  void goToCurrentMonth() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    if (DateUtils.isSameMonth(_selectedMonth, currentMonth)) {
      return;
    }

    _selectedMonth = currentMonth;
    _watchSelectedMonthExpenses();
  }

  void _logExpenseError(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('$message: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  @override
  void dispose() {
    _monthExpenseSubscription?.cancel();
    _dateExpenseSubscription?.cancel();
    super.dispose();
  }
}
