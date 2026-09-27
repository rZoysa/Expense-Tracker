import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...ExpenseCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.label),
                selected: selectedCategory == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
