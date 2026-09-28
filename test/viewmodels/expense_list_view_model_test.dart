import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_date_scope.dart';
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

    test('starts in month loading state', () {
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.expenses, isEmpty);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.dateScope, ExpenseDateScope.month);
    });

    test('updates monthly expenses when repository emits data', () {
      final selectedMonth = viewModel.selectedMonth;
      final expense = _expense(
        id: '1',
        title: 'Lunch',
        amount: 1500,
        category: ExpenseCategory.food,
        date: DateTime(selectedMonth.year, selectedMonth.month, 5),
      );

      repository.emitExpenses([expense]);

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.selectedMonthExpenses, hasLength(1));
      expect(viewModel.selectedMonthExpenses.first.title, 'Lunch');
    });

    test('calculates monthly total and category summary', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1000,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 5),
        ),
        _expense(
          id: '2',
          title: 'Groceries',
          amount: 2500,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 10),
        ),
        _expense(
          id: '3',
          title: 'Fuel',
          amount: 2000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 12),
        ),
      ]);

      expect(viewModel.monthlyTotal, 5500);
      expect(viewModel.categorySummary, hasLength(2));
      expect(viewModel.categorySummary.first.category, ExpenseCategory.food);
      expect(viewModel.categorySummary.first.total, 3500);
    });

    test('category filter does not change dashboard monthly total', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1000,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 5),
        ),
        _expense(
          id: '2',
          title: 'Fuel',
          amount: 2000,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 10),
        ),
      ]);

      viewModel.setCategoryFilter(ExpenseCategory.food);

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.monthlyTotal, 3000);
    });

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
      expect(viewModel.recentExpenses.map((expense) => expense.title), [
        'First',
        'Second',
        'Third',
      ]);
    });

    test('search combines with month and category filters', () {
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Team Lunch',
          amount: 1800,
          category: ExpenseCategory.food,
          date: DateTime(selectedMonth.year, selectedMonth.month, 20),
          note: 'Design meeting',
        ),
        _expense(
          id: '2',
          title: 'Team Taxi',
          amount: 1500,
          category: ExpenseCategory.transport,
          date: DateTime(selectedMonth.year, selectedMonth.month, 18),
        ),
      ]);

      viewModel.setCategoryFilter(ExpenseCategory.food);
      viewModel.setSearchQuery('design');

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Team Lunch');
    });

    test('specific date scope uses date-scoped repository stream', () {
      final selectedDate = DateTime(2026, 9, 15);

      viewModel.setSelectedDate(selectedDate);
      viewModel.setDateScope(ExpenseDateScope.specificDate);

      repository.emitDateExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1000,
          category: ExpenseCategory.food,
          date: DateTime(2026, 9, 15, 12, 30),
        ),
      ]);

      expect(viewModel.isTransactionsLoading, isFalse);
      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Lunch');
    });

    test('specific date and category filters combine', () {
      viewModel.setSelectedDate(DateTime(2026, 9, 15));
      viewModel.setDateScope(ExpenseDateScope.specificDate);

      repository.emitDateExpenses([
        _expense(
          id: '1',
          title: 'Lunch',
          amount: 1000,
          category: ExpenseCategory.food,
          date: DateTime(2026, 9, 15, 12),
        ),
        _expense(
          id: '2',
          title: 'Taxi',
          amount: 1500,
          category: ExpenseCategory.transport,
          date: DateTime(2026, 9, 15, 18),
        ),
      ]);

      viewModel.setCategoryFilter(ExpenseCategory.food);

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.filteredExpenses.single.title, 'Lunch');
    });

    test('all-time scope loads only the first page initially', () async {
      repository.allTimeExpenses = _manyExpenses(45);

      viewModel.setDateScope(ExpenseDateScope.allTime);
      await _flushAsync();

      expect(viewModel.dateScopedExpenses, hasLength(20));
      expect(viewModel.loadedAllTimeCount, 20);
      expect(viewModel.hasMoreAllTime, isTrue);
      expect(repository.fetchPageCallCount, 1);
    });

    test('loadMoreAllTime appends the next page', () async {
      repository.allTimeExpenses = _manyExpenses(45);

      viewModel.setDateScope(ExpenseDateScope.allTime);
      await _flushAsync();
      await viewModel.loadMoreAllTime();

      expect(viewModel.dateScopedExpenses, hasLength(40));
      expect(viewModel.hasMoreAllTime, isTrue);

      await viewModel.loadMoreAllTime();

      expect(viewModel.dateScopedExpenses, hasLength(45));
      expect(viewModel.hasMoreAllTime, isFalse);
    });

    test(
      'all-time category change resets pagination and queries that category',
      () async {
        repository.allTimeExpenses = [
          ..._manyExpenses(25, category: ExpenseCategory.food),
          ..._manyExpenses(
            25,
            startIndex: 100,
            category: ExpenseCategory.transport,
          ),
        ];

        viewModel.setDateScope(ExpenseDateScope.allTime);
        await _flushAsync();

        expect(viewModel.loadedAllTimeCount, 20);

        viewModel.setCategoryFilter(ExpenseCategory.transport);
        await _flushAsync();

        expect(viewModel.loadedAllTimeCount, 20);
        expect(
          viewModel.dateScopedExpenses.every(
            (expense) => expense.category == ExpenseCategory.transport,
          ),
          isTrue,
        );
      },
    );

    test(
      'all-time search filters only loaded pages without changing dashboard',
      () async {
        final selectedMonth = viewModel.selectedMonth;
        repository.emitExpenses([
          _expense(
            id: 'dashboard-1',
            title: 'Current Lunch',
            amount: 1000,
            category: ExpenseCategory.food,
            date: DateTime(selectedMonth.year, selectedMonth.month, 10),
          ),
        ]);

        repository.allTimeExpenses = [
          _expense(
            id: '1',
            title: 'Team Lunch',
            amount: 1800,
            category: ExpenseCategory.food,
            date: DateTime(2026, 8, 20),
          ),
          ..._manyExpenses(24, startIndex: 10),
        ];

        viewModel.setDateScope(ExpenseDateScope.allTime);
        await _flushAsync();
        viewModel.setSearchQuery('team');

        expect(viewModel.filteredExpenses, hasLength(1));
        expect(viewModel.monthlyTotal, 1000);
        expect(viewModel.selectedMonthExpenses, hasLength(1));
      },
    );

    test('all-time load failure exposes pagination error', () async {
      repository.fetchPageError = Exception('Firestore failed');

      viewModel.setDateScope(ExpenseDateScope.allTime);
      await _flushAsync();

      expect(viewModel.hasTransactionsError, isTrue);
      expect(
        viewModel.transactionsErrorMessage,
        'Unable to load older expenses.',
      );
    });

    test('switches to previous month and listens to the new month', () {
      viewModel.goToPreviousMonth();
      final selectedMonth = viewModel.selectedMonth;

      repository.emitExpenses([
        _expense(
          id: '1',
          title: 'Previous month',
          amount: 2500,
          category: ExpenseCategory.bills,
          date: DateTime(selectedMonth.year, selectedMonth.month, 10),
        ),
      ]);

      expect(viewModel.filteredExpenses, hasLength(1));
      expect(viewModel.monthlyTotal, 2500);
    });

    test('exposes error when monthly stream fails', () {
      repository.emitWatchError(Exception('Firestore failed'));

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, 'Unable to load expenses.');
    });

    test('monthly retry creates only one replacement listener', () async {
      expect(repository.watchMonthCallCount, 1);

      repository.emitWatchError(Exception('Firestore failed'));
      await viewModel.retry();

      expect(repository.watchMonthCallCount, 2);
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

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

List<Expense> _manyExpenses(
  int count, {
  int startIndex = 0,
  ExpenseCategory category = ExpenseCategory.food,
}) {
  return List.generate(count, (offset) {
    final index = startIndex + offset;
    final date = DateTime(2026, 9, 30).subtract(Duration(days: index));

    return _expense(
      id: 'expense-$index',
      title: 'Expense $index',
      amount: 1000 + index.toDouble(),
      category: category,
      date: date,
    );
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
