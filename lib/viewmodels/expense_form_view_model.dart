import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../repositories/expense_repository.dart';

class ExpenseFormViewModel extends ChangeNotifier {
  ExpenseFormViewModel({required this._expenseRepository});

  final ExpenseRepository _expenseRepository;

  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  ExpenseCategory get selectedCategory => _selectedCategory;

  DateTime get selectedDate => _selectedDate;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  void setCategory(ExpenseCategory category) {
    if (_selectedCategory == category) {
      return;
    }

    _selectedCategory = category;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);

    notifyListeners();
  }

  Future<bool> saveExpense({
    required String title,
    required double amount,
    String? note,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final trimmedNote = note?.trim();

      final expense = Expense(
        title: title.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
        createdAt: now,
        updatedAt: now,
      );

      await _expenseRepository.addExpense(expense);

      return true;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to save the expense. Please try again.';

      debugPrint('Failed to save expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
