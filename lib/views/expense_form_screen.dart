import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_form_result.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';

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
      helpText: 'Select expense date',
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
        final dialogColorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Delete expense?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This expense will be deleted. You will have a few seconds to undo it from the transactions screen.',
              ),
              SizedBox(height: 20.h),
              SlideAction(
                height: 56.h,
                borderRadius: 18.r,
                elevation: 0,
                innerColor: dialogColorScheme.error,
                outerColor: dialogColorScheme.errorContainer,
                sliderButtonIcon: Icon(
                  Icons.delete_forever_outlined,
                  color: dialogColorScheme.onError,
                  size: 22.r,
                ),
                submittedIcon: Icon(
                  Icons.check_rounded,
                  color: dialogColorScheme.onErrorContainer,
                  size: 22.r,
                ),
                child: Text(
                  'Slide to delete',
                  style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                    color: dialogColorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onSubmit: () {
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
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

    if (!mounted || !wasDeleted || widget.expense == null) {
      return;
    }

    Navigator.of(context).pop(ExpenseFormResult.deleted(widget.expense!));
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final viewModel = context.read<ExpenseFormViewModel>();
    final amount = double.parse(_amountController.text.trim());

    final wasSaved = await viewModel.saveExpense(
      title: _titleController.text,
      amount: amount,
      note: _noteController.text,
    );

    if (!mounted || !wasSaved || viewModel.lastSavedExpense == null) {
      return;
    }

    Navigator.of(context)
        .pop(ExpenseFormResult.saved(viewModel.lastSavedExpense!));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExpenseFormViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.isEditing ? 'Edit expense' : 'Add expense'),
        actions: [
          if (viewModel.isEditing)
            IconButton(
              onPressed: viewModel.isSubmitting ? null : _deleteExpense,
              tooltip: 'Delete expense',
              icon: Icon(
                Icons.delete_outline,
                size: 24.r,
                color: colorScheme.error,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              children: [
                _FormHeader(isEditing: viewModel.isEditing),
                SizedBox(height: 20.h),
                _FormSectionCard(
                  title: 'Expense details',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Team lunch',
                          prefixIcon: Icon(Icons.edit_outlined),
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
                          prefixIcon: Icon(Icons.payments_outlined),
                          prefixText: 'LKR ',
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
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _FormSectionCard(
                  title: 'Category & date',
                  icon: Icons.tune_outlined,
                  child: Column(
                    children: [
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: viewModel.selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: ExpenseCategory.values
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(category.icon, size: 20.r),
                                    SizedBox(width: 10.w),
                                    Text(category.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: viewModel.isSubmitting
                            ? null
                            : (category) {
                                if (category != null) {
                                  context
                                      .read<ExpenseFormViewModel>()
                                      .setCategory(category);
                                }
                              },
                      ),
                      SizedBox(height: 16.h),
                      InkWell(
                        onTap: viewModel.isSubmitting ? null : _pickDate,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.chevron_right),
                          ),
                          child: Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(viewModel.selectedDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _FormSectionCard(
                  title: 'Note',
                  icon: Icons.notes_outlined,
                  child: TextFormField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add an optional note or description',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20.r,
                          color: colorScheme.onErrorContainer,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
          child: SizedBox(
            height: 52.h,
            child: FilledButton.icon(
              onPressed: viewModel.isSubmitting ? null : _submit,
              icon: viewModel.isSubmitting
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(strokeWidth: 2.r),
                    )
                  : Icon(
                      viewModel.isEditing
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                      size: 22.r,
                    ),
              label: Text(viewModel.isEditing ? 'Save changes' : 'Add expense'),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEditing ? Icons.edit_outlined : Icons.add_card_outlined,
              color: colorScheme.onPrimary,
              size: 24.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Update transaction' : 'Record a new expense',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isEditing ? 'Make the changes you need and save them.' : 'Add the important details now. You can edit them later.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20.r),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            child,
          ],
        ),
      ),
    );
  }
}
