import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/viewmodels/expense_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_expense_repository.dart';

void main() {
  group('ExpenseListViewModel', () {
    late FakeExpenseRepository repository;
    late ExpenseListViewModel viewModel;

    setUp(() {
      repository = FakeExpenseRepository();

      viewModel = ExpenseListViewModel(expenseRepository: repository);
    });

    tearDown(() async {
      viewModel.dispose();
      await repository.dispose();
    });

    test('starts in loading state', () {
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.expenses, isEmpty);
      expect(viewModel.hasError, isFalse);
    });

    test('updates expenses when repository emits data', () {
      final now = DateTime.now();

      final expense = _expense(
        id: '1',
        title: 'Lunch',
        amount: 1500,
        category: ExpenseCategory.food,
        date: DateTime(now.year, now.month, 5),
      );

      repository.emitExpenses([expense]);

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.expenses, hasLength(1));
      expect(viewModel.expenses.first.title, 'Lunch');
      expect(viewModel.hasError, isFalse);
    });

    test('calculates total for selected month', () {
      final now = DateTime.now();

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1000,
          category: ExpenseCategory.food,
          date: DateTime(now.year, now.month, 5),
        ),
        _expense(
          id: '2',
          title: 'Fuel',
          amount: 2000,
          category: ExpenseCategory.transport,
          date: DateTime(now.year, now.month, 10),
        ),
        _expense(
          id: '3',
          title: 'Old expense',
          amount: 5000,
          category: ExpenseCategory.food,
          date: DateTime(now.year, now.month - 1, 10),
        ),
      ]);

      expect(viewModel.monthlyTotal, 3000);
    });

    test(
      'filters selected month by category without changing monthly total',
      () {
        final now = DateTime.now();

        repository.emitExpenses([
          _expense(
            id: '1',
            title: 'Lunch',
            amount: 1000,
            category: ExpenseCategory.food,
            date: DateTime(now.year, now.month, 5),
          ),
          _expense(
            id: '2',
            title: 'Fuel',
            amount: 2000,
            category: ExpenseCategory.transport,
            date: DateTime(now.year, now.month, 10),
          ),
        ]);

        expect(viewModel.filteredExpenses, hasLength(2));

        viewModel.setCategoryFilter(ExpenseCategory.food);

        expect(viewModel.filteredExpenses, hasLength(1));

        expect(viewModel.filteredExpenses.single.title, 'Lunch');

        // Category filtering should not change the month's total.
        expect(viewModel.monthlyTotal, 3000);
      },
    );

    test('switches to previous month', () {
      final now = DateTime.now();

      final previousMonthExpense = _expense(
        id: '1',
        title: 'Previous month',
        amount: 2500,
        category: ExpenseCategory.bills,
        date: DateTime(now.year, now.month - 1, 10),
      );

      repository.emitExpenses([previousMonthExpense]);

      expect(viewModel.filteredExpenses, isEmpty);

      viewModel.goToPreviousMonth();

      expect(viewModel.filteredExpenses, hasLength(1));

      expect(viewModel.monthlyTotal, 2500);
    });

    test('exposes error when expense stream fails', () {
      repository.emitWatchError(Exception('Firestore failed'));

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, 'Unable to load expenses.');
    });

    test('restores expense through repository', () async {
      final expense = _expense(
        id: 'expense-1',
        title: 'Lunch',
        amount: 1000,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      );

      final result = await viewModel.restoreExpense(expense);

      expect(result, isTrue);
      expect(repository.restoredExpense, same(expense));
    });

    test('returns false when restore fails', () async {
      repository.restoreExpenseError = Exception('Restore failed');

      final expense = _expense(
        id: 'expense-1',
        title: 'Lunch',
        amount: 1000,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      );

      final result = await viewModel.restoreExpense(expense);

      expect(result, isFalse);
    });
  });
}

Expense _expense({
  required String id,
  required String title,
  required double amount,
  required ExpenseCategory category,
  required DateTime date,
}) {
  return Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    createdAt: date,
    updatedAt: date,
  );
}
