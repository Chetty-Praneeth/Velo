import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../expenses/data/models/expense_model.dart';

/// Repository for dashboard data operations.
class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get or create the current month's budget.
  Future<MonthlyBudgetModel?> getCurrentMonthBudget(int cycleStartDay) async {
    final now = DateTime.now();
    final cycleStart = AppDateUtils.startOfCycle(now, cycleStartDay);
    try {
      final response = await _client
          .from(SupabaseConstants.monthlyBudgetsTable)
          .select()
          .eq('user_id', _userId)
          .eq('month', cycleStart.month)
          .eq('year', cycleStart.year)
          .single();

      return MonthlyBudgetModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Get budget for a specific month/year.
  Future<MonthlyBudgetModel?> getBudgetForMonth(int month, int year) async {
    try {
      final response = await _client
          .from(SupabaseConstants.monthlyBudgetsTable)
          .select()
          .eq('user_id', _userId)
          .eq('month', month)
          .eq('year', year)
          .single();

      return MonthlyBudgetModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Save monthly budget setup.
  Future<MonthlyBudgetModel> saveBudget({
    required double monthlyAllowance,
    required double savingsGoal,
    required int cycleStartDay,
  }) async {
    final now = DateTime.now();
    final cycleStart = AppDateUtils.startOfCycle(now, cycleStartDay);
    final data = {
      'user_id': _userId,
      'month': cycleStart.month,
      'year': cycleStart.year,
      'monthly_allowance': monthlyAllowance,
      'savings_goal': savingsGoal,
    };

    final response = await _client
        .from(SupabaseConstants.monthlyBudgetsTable)
        .upsert(data, onConflict: 'user_id,month,year')
        .select()
        .single();

    return MonthlyBudgetModel.fromJson(response);
  }

  /// Check if user has set up budget for current month.
  Future<bool> hasBudgetSetup(int cycleStartDay) async {
    final budget = await getCurrentMonthBudget(cycleStartDay);
    return budget != null;
  }
}
