import '../../expenses/data/models/expense_model.dart';

/// Spending in one category this cycle, with the same point last cycle.
class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.amount,
    required this.count,
    required this.share,
    this.previous,
  });

  final String category;
  final double amount;
  final int count;

  /// Fraction of this cycle's total spending (0–1).
  final double share;

  /// Spent in this category by the same day last cycle. Null when last
  /// cycle's data isn't available.
  final double? previous;

  /// Change vs last cycle as a fraction (0.24 = 24% more). Null when there's
  /// nothing to compare with.
  double? get change =>
      previous == null || previous! <= 0 ? null : (amount - previous!) / previous!;
}

/// Figures for the Insights tab, worked out from one cycle's transactions.
///
/// "Everyday" spending leaves out bill payments, matching the home screen:
/// bills are set aside up front, so pace and projections only look at what's
/// left after them.
class CycleAnalytics {
  const CycleAnalytics({
    required this.start,
    required this.totalDays,
    required this.daysElapsed,
    required this.isCurrent,
    required this.hasBudget,
    required this.spendableBudget,
    required this.savingsGoal,
    required this.totalSpent,
    required this.everydaySpent,
    required this.income,
    required this.paidBills,
    required this.upcomingBills,
    required this.cumulative,
    required this.categories,
    required this.previousToDate,
    required this.biggestDay,
    required this.noSpendDays,
    required this.mostFrequent,
  });

  /// First day of the cycle.
  final DateTime start;
  final int totalDays;

  /// Days counted so far: up to and including today for the current cycle,
  /// every day for a past one, 0 for one that hasn't started.
  final int daysElapsed;
  final bool isCurrent;

  final bool hasBudget;
  final double spendableBudget;
  final double savingsGoal;

  final double totalSpent;
  final double everydaySpent;
  final double income;
  final double paidBills;
  final double upcomingBills;

  /// Running total of everyday spending at the end of each counted day.
  final List<double> cumulative;

  /// Biggest first.
  final List<CategoryStat> categories;

  /// Last cycle's total spending by the same day, or null if unknown.
  final double? previousToDate;

  final ({DateTime day, double amount})? biggestDay;

  /// Days with no everyday spending. Today isn't counted until it's over.
  final int noSpendDays;
  final ({String category, int count})? mostFrequent;

  bool get isFuture => daysElapsed == 0;
  int get daysLeftAfterToday => isCurrent ? totalDays - daysElapsed : 0;

  /// Budget for everyday spending: budget + income − bills.
  double get everydayBudget => spendableBudget + income - paidBills - upcomingBills;

  double get averageDaily => daysElapsed > 0 ? everydaySpent / daysElapsed : 0;

  /// What an even pace would have spent by now.
  double get evenPaceToDate =>
      totalDays > 0 ? everydayBudget * daysElapsed / totalDays : 0;

  /// Positive when spending is behind an even pace (good).
  double get paceDelta => evenPaceToDate - everydaySpent;

  /// Everyday spending by the end of the cycle at the current daily average.
  double get projectedSpend => everydaySpent + averageDaily * daysLeftAfterToday;

  /// Left over at the end of the cycle (negative = overspent). For a past
  /// cycle this is the actual result.
  double get projectedLeftover => everydayBudget - projectedSpend;

  /// Total saved by the end of the cycle: the savings goal plus anything
  /// left over. Negative when spending runs past the whole allowance.
  double get projectedSavings => savingsGoal + projectedLeftover;

  /// For the current cycle: the day the budget runs out at this pace, or
  /// null if it lasts the whole cycle.
  DateTime? get runOutDay {
    if (!isCurrent || averageDaily <= 0 || projectedLeftover >= 0) return null;
    final left = everydayBudget - everydaySpent;
    final today = _addDays(start, daysElapsed - 1);
    if (left <= 0) return today;
    return _addDays(today, (left / averageDaily).floor());
  }

  /// Change in total spending vs the same point last cycle, as a fraction.
  double? get changeVsPrevious => previousToDate == null || previousToDate! <= 0
      ? null
      : (totalSpent - previousToDate!) / previousToDate!;

