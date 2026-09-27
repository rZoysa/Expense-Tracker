import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: expenses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => onExpenseTap(expense),
          title: Text(expense.title),
          subtitle: Text(expense.category.label),
          trailing: Text(
            'LKR ${expense.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
