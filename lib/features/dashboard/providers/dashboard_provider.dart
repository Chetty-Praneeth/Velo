import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/math_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/expenses/providers/expense_provider.dart';
import '../../../features/expenses/data/models/expense_model.dart';
import '../data/dashboard_repository.dart';

/// Provider for the DashboardRepository.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

/// Provider for current month's budget.
final currentBudgetProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<MonthlyBudgetModel?>>(
        (ref) {
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  return BudgetNotifier(ref.watch(dashboardRepositoryProvider), cycleStartDay);
});

class BudgetNotifier
    extends StateNotifier<AsyncValue<MonthlyBudgetModel?>> {
  final DashboardRepository _repo;
  final int cycleStartDay;

  BudgetNotifier(this._repo, this.cycleStartDay) : super(const AsyncValue.loading()) {
    loadBudget();
  }

  Future<void> loadBudget() async {
    state = const AsyncValue.loading();
    try {
      final budget = await _repo.getCurrentMonthBudget(cycleStartDay);
      state = AsyncValue.data(budget);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveBudget({
    required double monthlyAllowance,
    required double savingsGoal,
  }) async {
    try {
      final budget = await _repo.saveBudget(
        monthlyAllowance: monthlyAllowance,
        savingsGoal: savingsGoal,
        cycleStartDay: cycleStartDay,
      );
      state = AsyncValue.data(budget);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Combined dashboard state — all derived metrics.
class DashboardState {
  final double monthlyAllowance;
  final double savingsGoal;
  final double spendableBudget;
  final double totalSpent;
  final double totalIncome;
  final double todaySpent;
  final double remainingBalance;
  final int daysRemaining;
  final int daysElapsed;
  final double safeDailySpend;
  final double averageDailySpend;
  final double spendPercentage;
  final double predictedEndBalance;
  final bool isSavingsOnTrack;
  final double dailyReductionNeeded;
  final double monthProgress;

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
}

/// Provider that computes the full dashboard state from budget + expenses.
final dashboardStateProvider = Provider<DashboardState>((ref) {
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  final budgetAsync = ref.watch(currentBudgetProvider);
  final totalSpent = ref.watch(totalSpentProvider);
  final totalIncome = ref.watch(totalIncomeProvider);
  final todaySpent = ref.watch(todaySpentProvider);

  return budgetAsync.when(
    data: (budget) {
      if (budget == null) return DashboardState.empty();

      final spendable = budget.spendableBudget;
      final remaining = spendable + totalIncome - totalSpent;
      final daysLeft = AppDateUtils.daysRemainingInCycle(DateTime.now(), cycleStartDay);
      final daysElapsed = AppDateUtils.daysElapsedInCycle(DateTime.now(), cycleStartDay);
      final safeDailySpend =
          MathUtils.safeDailySpend(remaining, daysLeft);
      final avgDailySpend =
          MathUtils.averageDailySpend(totalSpent, daysElapsed);
      final spendPct =
          MathUtils.spendPercentage(totalSpent, spendable);
      final predicted = MathUtils.predictedMonthEndBalance(
        remainingBalance: remaining,
        avgDailySpend: avgDailySpend,
        daysRemaining: daysLeft,
      );
      final onTrack = MathUtils.isSavingsOnTrack(
        remainingBalance: remaining,
        avgDailySpend: avgDailySpend,
        daysRemaining: daysLeft,
      );
      final reductionNeeded = MathUtils.dailyReductionNeeded(
        remainingBalance: remaining,
        safeDailySpend: safeDailySpend,
        avgDailySpend: avgDailySpend,
      );

      return DashboardState(
        monthlyAllowance: budget.monthlyAllowance,
        savingsGoal: budget.savingsGoal,
        spendableBudget: spendable,
        totalSpent: totalSpent,
        totalIncome: totalIncome,
        todaySpent: todaySpent,
        remainingBalance: remaining,
        daysRemaining: daysLeft,
        daysElapsed: daysElapsed,
        safeDailySpend: safeDailySpend,
        averageDailySpend: avgDailySpend,
        spendPercentage: spendPct,
        predictedEndBalance: predicted,
        isSavingsOnTrack: onTrack,
        dailyReductionNeeded: reductionNeeded,
        monthProgress: AppDateUtils.cycleProgress(DateTime.now(), cycleStartDay),
      );
    },
    loading: () => DashboardState.empty(),
    error: (_, __) => DashboardState.empty(),
  );
});

/// Smart guidance messages.
final smartGuidanceProvider = Provider<List<String>>((ref) {
  final state = ref.watch(dashboardStateProvider);
  final messages = <String>[];

  if (state.spendableBudget == 0) return messages;

  // Extra income tip
  if (state.totalIncome > 0) {
    messages.add(
        'You added ₹${state.totalIncome.toStringAsFixed(0)} in extra income this month! This has boosted your Safe Daily Spend.');
  }

  // Over daily budget warning
  if (state.averageDailySpend > state.safeDailySpend &&
      state.daysElapsed > 1) {
    messages.add('You are spending above your daily budget of '
        '₹${state.safeDailySpend.toStringAsFixed(0)}.');
  }

  // Savings on track
  if (state.isSavingsOnTrack && state.daysElapsed > 3) {
    messages.add(
        'Great job! You\'re on track to save ₹${state.savingsGoal.toStringAsFixed(0)} this month. 🎉');
  }

  // Overspending warning
  if (!state.isSavingsOnTrack && state.daysElapsed > 1) {
    messages.add(
        'At your current spending rate, you may overshoot your budget by '
        '₹${state.predictedEndBalance.abs().toStringAsFixed(0)}.');
  }

  // Reduction tip
  if (state.dailyReductionNeeded > 0) {
    messages.add(
        'Reducing your daily spending by ₹${state.dailyReductionNeeded.toStringAsFixed(0)} '
        'will help you reach your savings goal.');
  }

  // Spend percentage warning
  if (state.spendPercentage >= 0.7 && state.spendPercentage < 0.9) {
    messages.add(
        'You\'ve used ${(state.spendPercentage * 100).toStringAsFixed(0)}% of your budget '
        'with ${state.daysRemaining} days remaining.');
  }

  if (state.spendPercentage >= 0.9) {
    messages.add(
        '⚠️ You\'ve used ${(state.spendPercentage * 100).toStringAsFixed(0)}% of your budget! '
        'Consider cutting back on non-essentials.');
  }

  return messages;
});
