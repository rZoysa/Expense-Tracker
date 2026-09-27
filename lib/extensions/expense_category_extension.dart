import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';

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

  IconData get icon {
    return switch (this) {
      ExpenseCategory.food => Icons.restaurant_outlined,
      ExpenseCategory.transport => Icons.directions_car_outlined,
      ExpenseCategory.shopping => Icons.shopping_bag_outlined,
      ExpenseCategory.bills => Icons.receipt_long_outlined,
      ExpenseCategory.entertainment => Icons.movie_outlined,
      ExpenseCategory.health => Icons.health_and_safety_outlined,
      ExpenseCategory.education => Icons.school_outlined,
      ExpenseCategory.other => Icons.category_outlined,
    };
  }
}
