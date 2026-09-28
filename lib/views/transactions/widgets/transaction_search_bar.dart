import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionSearchBar extends StatefulWidget {
  const TransactionSearchBar({
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<TransactionSearchBar> createState() => _TransactionSearchBarState();
}

class _TransactionSearchBarState extends State<TransactionSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant TransactionSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searchQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: 'Search transactions',
      leading: Icon(Icons.search, size: 22.r),
      onChanged: (query) {
        widget.onChanged(query);
        setState(() {});
      },
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            onPressed: _clearSearch,
            tooltip: 'Clear search',
            icon: Icon(Icons.close, size: 20.r),
          ),
      ],
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16.w)),
    );
  }
}
