import 'dart:async';

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final StreamController<List<Expense>> _expensesController =
      StreamController<List<Expense>>.broadcast(sync: true);

  Expense? addedExpense;
  Expense? updatedExpense;
  Expense? restoredExpense;
  String? deletedExpenseId;

  Object? addExpenseError;
  Object? updateExpenseError;
  Object? deleteExpenseError;
  Object? restoreExpenseError;

  @override
  Stream<List<Expense>> watchExpenses() {
    return _expensesController.stream;
  }

  void emitExpenses(List<Expense> expenses) {
    _expensesController.add(expenses);
  }

  void emitWatchError(Object error) {
    _expensesController.addError(error, StackTrace.current);
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

  Future<void> dispose() {
    return _expensesController.close();
  }
}
