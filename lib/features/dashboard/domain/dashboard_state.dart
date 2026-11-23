import 'dart:math' as math;
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/math_utils.dart';
import '../../bills/domain/bill_status.dart';
import '../../expenses/data/models/expense_model.dart';

/// How today's daily limit differs from yesterday's, broken into causes.
///
/// Exact identity (n = days left including today):
///   today = yesterday + (yesterday − spentYesterday) / n + incomeToday / n
class LimitChange {
  /// Yesterday's limit, worked out with what's known now.
  final double yesterdayLimit;

  /// Everyday spending logged for yesterday.
  final double yesterdaySpent;

  /// Income dated today (or later) — it wasn't there yesterday.
  final double incomeSinceYesterday;

  final int daysLeft;

  const LimitChange({
    required this.yesterdayLimit,
    required this.yesterdaySpent,
    required this.incomeSinceYesterday,
    required this.daysLeft,
  });

  /// Positive = spent less than the limit, negative = went over.
  double get underBy => yesterdayLimit - yesterdaySpent;

  /// What yesterday's under/overspend adds to each remaining day.
  double get fromYesterday => underBy / daysLeft;

  /// What today's new income adds to each remaining day.
  double get fromIncome => incomeSinceYesterday / daysLeft;
}

/// Combined dashboard state — all derived metrics.
class DashboardState {
  final double monthlyAllowance;
  final double savingsGoal;
  final double spendableBudget;
  final double totalSpent;
  final double totalIncome;

  /// Everyday spending today. Bill payments don't count against the daily
  /// limit because they were already set aside.
  final double todaySpent;
  final double remainingBalance;
  final int daysRemaining;
  final int daysElapsed;

  /// Today's limit for everyday spending. Never negative.
  final double safeDailySpend;
  final double averageDailySpend;
  final double spendPercentage;
  final double predictedEndBalance;
  final bool isSavingsOnTrack;
  final double dailyReductionNeeded;
  final double monthProgress;

  /// Bill payments logged this cycle.
  final double paidBills;

  /// Bills still to pay this cycle — set aside up front.
  final double upcomingBills;

  /// Everyday spending this cycle before today.
  final double everydaySpentBeforeToday;

  /// Money left for everyday spending at the start of today. Split across
  /// [daysRemaining] to get [safeDailySpend]. Negative when over budget.
  final double availableFromToday;

  /// Why today's limit moved since yesterday. Null on the first day of the
  /// cycle or when the budget is used up.
  final LimitChange? limitChange;

  const DashboardState({
    required this.monthlyAllowance,
    required this.savingsGoal,
    required this.spendableBudget,
    required this.totalSpent,
    required this.totalIncome,
    required this.todaySpent,
    required this.remainingBalance,
    required this.daysRemaining,
    required this.daysElapsed,
    required this.safeDailySpend,
    required this.averageDailySpend,
    required this.spendPercentage,
    required this.predictedEndBalance,
    required this.isSavingsOnTrack,
    required this.dailyReductionNeeded,
    required this.monthProgress,
    this.paidBills = 0,
    this.upcomingBills = 0,
    this.everydaySpentBeforeToday = 0,
    this.availableFromToday = 0,
    this.limitChange,
  });

  factory DashboardState.empty() {
    return const DashboardState(
      monthlyAllowance: 0,
      savingsGoal: 0,
      spendableBudget: 0,
      totalSpent: 0,
      totalIncome: 0,
      todaySpent: 0,
      remainingBalance: 0,
      daysRemaining: 30,
      daysElapsed: 0,
      safeDailySpend: 0,
      averageDailySpend: 0,
      spendPercentage: 0,
      predictedEndBalance: 0,
      isSavingsOnTrack: true,
      dailyReductionNeeded: 0,
      monthProgress: 0,
    );
  }

  /// Bills paid + still to pay this cycle.
  double get billsThisCycle => paidBills + upcomingBills;

