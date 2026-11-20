import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/math_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/expenses/data/expense_repository.dart';
import '../../../features/expenses/data/models/expense_model.dart';
import '../../../features/expenses/providers/expense_provider.dart';

/// Provider for insights data.
final insightsProvider =
    StateNotifierProvider<InsightsNotifier, AsyncValue<InsightsData>>((ref) {
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final expensesAsync = ref.watch(selectedMonthExpensesProvider);
  
  return InsightsNotifier(
    expenseRepo: expenseRepo,
    supabaseClient: supabaseClient,
    cycleStartDay: cycleStartDay,
    selectedMonth: selectedMonth,
    expensesAsync: expensesAsync,
  );
});

class InsightsData {
  // Weekly summary
  final double thisWeekSpent;
  final double lastWeekSpent;
  final double weeklyChange;
  final String topCategoryThisWeek;

  // Category breakdown
  final Map<String, double> categoryBreakdown;
  final double totalSpent;

  // Prediction & Metrics
  final double predictedEndBalance;
  final double avgDailySpend;
  final double monthlyAllowance;
  final double savingsGoal;
  final double spendableBudget;
  final double spendPercentage;

  // Recurring
  final List<RecurringExpense> recurringExpenses;

  // Daily spending (for chart)
  final List<DailySpend> dailySpending;

  const InsightsData({
    required this.thisWeekSpent,
    required this.lastWeekSpent,
    required this.weeklyChange,
    required this.topCategoryThisWeek,
    required this.categoryBreakdown,
    required this.totalSpent,
    required this.predictedEndBalance,
    required this.avgDailySpend,
    required this.monthlyAllowance,
    required this.savingsGoal,
    required this.spendableBudget,
    required this.spendPercentage,
    required this.recurringExpenses,
    required this.dailySpending,
  });

  factory InsightsData.empty() => const InsightsData(
        thisWeekSpent: 0,
        lastWeekSpent: 0,
        weeklyChange: 0,
        topCategoryThisWeek: '-',
        categoryBreakdown: {},
        totalSpent: 0,
        predictedEndBalance: 0,
        avgDailySpend: 0,
        monthlyAllowance: 0,
        savingsGoal: 0,
        spendableBudget: 0,
        spendPercentage: 0,
        recurringExpenses: [],
        dailySpending: [],
      );
}

class RecurringExpense {
  final String category;
  final double avgMonthlyAmount;
  final int monthsDetected;

  const RecurringExpense({
    required this.category,
    required this.avgMonthlyAmount,
    required this.monthsDetected,
  });
}

class DailySpend {
  final DateTime date;
  final double amount;

  const DailySpend({required this.date, required this.amount});
}

class InsightsNotifier extends StateNotifier<AsyncValue<InsightsData>> {
  final ExpenseRepository _repo;
  final SupabaseClient _client;
  final int cycleStartDay;
  final DateTime selectedMonth;
  final AsyncValue<List<ExpenseModel>> expensesAsync;

  InsightsNotifier({
    required ExpenseRepository expenseRepo,
    required SupabaseClient supabaseClient,
    required this.cycleStartDay,
    required this.selectedMonth,
    required this.expensesAsync,
  })  : _repo = expenseRepo,
        _client = supabaseClient,
        super(const AsyncValue.loading()) {
    loadInsights();
  }

