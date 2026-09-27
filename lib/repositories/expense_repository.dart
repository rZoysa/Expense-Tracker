import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_page.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpensesForMonth(DateTime month);

  Stream<List<Expense>> watchExpensesForDate(DateTime date);

  Future<ExpensePage> fetchExpensePage({
    ExpensePageCursor? cursor,
    ExpenseCategory? category,
    int pageSize = 20,
  });

  Future<void> addExpense(Expense expense);

  Future<void> updateExpense(Expense expense);

  Future<void> deleteExpense(String expenseId);

  Future<void> restoreExpense(Expense expense);
}
