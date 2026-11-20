import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../expenses/data/models/expense_model.dart';

/// Repository for expense CRUD operations.
class ExpenseRepository {
  final SupabaseClient _client;

  ExpenseRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Add a new expense/income.
  Future<ExpenseModel> addExpense({
    required double amount,
    required String category,
    String? note,
    DateTime? date,
    String type = 'expense',
  }) async {
    final data = {
      'user_id': _userId,
      'amount': amount,
      'category': category,
      'note': note,
      'expense_date': (date ?? DateTime.now()).toIso8601String().split('T').first,
      'type': type,
    };

    final response = await _client
        .from(SupabaseConstants.expensesTable)
        .insert(data)
        .select()
        .single();

    return ExpenseModel.fromJson(response);
  }

  /// Get all expenses for the current month.
  Future<List<ExpenseModel>> getCurrentMonthExpenses(int cycleStartDay) async {
    final now = DateTime.now();
    final startOfMonth = AppDateUtils.startOfCycle(now, cycleStartDay);
    final endOfMonth = AppDateUtils.endOfCycle(now, cycleStartDay);

    final response = await _client
        .from(SupabaseConstants.expensesTable)
        .select()
        .eq('user_id', _userId)
        .gte('expense_date', startOfMonth.toIso8601String().split('T').first)
        .lte('expense_date', endOfMonth.toIso8601String().split('T').first)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get expenses for a specific month/year.
  Future<List<ExpenseModel>> getExpensesForMonth(int month, int year, int cycleStartDay) async {
    final startOfMonth = DateTime(year, month, cycleStartDay);
    final endOfMonth = DateTime(year, month + 1, cycleStartDay).subtract(const Duration(seconds: 1));

    final response = await _client
        .from(SupabaseConstants.expensesTable)
        .select()
        .eq('user_id', _userId)
        .gte('expense_date', startOfMonth.toIso8601String().split('T').first)
        .lte('expense_date', endOfMonth.toIso8601String().split('T').first)
        .order('expense_date', ascending: false);

    return (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get expenses for a date range.
  Future<List<ExpenseModel>> getExpensesInRange(
      DateTime start, DateTime end) async {
    final response = await _client
        .from(SupabaseConstants.expensesTable)
        .select()
        .eq('user_id', _userId)
        .gte('expense_date', start.toIso8601String().split('T').first)
        .lte('expense_date', end.toIso8601String().split('T').first)
        .order('expense_date', ascending: false);

    return (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Delete an expense.
  Future<void> deleteExpense(String id) async {
    await _client
        .from(SupabaseConstants.expensesTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Update an expense.
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final response = await _client
        .from(SupabaseConstants.expensesTable)
        .update({
          'amount': expense.amount,
          'category': expense.category,
          'note': expense.note,
          'expense_date':
              expense.expenseDate.toIso8601String().split('T').first,
          'type': expense.type,
        })
        .eq('id', expense.id)
        .eq('user_id', _userId)
        .select()
        .single();

    return ExpenseModel.fromJson(response);
  }

  /// Get total spent this month (expenses only).
  Future<double> getTotalSpentThisMonth([int cycleStartDay = 1]) async {
    final expenses = await getCurrentMonthExpenses(cycleStartDay);
    return expenses
        .where((e) => e.type == 'expense')
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Get expenses grouped by category for current month.
  Future<Map<String, double>> getCategoryBreakdown([int cycleStartDay = 1]) async {
    final expenses = await getCurrentMonthExpenses(cycleStartDay);
    final breakdown = <String, double>{};
    for (final expense in expenses) {
      if (expense.type == 'expense') {
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0) + expense.amount;
      }
    }
    return breakdown;
  }

  /// Get last N months of expenses (for recurring detection).
  Future<List<ExpenseModel>> getLastNMonthsExpenses(int months) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months, 1);

    final response = await _client
        .from(SupabaseConstants.expensesTable)
        .select()
        .eq('user_id', _userId)
        .gte('expense_date', start.toIso8601String().split('T').first)
        .order('expense_date', ascending: false);

    return (response as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
