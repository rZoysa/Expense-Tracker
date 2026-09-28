import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/views/shared/widgets/expense_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentExpensesList extends StatelessWidget {
  const RecentExpensesList({required this.expenses, super.key});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < expenses.length; index++) ...[
          ExpenseListItem(expense: expenses[index]),
          if (index != expenses.length - 1) Divider(height: 1.h, indent: 72.w),
        ],
      ],
    );
  }
}
