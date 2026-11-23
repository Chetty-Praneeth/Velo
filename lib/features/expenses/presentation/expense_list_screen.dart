import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/bounceable.dart';
import '../../../core/widgets/home_style.dart';
import '../providers/expense_provider.dart';
import '../data/models/expense_model.dart';
import 'month_picker.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));
DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
double _sum(Iterable<ExpenseModel> list) => list.fold(0.0, (s, e) => s + e.amount);

final _dayMonth = DateFormat('d MMM');
final _weekdayDayMonth = DateFormat('EEE d MMM');

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  TxnFilter _filter = TxnFilter.all;
  String? _query; // null when the search field is closed
  final _searchController = TextEditingController();

  // Swiped-away rows, hidden at once while the delete request runs.
  final _dismissed = <String>{};

  DateTime? _weekStart; // Monday shown in the chart; null = default for the cycle
  DateTime? _selectedDay; // day tapped in the chart

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      if (_query == null) {
        _query = '';
      } else {
        _query = null;
        _searchController.clear();
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _delete(ExpenseModel e) {
    setState(() => _dismissed.add(e.id));
    ref.read(selectedMonthExpensesProvider.notifier).deleteExpense(e.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedMonthProvider, (_, __) {
      setState(() {
        _weekStart = null;
        _selectedDay = null;
      });
    });

    final csd = ref.watch(cycleStartDayProvider);
    final selected = ref.watch(selectedMonthProvider);
    // Same range the repository loads for the selected month.
    final cycleStart = DateTime(selected.year, selected.month, csd);
    final cycleEnd = DateTime(selected.year, selected.month + 1, csd - 1);
    final today = _dateOnly(DateTime.now());
    final isCurrent = !today.isBefore(cycleStart) && !today.isAfter(cycleEnd);

    final anchor = isCurrent ? today : (cycleStart.isAfter(today) ? cycleStart : cycleEnd);
    final weekStart = _weekStart ?? _mondayOf(anchor);
    final thisMonday = _mondayOf(today);

    final expensesAsync = ref.watch(selectedMonthExpensesProvider);
    final all = (expensesAsync.valueOrNull ?? const <ExpenseModel>[])
        .where((e) => !_dismissed.contains(e.id))
        .toList();
    final budget = ref.watch(selectedMonthBudgetProvider).valueOrNull;

    final selectedDay = _selectedDay;
    final dayList = selectedDay == null
        ? null
        : (ref.watch(weekExpensesProvider(weekStart)).valueOrNull ?? const <ExpenseModel>[])
            .where((e) => _sameDay(e.expenseDate, selectedDay) && !_dismissed.contains(e.id))
            .toList();

    final monthName = AppDateUtils.monthName(selected.month);

    return DarkSheetPage(
      header: [
        HomeTopBar(
          center: MonthPill(
            month: selected,
            onTap: () => showCycleMonthPicker(context, ref, current: selected, cycleStartDay: csd),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SpentHero(
            title: isCurrent ? 'Spent this cycle' : 'Spent in $monthName',
            spent: _sum(all.where((e) => e.isExpense)),
            income: _sum(all.where((e) => e.isIncome)),
            budget: budget?.spendableBudget ?? 0,
            range: '${_dayMonth.format(cycleStart)} – ${_dayMonth.format(cycleEnd)}',
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _WeekChart(
            weekStart: weekStart,
            today: today,
            selectedDay: selectedDay,
            onSelectDay: (d) => setState(() => _selectedDay = _sameDay(d, selectedDay ?? DateTime(0)) ? null : d),
            onPrev: () => setState(() {
              _weekStart = _addDays(weekStart, -7);
              _selectedDay = null;
            }),
            onNext: weekStart.isBefore(thisMonday)
                ? () => setState(() {
                      _weekStart = _addDays(weekStart, 7);
                      _selectedDay = null;
                    })
                : null,
          ),
        ),
      ],
      sheet: [
        SheetHeader(
          title: _filter.title,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
          searching: _query != null,
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _query = v),
          onToggleSearch: _toggleSearch,
        ),
        if (selectedDay != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Bounceable(
              onTap: () => setState(() => _selectedDay = null),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                decoration: BoxDecoration(
                  color: HomeColors.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Showing ${_weekdayDayMonth.format(selectedDay)}',
                        style: homeText(12, FontWeight.w600, HomeColors.inkSoft)),
                    const SizedBox(width: 4),
                    const Icon(Icons.close_rounded, size: 15, color: HomeColors.inkSoft),
                  ],
                ),
              ),
            ),
          ),
        if (dayList != null)
          _list(dayList, dayMode: true)
        else if (!expensesAsync.hasValue && expensesAsync.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.ink),
            ),
          )
        else if (!expensesAsync.hasValue && expensesAsync.hasError)
          SheetMessage(
            emoji: '⚠️',
            title: 'Couldn\'t load transactions',
            action: TextButton(
              onPressed: () => ref.read(selectedMonthExpensesProvider.notifier).loadExpenses(),
              child: Text('Try again', style: homeText(14, FontWeight.w600, HomeColors.ink)),
            ),
          )
        else
          _list(all, dayMode: false),
        // Room to scroll the last row clear of the + button.
        const SizedBox(height: 72),
      ],
    );
  }

  Widget _list(List<ExpenseModel> source, {required bool dayMode}) {
    final matches =
        source.where(_filter.matches).where((e) => matchesSearch(e, _query)).toList();

    if (matches.isEmpty) {
      final filtering = _filter != TxnFilter.all || (_query ?? '').trim().isNotEmpty;
      if (filtering) {
        return const SheetMessage(
          emoji: '🔍',
          title: 'Nothing matches',
          subtitle: 'Try a different search or filter.',
        );
      }
      return dayMode
          ? const SheetMessage(emoji: '📭', title: 'Nothing logged this day')
          : const SheetMessage(
              emoji: '🧾',
              title: 'No transactions in this cycle',
              subtitle: 'Tap + to add one.',
            );
    }

    // Group by day, newest first.
    final groups = <DateTime, List<ExpenseModel>>{};
    for (final e in matches) {
      groups.putIfAbsent(_dateOnly(e.expenseDate), () => []).add(e);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        for (final day in days) ...[
          if (!dayMode) _DayHeader(day: day, items: groups[day]!),
          for (final e in groups[day]!)
            TransactionRow(expense: e, showDate: false, onDismissed: () => _delete(e)),
        ],
      ],
    );
  }
}

