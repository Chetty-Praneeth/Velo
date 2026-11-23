import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/expenses/providers/expense_provider.dart';
import '../../../features/expenses/data/models/expense_model.dart';
import '../../bills/providers/recurring_bill_provider.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_state.dart';

export '../domain/dashboard_state.dart';

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

/// Provider that computes the full dashboard state from budget, expenses
/// and bills.
final dashboardStateProvider = Provider<DashboardState>((ref) {
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  final budgetAsync = ref.watch(currentBudgetProvider);
  final expenses =
      ref.watch(currentMonthExpensesProvider).valueOrNull ?? const [];
  final bills = ref.watch(billStatusesProvider);

  return budgetAsync.when(
    data: (budget) {
      if (budget == null) return DashboardState.empty();
      return DashboardState.compute(
        monthlyAllowance: budget.monthlyAllowance,
        savingsGoal: budget.savingsGoal,
        expenses: expenses,
        bills: bills,
        now: DateTime.now(),
        cycleStartDay: cycleStartDay,
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
