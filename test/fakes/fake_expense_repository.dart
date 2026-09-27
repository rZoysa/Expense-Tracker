import 'dart:async';
import 'dart:math' as math;

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_page.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final StreamController<List<Expense>> _monthExpensesController =
      StreamController<List<Expense>>.broadcast(sync: true);
  final StreamController<List<Expense>> _dateExpensesController =
      StreamController<List<Expense>>.broadcast(sync: true);

  Expense? addedExpense;
  Expense? updatedExpense;
  Expense? restoredExpense;
  String? deletedExpenseId;

  List<Expense> allTimeExpenses = [];
  int fetchPageCallCount = 0;

  Object? addExpenseError;
  Object? updateExpenseError;
  Object? deleteExpenseError;
  Object? restoreExpenseError;
  Object? fetchPageError;

  @override
  Stream<List<Expense>> watchExpensesForMonth(DateTime month) {
    return _monthExpensesController.stream;
  }

  @override
  Stream<List<Expense>> watchExpensesForDate(DateTime date) {
    return _dateExpensesController.stream;
  }

  void emitExpenses(List<Expense> expenses) {
    _monthExpensesController.add(expenses);
  }

  void emitDateExpenses(List<Expense> expenses) {
    _dateExpensesController.add(expenses);
  }

  void emitWatchError(Object error) {
    _monthExpensesController.addError(error, StackTrace.current);
  }

  void emitDateWatchError(Object error) {
    _dateExpensesController.addError(error, StackTrace.current);
  }

  @override
  Future<ExpensePage> fetchExpensePage({
    ExpensePageCursor? cursor,
    ExpenseCategory? category,
    int pageSize = 20,
  }) async {
    fetchPageCallCount++;

    if (fetchPageError != null) {
      throw fetchPageError!;
    }

    final filtered = allTimeExpenses
        .where((expense) => category == null || expense.category == category)
        .toList();

    var startIndex = 0;
    if (cursor != null) {
      final cursorIndex = filtered.indexWhere(
        (expense) => expense.id == cursor.expenseId,
      );
      if (cursorIndex >= 0) {
        startIndex = cursorIndex + 1;
      }
    }

    final endIndex = math.min(startIndex + pageSize, filtered.length);
    final pageExpenses = filtered.sublist(startIndex, endIndex);
    final lastExpense = pageExpenses.isEmpty ? null : pageExpenses.last;

    return ExpensePage(
      expenses: pageExpenses,
      nextCursor: lastExpense?.id == null
          ? null
          : ExpensePageCursor(
              date: lastExpense!.date,
              expenseId: lastExpense.id!,
            ),
      hasMore: endIndex < filtered.length,
    );
  }

  @override
  Future<void> addExpense(Expense expense) async {
    if (addExpenseError != null) {
      throw addExpenseError!;
    }

    addedExpense = expense;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    if (updateExpenseError != null) {
      throw updateExpenseError!;
    }

    updatedExpense = expense;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    if (deleteExpenseError != null) {
      throw deleteExpenseError!;
    }

    deletedExpenseId = expenseId;
  }

  @override
  Future<void> restoreExpense(Expense expense) async {
    if (restoreExpenseError != null) {
      throw restoreExpenseError!;
    }

    restoredExpense = expense;
  }

  Future<void> dispose() async {
    await _monthExpensesController.close();
    await _dateExpensesController.close();
  }
}
