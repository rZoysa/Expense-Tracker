import 'package:expense_tracker/models/expense_category.dart';

class CategoryExpenseSummary {
  const CategoryExpenseSummary({
    required this.category,
    required this.total,
  });

  final ExpenseCategory category;
  final double total;
}
