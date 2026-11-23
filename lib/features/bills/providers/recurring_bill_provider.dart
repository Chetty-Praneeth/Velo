import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../data/models/recurring_bill_model.dart';
import '../data/recurring_bill_repository.dart';
import '../domain/bill_status.dart';

final recurringBillRepositoryProvider = Provider<RecurringBillRepository>((ref) {
  return RecurringBillRepository(ref.watch(supabaseClientProvider));
});

/// The user's recurring bills.
final recurringBillsProvider = StateNotifierProvider<RecurringBillsNotifier,
    AsyncValue<List<RecurringBillModel>>>((ref) {
  return RecurringBillsNotifier(ref.watch(recurringBillRepositoryProvider), ref);
});

class RecurringBillsNotifier
    extends StateNotifier<AsyncValue<List<RecurringBillModel>>> {
  final RecurringBillRepository _repo;
  final Ref _ref;

  RecurringBillsNotifier(this._repo, this._ref)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.getBills());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<RecurringBillModel> get _current => state.valueOrNull ?? const [];

  Future<void> addBill({
    required String name,
    required double amount,
    required String category,
    required int dueDay,
  }) async {
    final bill = await _repo.createBill(
      name: name,
      amount: amount,
      category: category,
      dueDay: dueDay,
    );
    state = AsyncValue.data([..._current, bill]);
  }

  Future<void> updateBill(RecurringBillModel bill) async {
    final updated = await _repo.updateBill(bill);
    state = AsyncValue.data(
      _current.map((b) => b.id == updated.id ? updated : b).toList(),
    );
  }

  Future<void> deleteBill(String id) async {
    await _repo.deleteBill(id);
    state = AsyncValue.data(_current.where((b) => b.id != id).toList());
    // Its past payments are now unlinked, ordinary expenses.
    _refreshExpenses();
  }

  /// Log this cycle's payment as an expense linked to the bill.
  Future<void> markPaid(RecurringBillModel bill) async {
    await _ref.read(expenseRepositoryProvider).addExpense(
          amount: bill.amount,
          category: bill.category,
          note: bill.name,
          recurringBillId: bill.id,
        );
    _refreshExpenses();
  }

  void _refreshExpenses() {
    _ref.invalidate(currentMonthExpensesProvider);
    _ref.invalidate(selectedMonthExpensesProvider);
  }
}

/// Every bill's status in the current cycle, sorted by due date.
/// Empty while loading or if bills can't be loaded (e.g. migration 003 not
/// yet applied), so the rest of the app keeps working.
final billStatusesProvider = Provider<List<BillStatus>>((ref) {
  // valueOrNull: `.value` rethrows when the provider is in an error state.
  final bills = ref.watch(recurringBillsProvider).valueOrNull ?? const [];
  final expenses =
      ref.watch(currentMonthExpensesProvider).valueOrNull ?? const [];
  final cycleStartDay = ref.watch(cycleStartDayProvider);
  return BillSchedule.statusesForCycle(
    bills: bills,
    cycleExpenses: expenses,
    now: DateTime.now(),
    cycleStartDay: cycleStartDay,
  );
});
