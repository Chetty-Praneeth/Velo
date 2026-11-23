import '../../../core/utils/date_utils.dart';
import '../../expenses/data/models/expense_model.dart';
import '../data/models/recurring_bill_model.dart';

/// Where a recurring bill stands in the current cycle.
class BillStatus {
  final RecurringBillModel bill;

  /// When the bill falls due in the current cycle.
  final DateTime dueDate;

  /// The logged payment for this cycle, if any.
  final ExpenseModel? payment;

  /// False when the bill was added after this cycle's due date. It's then
  /// first set aside next cycle, unless it gets paid this cycle anyway.
  final bool dueThisCycle;

  /// When it's due in the next cycle.
  final DateTime nextCycleDueDate;

  final DateTime today;

  const BillStatus({
    required this.bill,
    required this.dueDate,
    required this.payment,
    required this.dueThisCycle,
    required this.nextCycleDueDate,
    required this.today,
  });

  bool get isPaid => payment != null;

  /// Still owed this cycle, so its amount is set aside.
  bool get isPending => bill.isActive && dueThisCycle && !isPaid;

  bool get isOverdue => isPending && dueDate.isBefore(today);
  bool get isDueToday => isPending && dueDate == today;

  /// Money set aside for this bill right now.
  double get reservedAmount => isPending ? bill.amount : 0;
}

/// Pure helpers for bill scheduling within a budget cycle.
class BillSchedule {
  BillSchedule._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The date a bill due on [dueDay] falls in the cycle containing [date].
  ///
  /// Cycles start on [cycleStartDay] (1–28). A due day before the start day
  /// belongs to the following calendar month. Days past the end of a month
  /// are clamped (31 → 30 Nov, 28/29 Feb).
  static DateTime dueDateInCycle(DateTime date, int cycleStartDay, int dueDay) {
    final start = AppDateUtils.startOfCycle(date, cycleStartDay);
    final monthOffset = dueDay >= cycleStartDay ? 0 : 1;
    final year = start.year;
    final month = start.month + monthOffset;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, dueDay > lastDay ? lastDay : dueDay);
  }

  /// The due date in the cycle after the one containing [date].
  static DateTime dueDateInNextCycle(DateTime date, int cycleStartDay, int dueDay) {
    final end = AppDateUtils.endOfCycle(date, cycleStartDay);
    final nextCycleDay = DateTime(end.year, end.month, end.day + 1);
    return dueDateInCycle(nextCycleDay, cycleStartDay, dueDay);
  }

  /// Whether a bill added on [addedOn] is first due in the current cycle
  /// (its due date hasn't passed yet) rather than the next one.
  static bool firstDueThisCycle(DateTime addedOn, int cycleStartDay, int dueDay) {
    final dueDate = dueDateInCycle(addedOn, cycleStartDay, dueDay);
    return !dueDate.isBefore(_dateOnly(addedOn));
  }

  /// Status of every bill for the cycle containing [now].
  ///
  /// [cycleExpenses] must be the current cycle's transactions. A bill counts
  /// as paid when one of them is linked to it.
  static List<BillStatus> statusesForCycle({
    required List<RecurringBillModel> bills,
    required List<ExpenseModel> cycleExpenses,
    required DateTime now,
    required int cycleStartDay,
  }) {
    final today = _dateOnly(now);
    final payments = <String, ExpenseModel>{};
    for (final e in cycleExpenses) {
      final billId = e.recurringBillId;
      if (e.isBillPayment && billId != null) payments.putIfAbsent(billId, () => e);
    }

    final statuses = bills.map((bill) {
      final dueDate = dueDateInCycle(now, cycleStartDay, bill.dueDay);
      final addedOn = _dateOnly(bill.createdAt);
      return BillStatus(
        bill: bill,
        dueDate: dueDate,
        payment: payments[bill.id],
        dueThisCycle: !dueDate.isBefore(addedOn),
        nextCycleDueDate: dueDateInNextCycle(now, cycleStartDay, bill.dueDay),
        today: today,
      );
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return statuses;
  }
}
