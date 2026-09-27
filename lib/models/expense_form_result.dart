import 'package:expense_tracker/models/expense.dart';

enum ExpenseFormResultType { saved, deleted }

class ExpenseFormResult {
  const ExpenseFormResult.saved(this.expense)
    : type = ExpenseFormResultType.saved;

  const ExpenseFormResult.deleted(this.expense)
    : type = ExpenseFormResultType.deleted;

  final ExpenseFormResultType type;
  final Expense expense;

  bool get wasSaved => type == ExpenseFormResultType.saved;

  bool get wasDeleted => type == ExpenseFormResultType.deleted;
}