// ─── Header pieces ────────────────────────────────────────────

class _SpentHero extends StatelessWidget {
  const _SpentHero({
    required this.title,
    required this.spent,
    required this.income,
    required this.budget,
    required this.range,
  });
  final String title;
  final double spent;
  final double income;
  final double budget;
  final String range;

  @override
  Widget build(BuildContext context) {
    final available = budget + income;
    final pct = available > 0 ? spent / available : 0.0;
    final left = available - spent;
    final color = pct <= 0.5
        ? AppColors.success
        : pct <= 0.75
            ? AppColors.warning
            : HomeColors.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        BigAmount(value: spent),
        const SizedBox(height: 4),
        Text(
          income > 0 ? '$range · +${CurrencyFormatter.format(income)} income' : range,
          style: homeText(13, FontWeight.w400, Colors.white.withValues(alpha: 0.45)),
        ),
        if (budget > 0) ...[
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${(pct * 100).round()}% of budget used',
                  style: homeText(12, FontWeight.w400, Colors.white.withValues(alpha: 0.6))),
              const Spacer(),
              Text(
                left >= 0
                    ? '${CurrencyFormatter.format(left)} left'
                    : '${CurrencyFormatter.format(-left)} over',
                style: homeText(12, FontWeight.w600,
                    left >= 0 ? Colors.white.withValues(alpha: 0.85) : HomeColors.danger),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Weekly spending chart ────────────────────────────────────

class _WeekChart extends ConsumerWidget {
  const _WeekChart({
    required this.weekStart,
    required this.today,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime weekStart;
  final DateTime today;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPrev;
  final VoidCallback? onNext; // null on the current week

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weekExpensesProvider(weekStart));
    final days = [for (var i = 0; i < 7; i++) _addDays(weekStart, i)];

    final totals = List.filled(7, 0.0);
    for (final e in async.valueOrNull ?? const <ExpenseModel>[]) {
      if (!e.isEverydaySpend) continue;
      final i = days.indexWhere((d) => _sameDay(d, e.expenseDate));
      if (i >= 0) totals[i] += e.amount;
    }
    final weekTotal = totals.fold(0.0, (a, b) => a + b);
    final peak = totals.reduce(math.max);
    final daysSoFar = days.where((d) => !d.isAfter(today)).length;

    final thisMonday = _mondayOf(today);
    final title = _sameDay(weekStart, thisMonday)
        ? 'This week'
        : _sameDay(weekStart, _addDays(thisMonday, -7))
            ? 'Last week'
            : '${_dayMonth.format(days.first)} – ${_dayMonth.format(days.last)}';

    return GlassTile(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(CurrencyFormatter.format(weekTotal),
                            style: homeText(22, FontWeight.w600, Colors.white)),
                        if (weekTotal > 0 && daysSoFar > 0) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${CurrencyFormatter.format(weekTotal / daysSoFar)}/day',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: homeText(12, FontWeight.w400,
                                  Colors.white.withValues(alpha: 0.45)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _ChevronButton(icon: Icons.chevron_left_rounded, label: 'Previous week', onTap: onPrev),
              const SizedBox(width: 6),
              _ChevronButton(icon: Icons.chevron_right_rounded, label: 'Next week', onTap: onNext),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: async.hasError && !async.hasValue
                ? Center(
                    child: Text('Couldn\'t load this week',
                        style: homeText(13, FontWeight.w400, Colors.white.withValues(alpha: 0.5))),
                  )
                : Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: _Bar(
                            day: days[i],
                            letter: _letters[i],
                            value: totals[i],
                            peak: peak,
                            isToday: _sameDay(days[i], today),
                            isSelected: selectedDay != null && _sameDay(days[i], selectedDay!),
                            isFuture: days[i].isAfter(today),
                            onTap: () => onSelectDay(days[i]),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap a day to see what you spent · bills not included',
            style: homeText(11, FontWeight.w400, Colors.white.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.letter,
    required this.value,
    required this.peak,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime day;
  final String letter;
  final double value;
  final double peak;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback onTap;

  static const _maxHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final height = isFuture || peak <= 0 ? 4.0 : math.max(4.0, value / peak * _maxHeight);
    final barColor = isSelected
        ? Colors.white
        : isToday
            ? AppColors.success
            : Colors.white.withValues(alpha: value > 0 ? 0.22 : 0.08);
    final strong = isSelected || isToday;
    final textColor = strong ? Colors.white : Colors.white.withValues(alpha: isFuture ? 0.25 : 0.5);

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label: '${DateFormat('EEEE d MMMM').format(day)}, ${CurrencyFormatter.format(value)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isFuture ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              value > 0 ? CurrencyFormatter.formatCompact(value) : '',
              maxLines: 1,
              style: homeText(9, FontWeight.w600, textColor),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 22,
              height: height,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            Text(letter, style: homeText(11, FontWeight.w600, textColor)),
            Text('${day.day}',
                style: homeText(10, FontWeight.w500,
                    strong ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Bounceable(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 20, color: Colors.white.withValues(alpha: onTap != null ? 0.85 : 0.25)),
        ),
      ),
    );
  }
}

// ─── Sheet pieces ─────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.items});
  final DateTime day;
  final List<ExpenseModel> items;

  @override
  Widget build(BuildContext context) {
    final spent = _sum(items.where((e) => e.isExpense));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Row(
        children: [
          Text(AppDateUtils.formatRelative(day),
              style: homeText(13, FontWeight.w600, HomeColors.inkSoft)),
          const Spacer(),
          if (spent > 0)
            Text('−${CurrencyFormatter.format(spent)}',
                style: homeText(12, FontWeight.w500, HomeColors.muted)),
        ],
      ),
    );
  }
}
