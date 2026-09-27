import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/expense_category.dart';
import '../viewmodels/expense_form_view_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.expense?.title ?? '');

    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(2) ?? '',
    );

    _noteController = TextEditingController(text: widget.expense?.note ?? '');
  }

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

  Future<void> _deleteExpense() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete expense?'),
          content: const Text('This expense will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final wasDeleted = await context
        .read<ExpenseFormViewModel>()
        .deleteExpense();

    if (!mounted) {
      return;
    }

    if (wasDeleted) {
      Navigator.of(context).pop(widget.expense);
    }
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
      appBar: AppBar(
        title: Text(viewModel.isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (viewModel.isEditing)
            IconButton(
              color: Colors.red,
              onPressed: viewModel.isSubmitting ? null : _deleteExpense,
              tooltip: 'Delete expense',
              icon: Icon(Icons.delete_outline, size: 24.r),
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
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
                    textCapitalization: .sentences,
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
                  SizedBox(height: 16.h),
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
                  SizedBox(height: 16.h),
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
                  SizedBox(height: 16.h),
                  InkWell(
                    onTap: viewModel.isSubmitting ? null : _pickDate,
                    borderRadius: BorderRadius.circular(4.r),
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
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    maxLength: 200,
                    textCapitalization: .sentences,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Optional description',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (viewModel.errorMessage != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      viewModel.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  FilledButton(
                    onPressed: viewModel.isSubmitting ? null : _submit,
                    child: viewModel.isSubmitting
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(strokeWidth: 2.r),
                          )
                        : Text(
                            viewModel.isEditing
                                ? 'Update Expense'
                                : 'Save Expense',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
