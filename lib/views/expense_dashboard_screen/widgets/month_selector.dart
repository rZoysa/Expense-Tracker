import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    required this.selectedMonth,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final DateTime selectedMonth;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final monthLabel = MaterialLocalizations.of(context)
        .formatMonthYear(selectedMonth);

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Previous month',
          icon: Icon(Icons.chevron_left, size: 24.r),
        ),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : onNext,
          tooltip: 'Next month',
          icon: Icon(Icons.chevron_right, size: 24.r),
        ),
      ],
    );
  }
}
