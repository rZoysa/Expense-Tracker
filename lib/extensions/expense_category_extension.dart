import 'package:expense_tracker/models/expense_category.dart';

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label {
    return switch (this) {
      ExpenseCategory.food => 'Food',
      ExpenseCategory.transport => 'Transport',
      ExpenseCategory.shopping => 'Shopping',
      ExpenseCategory.bills => 'Bills',
      ExpenseCategory.entertainment => 'Entertainment',
      ExpenseCategory.health => 'Health',
      ExpenseCategory.education => 'Education',
      ExpenseCategory.other => 'Other',
    };
  }
}
