import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_expense_repository.dart';

void main() {
  group('ExpenseFormViewModel', () {
    late FakeExpenseRepository repository;

    setUp(() {
      repository = FakeExpenseRepository();
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('starts with default values when creating an expense', () {
      final viewModel = ExpenseFormViewModel(expenseRepository: repository);

      expect(viewModel.isEditing, isFalse);
      expect(viewModel.selectedCategory, ExpenseCategory.food);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('updates selected category and normalizes selected date', () {
      final viewModel = ExpenseFormViewModel(expenseRepository: repository);

      viewModel.setCategory(ExpenseCategory.transport);
      viewModel.setDate(DateTime(2026, 9, 15, 18, 30));

      expect(viewModel.selectedCategory, ExpenseCategory.transport);

      expect(viewModel.selectedDate, DateTime(2026, 9, 15));
    });

    test('creates a new expense using repository', () async {
      final viewModel = ExpenseFormViewModel(expenseRepository: repository);

      viewModel.setCategory(ExpenseCategory.food);

      final result = await viewModel.saveExpense(
        title: '  Team Lunch  ',
        amount: 1800,
        note: '  Lunch with team  ',
      );

      expect(result, isTrue);
      expect(repository.addedExpense, isNotNull);

      final expense = repository.addedExpense!;

      expect(expense.id, isNull);
      expect(expense.title, 'Team Lunch');
      expect(expense.amount, 1800);
      expect(expense.category, ExpenseCategory.food);
      expect(expense.note, 'Lunch with team');
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('converts blank note to null', () async {
      final viewModel = ExpenseFormViewModel(expenseRepository: repository);

      await viewModel.saveExpense(title: 'Lunch', amount: 1000, note: '   ');

      expect(repository.addedExpense?.note, isNull);
    });

    test('updates existing expense instead of creating another', () async {
      final createdAt = DateTime(2026, 8, 10);

      final existingExpense = Expense(
        id: 'expense-1',
        title: 'Lunch',
        amount: 1000,
        category: ExpenseCategory.food,
        date: DateTime(2026, 8, 10),
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final viewModel = ExpenseFormViewModel(
        expenseRepository: repository,
        expense: existingExpense,
      );

      final result = await viewModel.saveExpense(
        title: 'Team Lunch',
        amount: 1500,
      );

      expect(result, isTrue);
      expect(repository.addedExpense, isNull);
      expect(repository.updatedExpense, isNotNull);

      final updatedExpense = repository.updatedExpense!;

      expect(updatedExpense.id, 'expense-1');
      expect(updatedExpense.title, 'Team Lunch');
      expect(updatedExpense.amount, 1500);

      // Original creation date must be preserved.
      expect(updatedExpense.createdAt, createdAt);
    });

    test('deletes existing expense using repository', () async {
      final expense = Expense(
        id: 'expense-1',
        title: 'Lunch',
        amount: 1000,
        category: ExpenseCategory.food,
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      final viewModel = ExpenseFormViewModel(
        expenseRepository: repository,
        expense: expense,
      );

      final result = await viewModel.deleteExpense();

      expect(result, isTrue);
      expect(repository.deletedExpenseId, 'expense-1');
    });

    test('returns false and exposes error when save fails', () async {
      repository.addExpenseError = Exception('Firestore failed');

      final viewModel = ExpenseFormViewModel(expenseRepository: repository);

      final result = await viewModel.saveExpense(title: 'Lunch', amount: 1000);

      expect(result, isFalse);
      expect(viewModel.isSubmitting, isFalse);
      expect(
        viewModel.errorMessage,
        'Unable to save the expense. Please try again.',
      );
    });
  });
}
