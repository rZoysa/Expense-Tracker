import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/views/shared/widgets/expense_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({
    required this.expenses,
    required this.onExpenseTap,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
    this.onLoadMore,
    super.key,
  });

  final List<Expense> expenses;
  final ValueChanged<Expense> onExpenseTap;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final Future<void> Function()? onLoadMore;

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  late final ScrollController _scrollController;
  bool _loadRequestInFlight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320.h) {
      return;
    }

    _requestNextPage();
  }

  Future<void> _requestNextPage() async {
    if (_loadRequestInFlight ||
        widget.isLoadingMore ||
        !widget.hasMore ||
        widget.onLoadMore == null) {
      return;
    }

    _loadRequestInFlight = true;

    try {
      await widget.onLoadMore!();
    } finally {
      _loadRequestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPaginationFooter =
        widget.hasMore ||
        widget.isLoadingMore ||
        widget.loadMoreErrorMessage != null;
    final itemCount = widget.expenses.length + (showPaginationFooter ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 8.h, bottom: 96.h),
      itemCount: itemCount,
      separatorBuilder: (_, index) {
        if (index >= widget.expenses.length - 1) {
          return const SizedBox.shrink();
        }

        return Divider(height: 1.h, indent: 72.w);
      },
      itemBuilder: (context, index) {
        if (index == widget.expenses.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: widget.isLoadingMore
                  ? SizedBox(
                      width: 24.r,
                      height: 24.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : widget.loadMoreErrorMessage != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.loadMoreErrorMessage!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 4.h),
                        TextButton(
                          onPressed: _requestNextPage,
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : TextButton.icon(
                      onPressed: _requestNextPage,
                      icon: Icon(Icons.expand_more, size: 20.r),
                      label: const Text('Load more'),
                    ),
            ),
          );
        }

        final expense = widget.expenses[index];

        return ExpenseListItem(
          expense: expense,
          onTap: () => widget.onExpenseTap(expense),
        );
      },
    );
  }
}