  factory CycleAnalytics.compute({
    required List<ExpenseModel> expenses,
    required DateTime cycleStart,
    required DateTime cycleEnd,
    required DateTime now,
    double? spendableBudget,
    double savingsGoal = 0,
    double upcomingBills = 0,
    List<ExpenseModel>? previousExpenses,
    DateTime? previousStart,
  }) {
    final start = _dateOnly(cycleStart);
    final end = _dateOnly(cycleEnd);
    final today = _dateOnly(now);
    final totalDays = _daysBetween(start, end) + 1;
    final isCurrent = !today.isBefore(start) && !today.isAfter(end);
    final daysElapsed = today.isBefore(start)
        ? 0
        : isCurrent
            ? _daysBetween(start, today) + 1
            : totalDays;

    double sum(Iterable<ExpenseModel> list) => list.fold(0.0, (s, e) => s + e.amount);
    final spending = expenses.where((e) => e.isExpense).toList();
    final everyday = expenses.where((e) => e.isEverydaySpend).toList();

    // Everyday spending per cycle day.
    final daily = List.filled(totalDays, 0.0);
    final dailyCount = List.filled(totalDays, 0);
    for (final e in everyday) {
      final i = _daysBetween(start, _dateOnly(e.expenseDate));
      if (i >= 0 && i < totalDays) {
        daily[i] += e.amount;
        dailyCount[i]++;
      }
    }
    final cumulative = <double>[];
    var running = 0.0;
    for (var i = 0; i < daysElapsed; i++) {
      running += daily[i];
      cumulative.add(running);
    }

    ({DateTime day, double amount})? biggest;
    for (var i = 0; i < daysElapsed; i++) {
      if (daily[i] > 0 && (biggest == null || daily[i] > biggest.amount)) {
        biggest = (day: _addDays(start, i), amount: daily[i]);
      }
    }
    final finishedDays = isCurrent ? daysElapsed - 1 : daysElapsed;
    var noSpend = 0;
    for (var i = 0; i < finishedDays; i++) {
      if (dailyCount[i] == 0) noSpend++;
    }

    // Last cycle, cut off at the same day so a part-finished cycle compares
    // fairly with a finished one.
    List<ExpenseModel>? previousToDateList;
    if (previousExpenses != null && previousStart != null) {
      final pStart = _dateOnly(previousStart);
      previousToDateList = previousExpenses.where((e) {
        if (!e.isExpense) return false;
        final i = _daysBetween(pStart, _dateOnly(e.expenseDate));
        return i >= 0 && i < daysElapsed;
      }).toList();
    }

    final byCategory = <String, (double, int)>{};
    for (final e in spending) {
      final (amount, count) = byCategory[e.category] ?? (0.0, 0);
      byCategory[e.category] = (amount + e.amount, count + 1);
    }
    final previousByCategory = <String, double>{};
    for (final e in previousToDateList ?? const <ExpenseModel>[]) {
      previousByCategory.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final totalSpent = sum(spending);
    final categories = [
      for (final entry in byCategory.entries)
        CategoryStat(
          category: entry.key,
          amount: entry.value.$1,
          count: entry.value.$2,
          share: totalSpent > 0 ? entry.value.$1 / totalSpent : 0,
          previous: previousToDateList == null ? null : previousByCategory[entry.key] ?? 0,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    final everydayCounts = <String, int>{};
    for (final e in everyday) {
      everydayCounts.update(e.category, (v) => v + 1, ifAbsent: () => 1);
    }
    final frequent = everydayCounts.entries.isEmpty
        ? null
        : (everydayCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    return CycleAnalytics(
      start: start,
      totalDays: totalDays,
      daysElapsed: daysElapsed,
      isCurrent: isCurrent,
      hasBudget: spendableBudget != null && spendableBudget > 0,
      spendableBudget: spendableBudget ?? 0,
      savingsGoal: savingsGoal,
      totalSpent: totalSpent,
      everydaySpent: sum(everyday),
      income: sum(expenses.where((e) => e.isIncome)),
      paidBills: sum(expenses.where((e) => e.isBillPayment)),
      upcomingBills: isCurrent ? upcomingBills : 0,
      cumulative: cumulative,
      categories: categories,
      previousToDate: previousToDateList == null ? null : sum(previousToDateList),
      biggestDay: biggest,
      noSpendDays: noSpend,
      mostFrequent: frequent == null ? null : (category: frequent.key, count: frequent.value),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Whole days from [a] to [b], unaffected by daylight-saving changes.
int _daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
