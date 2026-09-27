import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_page.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository({
    required this._userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _expensesCollection {
    return _firestore.collection('users').doc(_userId).collection('expenses');
  }

  @override
  Stream<List<Expense>> watchExpensesForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month);
    final startOfNextMonth = DateTime(month.year, month.month + 1);

    return _expensesCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_expenseFromDocument).toList());
  }

  @override
  Stream<List<Expense>> watchExpensesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final startOfNextDay = DateTime(date.year, date.month, date.day + 1);

    return _expensesCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_expenseFromDocument).toList());
  }

  @override
  Future<ExpensePage> fetchExpensePage({
    ExpensePageCursor? cursor,
    ExpenseCategory? category,
    int pageSize = 20,
  }) async {
    Query<Map<String, dynamic>> query = _expensesCollection;

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    query = query
        .orderBy('date', descending: true)
        .orderBy(FieldPath.documentId, descending: true);

    if (cursor != null) {
      query = query.startAfter([
        Timestamp.fromDate(cursor.date),
        _expensesCollection.doc(cursor.expenseId),
      ]);
    }

    final snapshot = await query.limit(pageSize).get();
    final documents = snapshot.docs;
    final expenses = documents.map(_expenseFromDocument).toList();

    final lastDocument = documents.isEmpty ? null : documents.last;
    final nextCursor = lastDocument == null
        ? null
        : ExpensePageCursor(
            date: (lastDocument.data()['date'] as Timestamp).toDate(),
            expenseId: lastDocument.id,
          );

    return ExpensePage(
      expenses: expenses,
      nextCursor: nextCursor,
      hasMore: documents.length == pageSize,
    );
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await _expensesCollection.add(_expenseToMap(expense));
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseId = expense.id;

    if (expenseId == null) {
      throw ArgumentError('Cannot update an expense without an ID.');
    }

    await _expensesCollection.doc(expenseId).update(_expenseToMap(expense));
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _expensesCollection.doc(expenseId).delete();
  }

  @override
  Future<void> restoreExpense(Expense expense) async {
    final expenseId = expense.id;

    if (expenseId == null) {
      throw ArgumentError('Cannot restore an expense without an ID.');
    }

    await _expensesCollection.doc(expenseId).set(_expenseToMap(expense));
  }

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category.name,
      'date': Timestamp.fromDate(expense.date),
      'note': expense.note,
      'createdAt': Timestamp.fromDate(expense.createdAt),
      'updatedAt': Timestamp.fromDate(expense.updatedAt),
    };
  }

  Expense _expenseFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return Expense(
      id: document.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: ExpenseCategory.values.byName(data['category'] as String),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
