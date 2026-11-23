import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import 'models/recurring_bill_model.dart';

/// CRUD for recurring bills.
class RecurringBillRepository {
  final SupabaseClient _client;

  RecurringBillRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<RecurringBillModel>> getBills() async {
    final response = await _client
        .from(SupabaseConstants.recurringBillsTable)
        .select()
        .eq('user_id', _userId)
        .order('due_day');

    return (response as List)
        .map((e) => RecurringBillModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringBillModel> createBill({
    required String name,
    required double amount,
    required String category,
    required int dueDay,
  }) async {
    final response = await _client
        .from(SupabaseConstants.recurringBillsTable)
        .insert({
          'user_id': _userId,
          'name': name,
          'amount': amount,
          'category': category,
          'due_day': dueDay,
        })
        .select()
        .single();

    return RecurringBillModel.fromJson(response);
  }

  Future<RecurringBillModel> updateBill(RecurringBillModel bill) async {
    final response = await _client
        .from(SupabaseConstants.recurringBillsTable)
        .update({
          'name': bill.name,
          'amount': bill.amount,
          'category': bill.category,
          'due_day': bill.dueDay,
          'is_active': bill.isActive,
        })
        .eq('id', bill.id)
        .eq('user_id', _userId)
        .select()
        .single();

    return RecurringBillModel.fromJson(response);
  }

  Future<void> deleteBill(String id) async {
    await _client
        .from(SupabaseConstants.recurringBillsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
