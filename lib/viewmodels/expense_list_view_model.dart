import 'dart:async';

import 'package:expense_tracker/models/category_expense_summary.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseListViewModel extends ChangeNotifier {
  ExpenseListViewModel({required this._expenseRepository}) {
    _watchExpenses();
  }

  final ExpenseRepository _expenseRepository;

  StreamSubscription<List<Expense>>? _expenseSubscription;

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  ExpenseCategory? get selectedCategory => _selectedCategory;

  String get searchQuery => _searchQuery;

  bool get hasSearchQuery => _searchQuery.trim().isNotEmpty;

  DateTime get selectedMonth => _selectedMonth;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get isEmpty => !_isLoading && !hasError && _expenses.isEmpty;

  bool get isCurrentMonth {
    final now = DateTime.now();

    return DateUtils.isSameMonth(_selectedMonth, now);
  }

  List<Expense> get selectedMonthExpenses {
    return _expenses
        .where((expense) => DateUtils.isSameMonth(expense.date, _selectedMonth))
        .toList();
  }

  List<Expense> get recentExpenses {
    return selectedMonthExpenses.take(3).toList();
  }

  List<Expense> get filteredExpenses {
    final normalizedSearchQuery = _searchQuery.trim().toLowerCase();

    return selectedMonthExpenses.where((expense) {
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
    return _expenses
        .where((expense) => DateUtils.isSameMonth(expense.date, _selectedMonth))
        .fold(0.0, (total, expense) => total + expense.amount);
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

    final summaries = totalsByCategory.entries
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

  void _watchExpenses() {
    _isLoading = true;
    _errorMessage = null;

    _expenseSubscription = _expenseRepository.watchExpenses().listen(
      (expenses) {
        _expenses = expenses;
        _isLoading = false;
        _errorMessage = null;

        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _isLoading = false;
        _errorMessage = 'Unable to load expenses.';

        debugPrint('Failed to load expenses: $error');
        debugPrintStack(stackTrace: stackTrace);

        notifyListeners();
      },
    );
  }

  Future<bool> restoreExpense(Expense expense) async {
    try {
      await _expenseRepository.restoreExpense(expense);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to restore expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  void setCategoryFilter(ExpenseCategory? category) {
    if (_selectedCategory == category) {
      return;
    }

    _selectedCategory = category;
    notifyListeners();
  }

  void clearCategoryFilter() {
    setCategoryFilter(null);
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
    await _expenseSubscription?.cancel();
    _watchExpenses();

    notifyListeners();
  }

  void goToPreviousMonth() {
    _selectedMonth = DateUtils.addMonthsToMonthDate(_selectedMonth, -1);

    notifyListeners();
  }

  void goToNextMonth() {
    final nextMonth = DateUtils.addMonthsToMonthDate(_selectedMonth, 1);

    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    if (nextMonth.isAfter(currentMonth)) {
      return;
    }

    _selectedMonth = nextMonth;
    notifyListeners();
  }

  void goToCurrentMonth() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    if (DateUtils.isSameMonth(_selectedMonth, currentMonth)) {
      return;
    }

    _selectedMonth = currentMonth;
    notifyListeners();
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
