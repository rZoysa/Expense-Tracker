import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseListViewModel extends ChangeNotifier {
  ExpenseListViewModel({required this._expenseRepository}) {
    _watchExpenses();
  }

  final ExpenseRepository _expenseRepository;

  StreamSubscription<List<Expense>>? _expenseSubscription;

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get isEmpty => !_isLoading && !hasError && _expenses.isEmpty;

  void _watchExpenses() {
    _isLoading = true;
    _errorMessage = null;

    _expenseSubscription = _expenseRepository.watchExpenses().listen(
      (expenses) {
        _expenses = expenses;
        _isLoading = false;
        _errorMessage = null;

        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _isLoading = false;
        _errorMessage = 'Unable to load expenses.';

        debugPrint('Failed to load expenses: $error');
        debugPrintStack(stackTrace: stackTrace);

        notifyListeners();
      },
    );
  }

  Future<bool> restoreExpense(Expense expense) async {
    try {
      await _expenseRepository.restoreExpense(expense);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to restore expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  Future<void> retry() async {
    await _expenseSubscription?.cancel();
    _watchExpenses();

    notifyListeners();
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
