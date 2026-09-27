import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/views/expense_dashboard_screen/widgets/expense_list_item.dart';
import 'package:flutter/material.dart';

class ExpenseList extends StatelessWidget {
  const ExpenseList({
    required this.expenses,
    required this.onExpenseTap,
    super.key,
  });

  final List<Expense> expenses;
  final ValueChanged<Expense> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: expenses.length,
      separatorBuilder: (_, _) {
        return const Divider(height: 1, indent: 72);
      },
      itemBuilder: (context, index) {
        final expense = expenses[index];

        return ExpenseListItem(
          expense: expense,
          onTap: () => onExpenseTap(expense),
        );
      },
    );
  }
}