  Future<void> loadInsights() async {
    if (expensesAsync is AsyncLoading) {
      state = const AsyncValue.loading();
      return;
    }
    if (expensesAsync is AsyncError) {
      state = AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
      return;
    }

    final expenses = expensesAsync.value ?? [];

    state = const AsyncValue.loading();
    try {
      // Fetch budget for selected month
      MonthlyBudgetModel? budget;
      try {
        final response = await _client
            .from('monthly_budgets')
            .select()
            .eq('user_id', _client.auth.currentUser!.id)
            .eq('month', selectedMonth.month)
            .eq('year', selectedMonth.year)
            .single();
        budget = MonthlyBudgetModel.fromJson(response);
      } catch (_) {}

      // Calculate total spent and income
      final totalSpent = expenses
          .where((e) => e.type == 'expense')
          .fold<double>(0, (sum, e) => sum + e.amount);
      final totalIncome = expenses
          .where((e) => e.type == 'income')
          .fold<double>(0, (sum, e) => sum + e.amount);

      // Weekly calculations
      final now = DateTime.now();
      final isCurrent = selectedMonth.month == now.month && selectedMonth.year == now.year;

      double thisWeekSpent = 0;
      double lastWeekSpent = 0;
      String topCat = '-';

      if (isCurrent) {
        final weekStart = AppDateUtils.startOfCurrentWeek();
        final lastWeekStart = AppDateUtils.startOfLastWeek();
        final lastWeekEnd = AppDateUtils.endOfLastWeek();

        final thisWeekExpenses = expenses
            .where((e) => e.type == 'expense' && (e.expenseDate.isAfter(weekStart) ||
                e.expenseDate.isAtSameMomentAs(weekStart)))
            .toList();

        thisWeekSpent = thisWeekExpenses.fold<double>(0, (s, e) => s + e.amount);

        double lwSpent = 0;
        try {
          final lastWeekExpenses = await _repo.getExpensesInRange(
              lastWeekStart, lastWeekEnd);
          lwSpent = lastWeekExpenses
              .where((e) => e.type == 'expense')
              .fold<double>(0, (s, e) => s + e.amount);
        } catch (_) {}
        lastWeekSpent = lwSpent;

        // Top category this week
        final weekCats = <String, double>{};
        for (final e in thisWeekExpenses) {
          weekCats[e.category] = (weekCats[e.category] ?? 0) + e.amount;
        }
        topCat = weekCats.entries.isEmpty
            ? '-'
            : (weekCats.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;
      }

      // Category breakdown (expenses only)
      final catBreakdown = <String, double>{};
      for (final e in expenses) {
        if (e.type == 'expense') {
          catBreakdown[e.category] =
              (catBreakdown[e.category] ?? 0) + e.amount;
        }
      }

      // Daily spending for chart (expenses only)
      final dailyMap = <String, double>{};
      for (final e in expenses) {
        if (e.type == 'expense') {
          final key = e.expenseDate.toIso8601String().split('T').first;
          dailyMap[key] = (dailyMap[key] ?? 0) + e.amount;
        }
      }
      final dailySpending = dailyMap.entries
          .map((e) =>
              DailySpend(date: DateTime.parse(e.key), amount: e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Recurring expense detection
      List<RecurringExpense> recurring = [];
      try {
        final allExpenses = await _repo.getLastNMonthsExpenses(3);
        final onlyExpenses = allExpenses.where((e) => e.type == 'expense').toList();
        recurring = _detectRecurring(onlyExpenses);
      } catch (_) {}

      // Calculate monthly metrics
      final allowance = budget?.monthlyAllowance ?? 0.0;
      final savingsGoal = budget?.savingsGoal ?? 0.0;
      final spendable = budget?.spendableBudget ?? 0.0;
      final remaining = spendable + totalIncome - totalSpent;

      final double avgDailySpend;
      final double predicted;
      final double spendPct;

      if (isCurrent) {
        final daysLeft = AppDateUtils.daysRemainingInCycle(now, cycleStartDay);
        final daysElapsed = AppDateUtils.daysElapsedInCycle(now, cycleStartDay);
        avgDailySpend = MathUtils.averageDailySpend(totalSpent, daysElapsed);
        spendPct = MathUtils.spendPercentage(totalSpent, spendable);
        predicted = MathUtils.predictedMonthEndBalance(
          remainingBalance: remaining,
          avgDailySpend: avgDailySpend,
          daysRemaining: daysLeft,
        );
      } else {
        avgDailySpend = totalSpent / AppDateUtils.daysInCycle(selectedMonth, cycleStartDay);
        spendPct = spendable > 0 ? (totalSpent / spendable) : 0.0;
        predicted = remaining;
      }

      state = AsyncValue.data(InsightsData(
        thisWeekSpent: thisWeekSpent,
        lastWeekSpent: lastWeekSpent,
        weeklyChange: MathUtils.percentageChange(thisWeekSpent, lastWeekSpent),
        topCategoryThisWeek: topCat,
        categoryBreakdown: catBreakdown,
        totalSpent: totalSpent,
        predictedEndBalance: predicted,
        avgDailySpend: avgDailySpend,
        monthlyAllowance: allowance,
        savingsGoal: savingsGoal,
        spendableBudget: spendable,
        spendPercentage: spendPct,
        recurringExpenses: recurring,
        dailySpending: dailySpending,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<RecurringExpense> _detectRecurring(List<ExpenseModel> allExpenses) {
    final monthlyCategories = <String, Map<String, double>>{};
    for (final e in allExpenses) {
      final monthKey = '${e.expenseDate.year}-${e.expenseDate.month}';
      monthlyCategories.putIfAbsent(monthKey, () => {});
      monthlyCategories[monthKey]![e.category] =
          (monthlyCategories[monthKey]![e.category] ?? 0) + e.amount;
    }

    final categoryMonths = <String, List<double>>{};
    for (final monthData in monthlyCategories.values) {
      for (final entry in monthData.entries) {
        categoryMonths.putIfAbsent(entry.key, () => []);
        categoryMonths[entry.key]!.add(entry.value);
      }
    }

    return categoryMonths.entries
        .where((e) => e.value.length >= 2)
        .map((e) => RecurringExpense(
              category: e.key,
              avgMonthlyAmount:
                  e.value.reduce((a, b) => a + b) / e.value.length,
              monthsDetected: e.value.length,
            ))
        .toList()
      ..sort((a, b) => b.avgMonthlyAmount.compareTo(a.avgMonthlyAmount));
  }
}

