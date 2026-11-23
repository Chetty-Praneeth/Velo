import 'package:flutter_test/flutter_test.dart';
import 'package:project_m/features/bills/data/models/recurring_bill_model.dart';
import 'package:project_m/features/bills/domain/bill_status.dart';
import 'package:project_m/features/dashboard/domain/dashboard_state.dart';
import 'package:project_m/features/expenses/data/models/expense_model.dart';

int _id = 0;

ExpenseModel spend(double amount, DateTime date, {String? billId}) => ExpenseModel(
      id: 'e${_id++}',
      userId: 'u',
      amount: amount,
      category: 'Food',
      expenseDate: DateTime(date.year, date.month, date.day),
      createdAt: date,
      recurringBillId: billId,
    );

ExpenseModel income(double amount, DateTime date) => ExpenseModel(
      id: 'e${_id++}',
      userId: 'u',
      amount: amount,
      category: 'Gift',
      expenseDate: DateTime(date.year, date.month, date.day),
      createdAt: date,
      type: 'income',
    );

RecurringBillModel bill(String id, double amount, int dueDay, DateTime createdAt,
        {bool active = true}) =>
    RecurringBillModel(
      id: id,
      userId: 'u',
      name: id,
      amount: amount,
      category: 'Bills',
      dueDay: dueDay,
      isActive: active,
      createdAt: createdAt,
    );

void main() {
  // 18 Nov, cycle starts on the 1st → 13 days left including today.
  final now = DateTime(2026, 11, 18, 14);
  final today = DateTime(2026, 11, 18);
  final yesterday = DateTime(2026, 11, 17);
  final earlier = DateTime(2026, 11, 10);
  final cycleStart = DateTime(2026, 11, 1);

  DashboardState compute(List<ExpenseModel> expenses,
      {List<RecurringBillModel> bills = const [], DateTime? at, int cycleStartDay = 1}) {
    final when = at ?? now;
    return DashboardState.compute(
      monthlyAllowance: 10000,
      savingsGoal: 0,
      expenses: expenses,
      bills: BillSchedule.statusesForCycle(
        bills: bills,
        cycleExpenses: expenses,
        now: when,
        cycleStartDay: cycleStartDay,
      ),
      now: when,
      cycleStartDay: cycleStartDay,
    );
  }

  group('safe daily spend', () {
    test('spending exactly the limit leaves 0, not "over"', () {
      // 10,000 − 5,619 = 4,381 → 4,381 / 13 = 337
      final before = compute([spend(5619, earlier)]);
      expect(before.daysRemaining, 13);
      expect(before.safeDailySpend, closeTo(337, 0.001));

      final after = compute([spend(5619, earlier), spend(337, today)]);
      expect(after.safeDailySpend, closeTo(337, 0.001));
      expect(after.todaySpent, 337);
      expect(after.safeDailySpend - after.todaySpent, closeTo(0, 0.001));
    });

    test('never negative when the budget is used up', () {
      final s = compute([spend(12000, earlier)]);
      expect(s.safeDailySpend, 0);
      expect(s.availableFromToday, lessThan(0));
      expect(s.limitChange, isNull);
    });
  });

  group('recurring bills', () {
    final rent = bill('rent', 3900, 25, cycleStart);

    test('an unpaid bill is set aside up front', () {
      final s = compute([], bills: [rent]);
      expect(s.upcomingBills, 3900);
      expect(s.safeDailySpend, closeTo((10000 - 3900) / 13, 0.001));
    });

    test('paying it does not change the limit or count as spent today', () {
      final unpaid = compute([], bills: [rent]);
      final paid = compute([spend(3900, today, billId: 'rent')], bills: [rent]);

      expect(paid.safeDailySpend, closeTo(unpaid.safeDailySpend, 0.001));
      expect(paid.todaySpent, 0);
      expect(paid.upcomingBills, 0);
      expect(paid.paidBills, 3900);
      expect(paid.totalSpent, 3900);
    });

    test('paused bills are not set aside', () {
      final s = compute([], bills: [bill('gym', 800, 25, cycleStart, active: false)]);
      expect(s.upcomingBills, 0);
    });

    test('a bill added after this cycle\'s due date starts next cycle', () {
      final phone = bill('phone', 299, 5, DateTime(2026, 11, 10));
      final status = BillSchedule.statusesForCycle(
        bills: [phone],
        cycleExpenses: const [],
        now: now,
        cycleStartDay: 1,
      ).single;

      expect(status.dueThisCycle, isFalse);
      expect(status.reservedAmount, 0);
      expect(status.nextCycleDueDate, DateTime(2026, 12, 5));
    });

    test('overdue and due-today flags', () {
      final statuses = BillSchedule.statusesForCycle(
        bills: [bill('a', 100, 10, cycleStart), bill('b', 100, 18, cycleStart)],
        cycleExpenses: const [],
        now: now,
        cycleStartDay: 1,
      );
      expect(statuses[0].isOverdue, isTrue);
      expect(statuses[1].isDueToday, isTrue);
      expect(statuses[1].isOverdue, isFalse);
    });

    test('bill payments are excluded from the everyday average', () {
      final s = compute(
        [spend(3900, earlier, billId: 'rent'), spend(1800, earlier)],
        bills: [rent],
      );
      expect(s.averageDailySpend, closeTo(1800 / 18, 0.001));
    });
  });

  group('due dates with a custom cycle start day', () {
    test('due day before the start day falls in the next month', () {
      // Cycle 25 Nov – 24 Dec.
      final at = DateTime(2026, 11, 30);
      expect(BillSchedule.dueDateInCycle(at, 25, 5), DateTime(2026, 12, 5));
      expect(BillSchedule.dueDateInCycle(at, 25, 28), DateTime(2026, 11, 28));
    });

    test('day 31 is clamped to the end of short months', () {
      expect(BillSchedule.dueDateInCycle(DateTime(2027, 2, 10), 1, 31),
          DateTime(2027, 2, 28));
      expect(BillSchedule.dueDateInCycle(DateTime(2026, 11, 10), 1, 31),
          DateTime(2026, 11, 30));
    });
  });

  group('why the limit changed since yesterday', () {
    test('under-spending is spread over the days left', () {
      final s = compute([spend(5000, earlier), spend(257, yesterday)]);
      final c = s.limitChange!;

      expect(c.yesterdaySpent, 257);
      expect(c.underBy, closeTo(c.yesterdayLimit - 257, 0.001));
      expect(c.fromYesterday, closeTo(c.underBy / 13, 0.001));
      expect(s.safeDailySpend, closeTo(c.yesterdayLimit + c.fromYesterday, 0.001));
    });

    test('today\'s income is its own part of the change', () {
      final s = compute([
        spend(5000, earlier),
        spend(400, yesterday),
        income(1000, today),
      ]);
      final c = s.limitChange!;

      expect(c.incomeSinceYesterday, 1000);
      expect(
        s.safeDailySpend,
        closeTo(c.yesterdayLimit + c.fromYesterday + c.fromIncome, 0.001),
      );
    });

    test('no comparison on the first day of a cycle', () {
      final s = compute([], at: DateTime(2026, 11, 1, 9));
      expect(s.daysElapsed, 1);
      expect(s.limitChange, isNull);
    });
  });
}
