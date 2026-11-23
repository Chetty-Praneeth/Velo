import 'package:flutter_test/flutter_test.dart';
import 'package:project_m/features/expenses/data/models/expense_model.dart';
import 'package:project_m/features/insights/domain/cycle_analytics.dart';

var _n = 0;
ExpenseModel _tx(double amount, DateTime date,
        {String category = 'Food', String type = 'expense', String? billId}) =>
    ExpenseModel(
      id: '${_n++}',
      userId: 'u',
      amount: amount,
      category: category,
      expenseDate: date,
      createdAt: date,
      type: type,
      recurringBillId: billId,
    );

void main() {
  final start = DateTime(2026, 11, 1);
  final end = DateTime(2026, 11, 30);
  DateTime nov(int d) => DateTime(2026, 11, d);

  CycleAnalytics compute(List<ExpenseModel> list,
          {DateTime? now,
          double? budget = 3000,
          double upcoming = 0,
          List<ExpenseModel>? previous}) =>
      CycleAnalytics.compute(
        expenses: list,
        cycleStart: start,
        cycleEnd: end,
        now: now ?? nov(10).add(const Duration(hours: 15)),
        spendableBudget: budget,
        upcomingBills: upcoming,
        previousExpenses: previous,
        previousStart: previous == null ? null : DateTime(2026, 10, 1),
      );

  test('counts days and averages everyday spending only', () {
    final a = compute([
      _tx(100, nov(1)),
      _tx(200, nov(5)),
      _tx(600, nov(2), category: 'Bills', billId: 'rent'),
      _tx(1000, nov(3), type: 'income', category: 'Gift'),
    ]);
    expect(a.totalDays, 30);
    expect(a.daysElapsed, 10);
    expect(a.isCurrent, isTrue);
    expect(a.everydaySpent, 300);
    expect(a.totalSpent, 900);
    expect(a.averageDaily, 30);
    expect(a.cumulative.length, 10);
    expect(a.cumulative.last, 300);
    // 3000 budget + 1000 income − 600 bill
    expect(a.everydayBudget, 3400);
  });

  test('pace and projection', () {
    final a = compute([_tx(500, nov(2))], upcoming: 400);
    // budget for everyday spending = 3000 − 400 upcoming bills = 2600
    expect(a.everydayBudget, 2600);
    // even pace by day 10 of 30 = 2600/3 ≈ 866.67; spent 500 → under pace
    expect(a.paceDelta, closeTo(366.67, 0.01));
    // avg 50/day for 20 more days → 1500 spent, 1100 left
    expect(a.projectedSpend, 1500);
    expect(a.projectedLeftover, 1100);
    expect(a.runOutDay, isNull);
  });

  test('run-out day when overspending', () {
    // 2000 spent in 10 days = 200/day; 1000 left lasts 5 more days.
    final a = compute([_tx(2000, nov(1))]);
    expect(a.projectedLeftover, lessThan(0));
    expect(a.runOutDay, nov(15));
  });

  test('past cycle uses actual figures and ignores upcoming bills', () {
    final a = compute([_tx(2500, nov(4))], now: DateTime(2026, 12, 5), upcoming: 999);
    expect(a.isCurrent, isFalse);
    expect(a.daysElapsed, 30);
    expect(a.upcomingBills, 0);
    expect(a.projectedSpend, 2500);
    expect(a.projectedLeftover, 500);
    expect(a.runOutDay, isNull);
  });

  test('cycle that has not started', () {
    final a = compute([], now: DateTime(2026, 10, 20));
    expect(a.isFuture, isTrue);
    expect(a.cumulative, isEmpty);
  });

  test('categories sorted with share and change vs same point last cycle', () {
    final a = compute(
      [
        _tx(300, nov(1)),
        _tx(100, nov(2), category: 'Transport'),
        _tx(100, nov(9)),
      ],
      previous: [
        _tx(200, DateTime(2026, 10, 3)), // by day 10 → counted
        _tx(900, DateTime(2026, 10, 25)), // after day 10 → not counted
        _tx(50, DateTime(2026, 10, 4), category: 'Transport'),
      ],
    );
    expect(a.categories.map((c) => c.category), ['Food', 'Transport']);
    expect(a.categories.first.amount, 400);
    expect(a.categories.first.count, 2);
    expect(a.categories.first.share, closeTo(0.8, 1e-9));
    expect(a.categories.first.change, closeTo(1.0, 1e-9)); // 400 vs 200
    expect(a.categories.last.change, closeTo(1.0, 1e-9)); // 100 vs 50
    expect(a.previousToDate, 250);
    expect(a.changeVsPrevious, closeTo(1.0, 1e-9)); // 500 vs 250
  });

  test('new category has no change figure', () {
    final a = compute([_tx(100, nov(1), category: 'Gym')], previous: []);
    expect(a.categories.single.previous, 0);
    expect(a.categories.single.change, isNull);
  });

  test('highlights: biggest day, no-spend days (today excluded), most frequent', () {
    final a = compute([
      _tx(50, nov(1), category: 'Tea'),
      _tx(50, nov(2), category: 'Tea'),
      _tx(400, nov(3), category: 'Shopping'),
      _tx(600, nov(4), category: 'Bills', billId: 'rent'), // bill: ignored
    ]);
    expect(a.biggestDay?.day, nov(3));
    expect(a.biggestDay?.amount, 400);
    // days 4–9 have no everyday spending; today (10th) isn't over yet
    expect(a.noSpendDays, 6);
    expect(a.mostFrequent?.category, 'Tea');
    expect(a.mostFrequent?.count, 2);
  });

  test('projected savings = savings goal + leftover', () {
    CycleAnalytics withGoal(List<ExpenseModel> list) => CycleAnalytics.compute(
          expenses: list,
          cycleStart: start,
          cycleEnd: end,
          now: nov(10),
          spendableBudget: 3000,
          savingsGoal: 2000,
        );
    // 50/day → 1500 spent, 1500 left over → 3500 saved in total
    expect(withGoal([_tx(500, nov(2))]).projectedSavings, 3500);
    // 200/day → 6000 spent, 3000 over → eats the 2000 goal, 1000 overspent
    expect(withGoal([_tx(2000, nov(2))]).projectedSavings, -1000);
  });

  test('no budget set', () {
    final a = compute([_tx(100, nov(1))], budget: null);
    expect(a.hasBudget, isFalse);
  });
}
