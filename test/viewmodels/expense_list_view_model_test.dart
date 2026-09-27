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

    test('recent expenses ignore category filter and are limited to three', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'First',
          amount: 1000,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
        ),
        _expense(
          id: '2',
          title: 'Second',
          amount: 2000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
        ),
        _expense(
          id: '3',
          title: 'Third',
          amount: 3000,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 15),
        ),
        _expense(
          id: '4',
          title: 'Fourth',
          amount: 4000,
          category: ExpenseCategory.bills,
          date: DateTime(selectedMonth.year, selectedMonth.month, 10),
        ),
      ]);

      viewModel.setCategoryFilter(ExpenseCategory.food);

      expect(viewModel.filteredExpenses, hasLength(2));
      expect(viewModel.selectedMonthExpenses, hasLength(4));
      expect(viewModel.recentExpenses, hasLength(3));
      expect(viewModel.recentExpenses.map((expense) => expense.title), [
        'First',
        'Second',
        'Third',
      ]);
    });

    test('searches expenses by title case-insensitively', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Team Lunch',
          amount: 1800,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
        ),
        _expense(
          id: '2',
          title: 'Fuel',
          amount: 5000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
        ),
      ]);

      viewModel.setSearchQuery('LUNCH');

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Team Lunch');
    });

    test('searches expenses by note', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1800,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
          note: 'Meeting with design team',
        ),
        _expense(
          id: '2',
          title: 'Fuel',
          amount: 5000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
        ),
      ]);

      viewModel.setSearchQuery('design');

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Lunch');
    });

    test('searches expenses by category name', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1800,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
        ),
        _expense(
          id: '2',
          title: 'Fuel',
          amount: 5000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
        ),
      ]);

      viewModel.setSearchQuery('transport');

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Fuel');
    });

    test('combines search query with category filter', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1800,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
          note: 'Team meeting',
        ),
        _expense(
          id: '2',
          title: 'Taxi',
          amount: 1500,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
          note: 'Team meeting transport',
        ),
      ]);

      viewModel.setSearchQuery('team');
      viewModel.setCategoryFilter(ExpenseCategory.food);

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Lunch');
    });

    test('clearing search restores category-filtered results', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1800,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
        ),
        _expense(
          id: '2',
          title: 'Groceries',
          amount: 4000,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
        ),
        _expense(
          id: '3',
          title: 'Fuel',
          amount: 5000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 16),
        ),
      ]);

      viewModel.setCategoryFilter(ExpenseCategory.food);
      viewModel.setSearchQuery('lunch');

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.hasSearchQuery, isTrue);

      viewModel.clearSearchQuery();

      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.hasSearchQuery, isFalse);
      expect(viewModel.filteredExpenses, hasLength(2));
    });

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
  String? note,
}) {
  return Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    note: note,
    createdAt: date,
    updatedAt: date,
  );
}
