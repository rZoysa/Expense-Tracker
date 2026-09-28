import 'package:expense_tracker/models/expense.dart';

class ExpensePageCursor {
  const ExpensePageCursor({required this.date, required this.expenseId});

  final DateTime date;
  final String expenseId;
}

class ExpensePage {
  const ExpensePage({
    required this.expenses,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<Expense> expenses;
  final ExpensePageCursor? nextCursor;
  final bool hasMore;
}
