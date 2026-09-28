import 'package:expense_tracker/models/expense_date_scope.dart';
import 'package:flutter/material.dart';

class DateScopeSelector extends StatelessWidget {
  const DateScopeSelector({
    required this.selectedScope,
    required this.onSelected,
    super.key,
  });

  final ExpenseDateScope selectedScope;
  final ValueChanged<ExpenseDateScope> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExpenseDateScope>(
      segments: const [
        ButtonSegment(value: ExpenseDateScope.month, label: Text('Month')),
        ButtonSegment(
          value: ExpenseDateScope.specificDate,
          label: Text('Date'),
        ),
        ButtonSegment(value: ExpenseDateScope.allTime, label: Text('All time')),
      ],
      selected: {selectedScope},
      onSelectionChanged: (selection) {
        onSelected(selection.first);
      },
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
    );
  }
}
