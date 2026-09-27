import 'package:expense_tracker/extensions/expense_category_extension.dart';
import 'package:expense_tracker/models/category_expense_summary.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategorySpendingCard extends StatelessWidget {
  const CategorySpendingCard({
    required this.summaries,
    required this.total,
    super.key,
  });

  final List<CategoryExpenseSummary> summaries;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Breakdown for the selected month',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 20.h),
            if (summaries.isEmpty)
              const _EmptyCategorySummary()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final useHorizontalLayout = constraints.maxWidth >= 600;

                  if (useHorizontalLayout) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _CategoryDonutChart(
                            summaries: summaries,
                            total: total,
                          ),
                        ),
                        SizedBox(width: 28.w),
                        Expanded(
                          child: _CategoryLegend(
                            summaries: summaries,
                            total: total,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _CategoryDonutChart(
                        summaries: summaries,
                        total: total,
                      ),
                      SizedBox(height: 20.h),
                      _CategoryLegend(
                        summaries: summaries,
                        total: total,
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDonutChart extends StatelessWidget {
  const _CategoryDonutChart({
    required this.summaries,
    required this.total,
  });

  final List<CategoryExpenseSummary> summaries;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3.r,
              centerSpaceRadius: 58.r,
              startDegreeOffset: -90,
              sections: [
                for (var index = 0; index < summaries.length; index++)
                  PieChartSectionData(
                    value: summaries[index].total,
                    color: _categoryColor(
                      summaries[index].category,
                      colorScheme,
                    ),
                    radius: 30.r,
                    showTitle: false,
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: 108.w,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.formatLkr(total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.summaries,
    required this.total,
  });

  final List<CategoryExpenseSummary> summaries;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (var index = 0; index < summaries.length; index++) ...[
          _CategoryLegendItem(
            summary: summaries[index],
            color: _categoryColor(summaries[index].category, colorScheme),
            percentage: total == 0 ? 0 : summaries[index].total / total * 100,
          ),
          if (index != summaries.length - 1) SizedBox(height: 12.h),
        ],
      ],
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  const _CategoryLegendItem({
    required this.summary,
    required this.color,
    required this.percentage,
  });

  final CategoryExpenseSummary summary;
  final Color color;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Row(
            children: [
              Icon(summary.category.icon, size: 18.r),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  summary.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 120.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  CurrencyFormatter.formatLkr(summary.total),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCategorySummary extends StatelessWidget {
  const _EmptyCategorySummary();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 150.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.donut_large_outlined,
            size: 40.r,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'No spending data this month',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Color _categoryColor(
  ExpenseCategory category,
  ColorScheme colorScheme,
) {
  return switch (category) {
    ExpenseCategory.food => colorScheme.primary,
    ExpenseCategory.transport => colorScheme.tertiary,
    ExpenseCategory.shopping => colorScheme.secondary,
    ExpenseCategory.bills => colorScheme.error,
    ExpenseCategory.entertainment => colorScheme.primary.withValues(alpha: 0.65),
    ExpenseCategory.health => colorScheme.tertiary.withValues(alpha: 0.65),
    ExpenseCategory.education => colorScheme.secondary.withValues(alpha: 0.65),
    ExpenseCategory.other => colorScheme.error.withValues(alpha: 0.65),
  };
}