  /// Computes every dashboard metric for the cycle containing [now].
  ///
  /// [expenses] are the current cycle's transactions (expenses and income);
  /// [bills] are the bill statuses for the same cycle.
  ///
  /// Today's limit = (budget + income − bills − everyday spending before
  /// today) ÷ days left including today. It's fixed for the whole day, so
  /// spending today doesn't move the limit it's measured against.
  factory DashboardState.compute({
    required double monthlyAllowance,
    required double savingsGoal,
    required List<ExpenseModel> expenses,
    required List<BillStatus> bills,
    required DateTime now,
    required int cycleStartDay,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    bool on(ExpenseModel e, DateTime day) =>
        e.expenseDate.year == day.year &&
        e.expenseDate.month == day.month &&
        e.expenseDate.day == day.day;
    double sum(Iterable<ExpenseModel> xs) =>
        xs.fold<double>(0, (s, e) => s + e.amount);

    final spendable = monthlyAllowance - savingsGoal;
    final totalSpent = sum(expenses.where((e) => e.isExpense));
    final totalIncome = sum(expenses.where((e) => e.isIncome));
    final incomeBeforeToday = sum(expenses.where((e) =>
        e.isIncome &&
        DateTime(e.expenseDate.year, e.expenseDate.month, e.expenseDate.day)
            .isBefore(today)));

    final everyday = expenses.where((e) => e.isEverydaySpend);
    final everydaySpent = sum(everyday);
    final todaySpent = sum(everyday.where((e) => on(e, today)));
    final yesterdaySpent = sum(everyday.where((e) => on(e, yesterday)));
    final paidBills = sum(expenses.where((e) => e.isBillPayment));
    final upcomingBills =
        bills.fold<double>(0, (s, b) => s + b.reservedAmount);

    final remaining = spendable + totalIncome - totalSpent;
    // What's left for everyday spending once unpaid bills are set aside.
    final available = remaining - upcomingBills;
    final availableFromToday = available + todaySpent;

    final daysLeft = AppDateUtils.daysRemainingInCycle(now, cycleStartDay);
    final daysElapsed = AppDateUtils.daysElapsedInCycle(now, cycleStartDay);
    final rawLimit = MathUtils.safeDailySpend(availableFromToday, daysLeft);
    final safeDailySpend = math.max(0.0, rawLimit);

    LimitChange? limitChange;
    if (daysElapsed > 1 && daysLeft > 0 && rawLimit > 0) {
      final incomeSinceYesterday = totalIncome - incomeBeforeToday;
      final availableFromYesterday =
          availableFromToday - incomeSinceYesterday + yesterdaySpent;
      final yesterdayLimit = availableFromYesterday / (daysLeft + 1);
      if (yesterdayLimit > 0) {
        limitChange = LimitChange(
          yesterdayLimit: yesterdayLimit,
          yesterdaySpent: yesterdaySpent,
          incomeSinceYesterday: incomeSinceYesterday,
          daysLeft: daysLeft,
        );
      }
    }

    final avgDailySpend =
        MathUtils.averageDailySpend(everydaySpent, daysElapsed);
    final predicted = MathUtils.predictedMonthEndBalance(
      remainingBalance: available,
      avgDailySpend: avgDailySpend,
      daysRemaining: daysLeft,
    );

    return DashboardState(
      monthlyAllowance: monthlyAllowance,
      savingsGoal: savingsGoal,
      spendableBudget: spendable,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      todaySpent: todaySpent,
      remainingBalance: remaining,
      daysRemaining: daysLeft,
      daysElapsed: daysElapsed,
      safeDailySpend: safeDailySpend,
      averageDailySpend: avgDailySpend,
      spendPercentage: MathUtils.spendPercentage(totalSpent, spendable),
      predictedEndBalance: predicted,
      isSavingsOnTrack: predicted >= 0,
      dailyReductionNeeded: MathUtils.dailyReductionNeeded(
        remainingBalance: available,
        safeDailySpend: safeDailySpend,
        avgDailySpend: avgDailySpend,
      ),
      monthProgress: AppDateUtils.cycleProgress(now, cycleStartDay),
      paidBills: paidBills,
      upcomingBills: upcomingBills,
      everydaySpentBeforeToday: everydaySpent - todaySpent,
      availableFromToday: availableFromToday,
      limitChange: limitChange,
    );
  }
}
