import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({required this.expense, this.onTap, super.key});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = MaterialLocalizations.of(context)
        .formatMediumDate(expense.date);

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: CircleAvatar(
        radius: 20.r,
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        child: Icon(expense.category.icon, size: 22.r),
      ),
      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${expense.category.label} • $formattedDate',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        CurrencyFormatter.formatLkr(expense.amount),
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
