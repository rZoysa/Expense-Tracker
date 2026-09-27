import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../repositories/expense_repository.dart';

class ExpenseFormViewModel extends ChangeNotifier {
  ExpenseFormViewModel({required this._expenseRepository, Expense? expense})
    : _existingExpense = expense,
      _selectedCategory = expense?.category ?? ExpenseCategory.food,
      _selectedDate = expense?.date ?? DateTime.now();

  final ExpenseRepository _expenseRepository;
  final Expense? _existingExpense;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;

  bool _isSubmitting = false;
  String? _errorMessage;

  ExpenseCategory get selectedCategory => _selectedCategory;

  DateTime get selectedDate => _selectedDate;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get isEditing => _existingExpense != null;

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
        id: _existingExpense?.id,
        title: title.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
        createdAt: _existingExpense?.createdAt ?? now,
        updatedAt: now,
      );

      if (isEditing) {
        await _expenseRepository.updateExpense(expense);
      } else {
        await _expenseRepository.addExpense(expense);
      }

      return true;
    } catch (error, stackTrace) {
      _errorMessage = isEditing
          ? 'Unable to update the expense. Please try again.'
          : 'Unable to save the expense. Please try again.';

      debugPrint('Failed to save expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExpense() async {
    if (_isSubmitting) {
      return false;
    }

    final expenseId = _existingExpense?.id;

    if (expenseId == null) {
      _errorMessage = 'Unable to delete this expense.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseRepository.deleteExpense(expenseId);
      return true;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to delete the expense. Please try again.';

      debugPrint('Failed to delete expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
