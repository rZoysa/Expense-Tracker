import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_form_result.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:expense_tracker/utils/currency_formatter.dart';
import 'package:expense_tracker/viewmodels/expense_form_view_model.dart';
import 'package:expense_tracker/views/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({required this.expense, super.key});

  final Expense expense;

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late Expense _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  Future<void> _editExpense() async {
    final expenseRepository = context.read<ExpenseRepository>();

    final result = await Navigator.of(context).push<ExpenseFormResult>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ExpenseFormViewModel(
            expenseRepository: expenseRepository,
            expense: _expense,
          ),
          child: ExpenseFormScreen(expense: _expense),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.wasDeleted) {
      Navigator.of(context).pop(result);
      return;
    }

    setState(() {
      _expense = result.expense;
    });
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );

    return '$date • $time';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final note = _expense.note?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction details')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
        children: [
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expense.category.icon,
                      size: 30.r,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    _expense.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.formatLkr(_expense.amount),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Chip(
                    avatar: Icon(_expense.category.icon, size: 18.r),
                    label: Text(_expense.category.label),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _DetailsCard(
            title: 'Expense information',
            children: [
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: MaterialLocalizations.of(context)
                    .formatMediumDate(_expense.date),
              ),
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: _expense.category.label,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _DetailsCard(
            title: 'Note',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 22.r,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      note == null || note.isEmpty
                          ? 'No note added for this transaction.'
                          : note,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: note == null || note.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _DetailsCard(
            title: 'Record details',
            children: [
              _DetailRow(
                icon: Icons.add_circle_outline,
                label: 'Created',
                value: _formatDateTime(context, _expense.createdAt),
              ),
              _DetailRow(
                icon: Icons.update_outlined,
                label: 'Last updated',
                value: _formatDateTime(context, _expense.updatedAt),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
          child: SizedBox(
            height: 52.h,
            child: FilledButton.icon(
              onPressed: _editExpense,
              icon: Icon(Icons.edit_outlined, size: 22.r),
              label: const Text('Edit expense'),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 14.h),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) ...[
                SizedBox(height: 12.h),
                const Divider(),
                SizedBox(height: 12.h),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22.r, color: colorScheme.onSurfaceVariant),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
