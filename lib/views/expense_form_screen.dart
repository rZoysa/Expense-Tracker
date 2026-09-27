import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_category.dart';
import '../viewmodels/expense_form_view_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final viewModel = context.read<ExpenseFormViewModel>();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    context.read<ExpenseFormViewModel>().setDate(selectedDate);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());

    final viewModel = context.read<ExpenseFormViewModel>();

    final wasSaved = await viewModel.saveExpense(
      title: _titleController.text,
      amount: amount,
      note: _noteController.text,
    );

    if (!mounted) {
      return;
    }

    if (wasSaved) {
      Navigator.of(context).pop();
    }
  }

  String _categoryLabel(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.food => 'Food',
      ExpenseCategory.transport => 'Transport',
      ExpenseCategory.shopping => 'Shopping',
      ExpenseCategory.bills => 'Bills',
      ExpenseCategory.entertainment => 'Entertainment',
      ExpenseCategory.health => 'Health',
      ExpenseCategory.education => 'Education',
      ExpenseCategory.other => 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExpenseFormViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Lunch',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final title = value?.trim() ?? '';

                    if (title.isEmpty) {
                      return 'Please enter a title.';
                    }

                    if (title.length > 60) {
                      return 'Title must be 60 characters or fewer.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    prefixText: 'LKR ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final input = value?.trim() ?? '';

                    if (input.isEmpty) {
                      return 'Please enter an amount.';
                    }

                    final amount = double.tryParse(input);

                    if (amount == null) {
                      return 'Please enter a valid amount.';
                    }

                    if (amount <= 0) {
                      return 'Amount must be greater than zero.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: viewModel.selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ExpenseCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(_categoryLabel(category)),
                        ),
                      )
                      .toList(),
                  onChanged: viewModel.isSubmitting
                      ? null
                      : (category) {
                          if (category != null) {
                            context.read<ExpenseFormViewModel>().setCategory(
                              category,
                            );
                          }
                        },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: viewModel.isSubmitting ? null : _pickDate,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(viewModel.selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Optional description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: viewModel.isSubmitting ? null : _submit,
                  child: viewModel.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
