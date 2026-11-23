import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/home_style.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../expenses/data/models/expense_model.dart';
import '../../expenses/presentation/month_picker.dart';
import '../../expenses/providers/expense_provider.dart';
import '../domain/cycle_analytics.dart';

final _dayMonth = DateFormat('d MMM');
String _fmt(double v) => CurrencyFormatter.format(v);

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final csd = ref.watch(cycleStartDayProvider);
    final selected = ref.watch(selectedMonthProvider);
    // Same range the repository loads for the selected month.
    final cycleStart = DateTime(selected.year, selected.month, csd);
    final cycleEnd = DateTime(selected.year, selected.month + 1, csd - 1);
    final previousMonth = DateTime(selected.year, selected.month - 1);

    final expensesAsync = ref.watch(selectedMonthExpensesProvider);
    final budgetAsync = ref.watch(selectedMonthBudgetProvider);
    final previous = ref.watch(previousCycleExpensesProvider).valueOrNull;
    final dashboard = ref.watch(dashboardStateProvider);

    final topBar = HomeTopBar(
      center: MonthPill(
        month: selected,
        onTap: () => showCycleMonthPicker(context, ref, current: selected, cycleStartDay: csd),
      ),
    );

    if (!expensesAsync.hasValue || (!budgetAsync.hasValue && budgetAsync.isLoading)) {
      return DarkSheetPage(
        header: [
          topBar,
          const SizedBox(height: 120),
          if (expensesAsync.hasError)
            Center(
              child: Text('Couldn\'t load this cycle',
                  style: homeText(15, FontWeight.w500, Colors.white.withValues(alpha: 0.7))),
            )
          else
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          const SizedBox(height: 120),
        ],
        sheet: [
          if (expensesAsync.hasError)
            TextButton(
              onPressed: () => ref.read(selectedMonthExpensesProvider.notifier).loadExpenses(),
              child: Text('Try again', style: homeText(14, FontWeight.w600, HomeColors.ink)),
            ),
        ],
      );
    }

    final budget = budgetAsync.valueOrNull;
    final a = CycleAnalytics.compute(
      expenses: expensesAsync.value ?? const <ExpenseModel>[],
      cycleStart: cycleStart,
      cycleEnd: cycleEnd,
      now: DateTime.now(),
      spendableBudget: budget?.spendableBudget,
      savingsGoal: budget?.savingsGoal ?? 0,
      // Only used when the selected cycle is the current one.
      upcomingBills: dashboard.upcomingBills,
      previousExpenses: previous,
      previousStart: DateTime(previousMonth.year, previousMonth.month, csd),
    );
    final vsLabel = 'vs ${DateFormat('MMM').format(previousMonth)}';

    return DarkSheetPage(
      header: [
        topBar,
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _Hero(a: a, monthName: DateFormat('MMMM').format(selected)),
        ),
        if (!a.isFuture) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StatsRow(a: a, vsLabel: vsLabel, previousLoaded: previous != null),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CategoryDonut(a: a),
          ),
        ],
      ],
      sheet: [
        const SizedBox(height: 14),
        Text('Where your money went', style: homeText(17, FontWeight.w600, HomeColors.ink)),
        if (a.categories.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '${_fmt(a.totalSpent)} across ${a.categories.length} '
            '${a.categories.length == 1 ? 'category' : 'categories'}',
            style: homeText(12, FontWeight.w400, HomeColors.muted),
          ),
        ],
        const SizedBox(height: 6),
        if (a.categories.isEmpty)
          const SheetMessage(
            emoji: '📊',
            title: 'Nothing spent yet',
            subtitle: 'Your spending by category will show up here.',
          )
        else
          for (var i = 0; i < a.categories.length; i++)
            _CategoryRow(
              stat: a.categories[i],
              maxAmount: a.categories.first.amount,
              vsLabel: vsLabel,
              // Match the donut; categories in "Other" get a neutral bar.
              color: i < _sliceColors.length ? _sliceColors[i] : HomeColors.muted,
            ),
        if (!a.isFuture && a.everydaySpent > 0) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Highlights', style: homeText(15, FontWeight.w600, HomeColors.ink)),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Highlights(a: a),
          ),
        ],
        // Room to scroll clear of the + button.
        const SizedBox(height: 72),
      ],
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ─── Header ───────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.good});
  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.success : HomeColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(good ? Icons.check_circle_rounded : Icons.warning_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: homeText(12, FontWeight.w600, color)),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.a, required this.monthName});
  final CycleAnalytics a;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    final label = homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.7));
    final sub = homeText(13, FontWeight.w400, Colors.white.withValues(alpha: 0.45), height: 1.35);

    if (a.isFuture) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing to show yet', style: label),
          const SizedBox(height: 6),
          Text('This cycle starts on ${_dayMonth.format(a.start)}',
              style: homeText(22, FontWeight.w600, Colors.white)),
        ],
      );
    }

    if (!a.hasBudget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.isCurrent ? 'Spent this cycle' : 'Spent in $monthName', style: label),
          const SizedBox(height: 6),
          BigAmount(value: a.totalSpent),
          const SizedBox(height: 4),
          Text('Set a monthly budget to see projections', style: sub),
        ],
      );
    }

    // Total savings: the savings goal plus whatever's left over. A warning
    // only shows when spending is eating into the savings goal.
    final savings = a.projectedSavings;
    final overspending = a.projectedLeftover < 0;
    final shortOfGoal = '${_fmt(-a.projectedLeftover)} short of your ${_fmt(a.savingsGoal)} goal';
    final String title;
    final String detail;
    String? warning;
    if (a.isCurrent) {
      title = savings >= 0 ? 'Projected savings' : 'Projected overspend';
      final days = a.daysLeftAfterToday;
      detail = a.averageDaily <= 0
          ? 'Nothing spent so far this cycle'
          : 'If you keep spending ${_fmt(a.averageDaily)} a day'
              '${days > 0 ? ' for the next $days ${days == 1 ? 'day' : 'days'}' : ''}';
      if (overspending) {
        final runOut = a.runOutDay;
        warning = a.savingsGoal > 0 && savings >= 0
            ? shortOfGoal
            : runOut == null || !runOut.isAfter(_dateOnly(DateTime.now()))
                ? 'Budget already used up'
                : 'Budget runs out around ${_dayMonth.format(runOut)}';
      }
    } else {
      title = savings >= 0 ? 'Saved' : 'Overspent';
      detail = 'Spent ${_fmt(a.everydaySpent)} of ${_fmt(a.everydayBudget)} '
          'on everyday things';
      if (overspending) {
        warning = a.savingsGoal <= 0
            ? 'Went over budget'
            : savings < 0
                ? 'Savings goal missed'
                : shortOfGoal;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: label),
        const SizedBox(height: 6),
        BigAmount(value: savings.abs()),
        const SizedBox(height: 4),
        Text(detail, style: sub),
        if (warning != null) ...[
          const SizedBox(height: 12),
          _StatusChip(text: warning, good: false),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.a, required this.vsLabel, required this.previousLoaded});
  final CycleAnalytics a;
  final String vsLabel;
  final bool previousLoaded;

  @override
  Widget build(BuildContext context) {
    final change = a.changeVsPrevious;
    final String changeText;
    Color? changeColor;
    if (!previousLoaded) {
      changeText = '…';
    } else if (change == null) {
      changeText = '—';
    } else if (change.abs() < 0.005) {
      changeText = 'Same';
    } else {
      changeText = '${change > 0 ? '↑' : '↓'} ${(change.abs() * 100).round()}%';
      changeColor = change > 0 ? HomeColors.danger : AppColors.success;
    }

    return Row(
      children: [
        Expanded(child: _MiniStat(label: 'Daily average', value: _fmt(a.averageDaily))),
        const SizedBox(width: 10),
        Expanded(child: _MiniStat(label: vsLabel, value: changeText, color: changeColor)),
        const SizedBox(width: 10),
        Expanded(
          child: a.isCurrent
              ? _MiniStat(
                  label: 'Days left', value: '${a.totalDays - a.daysElapsed + 1}')
              : _MiniStat(label: 'Bills paid', value: _fmt(a.paidBills)),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: homeText(12, FontWeight.w400, Colors.white.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: homeText(17, FontWeight.w600, color ?? Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Category donut ───────────────────────────────────────────

const _sliceColors = [
  Color(0xFFFF6A2B),
  Color(0xFF3B8BFF),
  Color(0xFF8CE600),
  Color(0xFFFFD233),
  Color(0xFF8B6CFF),
];
const _otherSlice = Color(0x4DFFFFFF);

class _CategoryDonut extends StatefulWidget {
  const _CategoryDonut({required this.a});
  final CycleAnalytics a;

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int? _selected;

  void _toggle(int i) => setState(() => _selected = _selected == i ? null : i);

  @override
  Widget build(BuildContext context) {
    final cats = widget.a.categories;
    final total = widget.a.totalSpent;
    final top = math.min(cats.length, _sliceColors.length);
    final slices = <({String label, double amount, Color color})>[
      for (var i = 0; i < top; i++)
        (label: cats[i].category, amount: cats[i].amount, color: _sliceColors[i]),
      if (cats.length > top)
        (
          label: 'Other',
          amount: cats.skip(top).fold(0.0, (s, c) => s + c.amount),
          color: _otherSlice,
        ),
    ];
    final selected = _selected != null && _selected! < slices.length ? _selected : null;
    final focus = selected == null ? null : slices[selected];

    return GlassTile(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by category',
              style: homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.65))),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        centerSpaceRadius: 50,
                        sectionsSpace: slices.length > 1 ? 3 : 0,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (event is! FlTapUpEvent) return;
                            final i = response?.touchedSection?.touchedSectionIndex ?? -1;
                            if (i < 0 || i >= slices.length) {
                              setState(() => _selected = null);
                            } else {
                              _toggle(i);
                            }
                          },
                        ),
                        sections: slices.isEmpty
                            ? [
                                PieChartSectionData(
                                  value: 1,
                                  radius: 18,
                                  showTitle: false,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ]
                            : [
                                for (var i = 0; i < slices.length; i++)
                                  PieChartSectionData(
                                    value: slices[i].amount,
                                    radius: selected == i ? 24 : 18,
                                    showTitle: false,
                                    color: selected == null || selected == i
                                        ? slices[i].color
                                        : slices[i].color.withValues(alpha: 0.3),
                                  ),
                              ],
                      ),
                    ),
                    IgnorePointer(
                      child: SizedBox(
                        width: 84,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_fmt(focus?.amount ?? total),
                                  style: homeText(17, FontWeight.w600, Colors.white)),
                            ),
                            Text(
                              focus?.label ?? 'spent',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: homeText(11, FontWeight.w500,
                                  Colors.white.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: slices.isEmpty
                    ? Text('Nothing spent yet',
                        style: homeText(13, FontWeight.w500, Colors.white.withValues(alpha: 0.6)))
                    : Column(
                        children: [
                          for (var i = 0; i < slices.length; i++)
                            _LegendRow(
                              color: slices[i].color,
                              label: slices[i].label,
                              percent: total > 0 ? (slices[i].amount / total * 100).round() : 0,
                              dimmed: selected != null && selected != i,
                              onTap: () => _toggle(i),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.dimmed,
    required this.onTap,
  });
  final Color color;
  final String label;
  final int percent;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $percent percent',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.4 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: homeText(13, FontWeight.w500, Colors.white.withValues(alpha: 0.85))),
                ),
                const SizedBox(width: 6),
                Text('$percent%',
                    style: homeText(13, FontWeight.w600, Colors.white.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sheet ────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.stat,
    required this.maxAmount,
    required this.vsLabel,
    required this.color,
  });
  final CategoryStat stat;
  final double maxAmount;
  final String vsLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = stat;
    final muted = homeText(12, FontWeight.w400, HomeColors.muted);
    final change = c.change;
    final InlineSpan? changeSpan;
    if (c.previous == null) {
      changeSpan = null;
    } else if (change == null) {
      changeSpan = TextSpan(text: ' · New this cycle', style: muted);
    } else if (change.abs() < 0.005) {
      changeSpan = TextSpan(text: ' · Same as ${vsLabel.substring(3)}', style: muted);
    } else {
      changeSpan = TextSpan(
        text: ' · ${change > 0 ? '↑' : '↓'} ${(change.abs() * 100).round()}% $vsLabel',
        style: homeText(12, FontWeight.w600,
            change > 0 ? const Color(0xFFE5484D) : HomeColors.income),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          CategoryAvatar(category: c.category, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeText(15, FontWeight.w600, HomeColors.inkSoft)),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmt(c.amount), style: homeText(15, FontWeight.w600, HomeColors.ink)),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: maxAmount > 0 ? c.amount / maxAmount : 0,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: HomeColors.chip,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 36,
                      child: Text('${(c.share * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: homeText(12, FontWeight.w600, HomeColors.muted)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${c.count} ${c.count == 1 ? 'transaction' : 'transactions'}',
                        style: muted),
                    if (changeSpan != null) changeSpan,
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.a});
  final CycleAnalytics a;

  @override
  Widget build(BuildContext context) {
    final biggest = a.biggestDay;
    final frequent = a.mostFrequent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Highlight(
            label: 'Biggest day',
            value: biggest == null ? '—' : _fmt(biggest.amount),
            sub: biggest == null ? '' : DateFormat('EEE d MMM').format(biggest.day),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Highlight(
            label: 'No-spend days',
            value: '${a.noSpendDays}',
            sub: a.isCurrent ? 'so far' : 'this cycle',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Highlight(
            label: 'Most often',
            value: frequent?.category ?? '—',
            sub: frequent == null ? '' : '${frequent.count} times',
          ),
        ),
      ],
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.label, required this.value, required this.sub});
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: HomeColors.tile,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: homeText(11, FontWeight.w500, HomeColors.muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: homeText(17, FontWeight.w700, HomeColors.ink)),
          ),
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: homeText(11, FontWeight.w400, HomeColors.muted)),
        ],
      ),
    );
  }
}
