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
  Expense? _lastSavedExpense;

  ExpenseCategory get selectedCategory => _selectedCategory;

  DateTime get selectedDate => _selectedDate;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  Expense? get lastSavedExpense => _lastSavedExpense;

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

      _lastSavedExpense = expense;
      return true;
    } catch (error, stackTrace) {
      _errorMessage = isEditing
          ? 'Unable to update the expense. Please try again.'
          : 'Unable to save the expense. Please try again.';

      _logFormError('Failed to save expense', error, stackTrace);

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _logFormError(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('$message: $error');
    debugPrintStack(stackTrace: stackTrace);
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

      _logFormError('Failed to delete expense', error, stackTrace);

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
