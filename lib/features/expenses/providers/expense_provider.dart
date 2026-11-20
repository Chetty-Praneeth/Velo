import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/expense_repository.dart';
import '../data/models/expense_model.dart';

/// Provider for the ExpenseRepository.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(supabaseClientProvider));
});

/// Provider for current month's expenses.
final currentMonthExpensesProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<ExpenseModel>>>(
        (ref) {
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  return ExpenseListNotifier(
    ref.watch(expenseRepositoryProvider),
    ref: ref,
    cycleStartDay: cycleStartDay,
  );
});

/// Notifier for managing the expense list.
class ExpenseListNotifier
    extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final ExpenseRepository _repo;
  final Ref? ref;
  final int? month;
  final int? year;
  final int cycleStartDay;

  ExpenseListNotifier(
    this._repo, {
    this.ref,
    this.month,
    this.year,
    required this.cycleStartDay,
  }) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = (month != null && year != null)
          ? await _repo.getExpensesForMonth(month!, year!, cycleStartDay)
          : await _repo.getCurrentMonthExpenses(cycleStartDay);
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    String? note,
    DateTime? date,
    String type = 'expense',
  }) async {
    try {
      final newExpense = await _repo.addExpense(
        amount: amount,
        category: category,
        note: note,
        date: date,
        type: type,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([newExpense, ...current]);

      if (ref != null) {
        ref!.invalidate(currentMonthExpensesProvider);
        ref!.invalidate(selectedMonthExpensesProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repo.deleteExpense(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((e) => e.id != id).toList());

      if (ref != null) {
        ref!.invalidate(currentMonthExpensesProvider);
        ref!.invalidate(selectedMonthExpensesProvider);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for total spent this month (expenses only).
final totalSpentProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.when(
    data: (list) => list
        .where((e) => e.type == 'expense')
        .fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for total income this month.
final totalIncomeProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.when(
    data: (list) => list
        .where((e) => e.type == 'income')
        .fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for category breakdown (expenses only).
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.when(
    data: (list) {
      final breakdown = <String, double>{};
      for (final expense in list) {
        if (expense.type == 'expense') {
          breakdown[expense.category] =
              (breakdown[expense.category] ?? 0) + expense.amount;
        }
      }
      return breakdown;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider for recent expenses (last 5).
final recentExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.when(
    data: (list) => list.take(5).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for today's spent amount (expenses only).
final todaySpentProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.when(
    data: (list) {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      return list
          .where((e) =>
              e.type == 'expense' &&
              e.expenseDate.toIso8601String().split('T').first == todayStr)
          .fold<double>(0, (sum, e) => sum + e.amount);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ─── Selected Month Providers for Expenses Tab ────────────────

/// Tracks the selected month/year for filtering the expenses tab.
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provider for expenses of the selected month/year.
final selectedMonthExpensesProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<ExpenseModel>>>(
        (ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  return ExpenseListNotifier(
    ref.watch(expenseRepositoryProvider),
    ref: ref,
    month: selectedMonth.month,
    year: selectedMonth.year,
    cycleStartDay: cycleStartDay,
  );
});

/// Provider for total spent in the selected month (expenses only).
final selectedMonthTotalSpentProvider = Provider<double>((ref) {
  final expenses = ref.watch(selectedMonthExpensesProvider);
  return expenses.when(
    data: (list) => list
        .where((e) => e.type == 'expense')
        .fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for total income in the selected month.
final selectedMonthTotalIncomeProvider = Provider<double>((ref) {
  final expenses = ref.watch(selectedMonthExpensesProvider);
  return expenses.when(
    data: (list) => list
        .where((e) => e.type == 'income')
        .fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for the budget model of the selected month/year.
final selectedMonthBudgetProvider =
    FutureProvider<MonthlyBudgetModel?>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('monthly_budgets')
        .select()
        .eq('user_id', client.auth.currentUser!.id)
        .eq('month', selectedMonth.month)
        .eq('year', selectedMonth.year)
        .single();
    return MonthlyBudgetModel.fromJson(response);
  } catch (_) {
    return null;
  }
});

