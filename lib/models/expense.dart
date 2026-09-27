import 'package:expense_tracker/models/expense_category.dart';

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}
