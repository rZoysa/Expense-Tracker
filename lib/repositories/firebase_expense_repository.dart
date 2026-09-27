import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
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
  Stream<List<Expense>> watchExpenses() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_expenseFromDocument).toList());
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
