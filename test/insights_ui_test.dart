import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_m/core/providers/cycle_provider.dart';
import 'package:project_m/features/auth/providers/auth_provider.dart';
import 'package:project_m/features/bills/data/models/recurring_bill_model.dart';
import 'package:project_m/features/bills/data/recurring_bill_repository.dart';
import 'package:project_m/features/bills/providers/recurring_bill_provider.dart';
import 'package:project_m/features/dashboard/providers/dashboard_provider.dart';
import 'package:project_m/features/expenses/data/category_repository.dart';
import 'package:project_m/features/expenses/data/expense_repository.dart';
import 'package:project_m/features/expenses/data/models/custom_category_model.dart';
import 'package:project_m/features/expenses/data/models/expense_model.dart';
import 'package:project_m/features/expenses/providers/category_provider.dart';
import 'package:project_m/features/expenses/providers/expense_provider.dart';
import 'package:project_m/features/insights/presentation/insights_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeClient extends Fake implements SupabaseClient {}

class _Expenses extends ExpenseListNotifier {
  _Expenses(this.items) : super(ExpenseRepository(_FakeClient()), cycleStartDay: 1);
  final List<ExpenseModel> items;
  @override
  Future<void> loadExpenses() async => state = AsyncValue.data(items);
}

class _Bills extends RecurringBillsNotifier {
  _Bills(Ref ref) : super(RecurringBillRepository(_FakeClient()), ref);
  @override
  Future<void> load() async => state = const AsyncValue.data(<RecurringBillModel>[]);
}

class _Categories extends CustomCategoriesNotifier {
  _Categories() : super(CategoryRepository(_FakeClient()));
  @override
  Future<void> loadCategories() async =>
      state = const AsyncValue.data(<CustomCategoryModel>[]);
}

// See bills_ui_test.dart: a real font gives realistic text widths.
const _arial = '/System/Library/Fonts/Supplemental/Arial.ttf';
const _arialBold = '/System/Library/Fonts/Supplemental/Arial Bold.ttf';
final _hasArial = [_arial, _arialBold].every((f) => File(f).existsSync());

Future<void> _loadRealFonts() async {
  final regular = File(_arial).readAsBytesSync();
  final bold = File(_arialBold).readAsBytesSync();
  for (final family in [
    'Roboto',
    'Inter_regular',
    for (var w = 100; w <= 900; w += 100)
      if (w != 400) 'Inter_$w',
  ]) {
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(regular)))
          ..addFont(Future.value(ByteData.sublistView(bold))))
        .load();
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (_hasArial) await _loadRealFonts();
  });

  final now = DateTime.now();
  final cycleStart = DateTime(now.year, now.month, 1);
  DateTime day(int d) => DateTime(now.year, now.month, d);
  DateTime lastMonth(int d) => DateTime(now.year, now.month - 1, d);

  var n = 0;
  ExpenseModel tx(double amount, String category, DateTime date, {String? billId}) =>
      ExpenseModel(
        id: '${n++}',
        userId: 'u',
        amount: amount,
        category: category,
        expenseDate: date,
        createdAt: date,
        recurringBillId: billId,
      );

  final expenses = [
    tx(450, 'Food', day(1)),
    tx(6000, 'Bills', day(1), billId: 'rent'),
    tx(1299, 'Entertainment and subscriptions', day(1)),
    tx(120, 'Transport', day(1)),
  ];
  final previous = [
    tx(300, 'Food', lastMonth(1)),
    tx(200, 'Transport', lastMonth(1)),
  ];

  Future<void> pump(WidgetTester tester, double width, {double? budget = 15000}) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(null),
        selectedMonthProvider.overrideWith((ref) => cycleStart),
        selectedMonthExpensesProvider.overrideWith((ref) => _Expenses(expenses)),
        currentMonthExpensesProvider.overrideWith((ref) => _Expenses(expenses)),
        selectedMonthBudgetProvider.overrideWith((ref) async => budget == null
            ? null
            : MonthlyBudgetModel(
                id: 'b',
                userId: 'u',
                month: now.month,
                year: now.year,
                monthlyAllowance: budget,
                savingsGoal: 2000,
                createdAt: now,
              )),
        previousCycleExpensesProvider.overrideWith((ref) async => previous),
        dashboardStateProvider.overrideWith((ref) => DashboardState.compute(
              monthlyAllowance: budget ?? 0,
              savingsGoal: 2000,
              expenses: expenses,
              bills: const [],
              now: now,
              cycleStartDay: 1,
            )),
        recurringBillsProvider.overrideWith((ref) => _Bills(ref)),
        customCategoriesProvider.overrideWith((ref) => _Categories()),
      ],
      child: const MaterialApp(home: InsightsScreen()),
    ));
    await tester.pumpAndSettle();
  }

  for (final width in [393.0, 350.0]) {
    testWidgets('insights renders projection, donut, categories at ${width}pt',
        skip: !_hasArial, (tester) async {
      await pump(tester, width);

      expect(find.textContaining('Projected'), findsOneWidget);
      expect(find.text('Spending by category'), findsOneWidget);
      expect(find.text('Where your money went'), findsOneWidget);
      // Bills is the biggest category: in the donut legend and the list.
      expect(find.text('Bills'), findsNWidgets(2));
      // Tapping a legend row puts that category in the middle of the donut.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Bills, \d+ percent')));
      await tester.pumpAndSettle();
      expect(find.text('Bills'), findsNWidgets(3));
      // Food 450 vs 300 at the same point last cycle.
      expect(find.textContaining('↑ 50%'), findsOneWidget);
      expect(find.textContaining('New this cycle'), findsNWidgets(2));

      await tester.scrollUntilVisible(find.text('Highlights'), 200);
      expect(find.text('No-spend days'), findsOneWidget);

      final error = tester.takeException();
      if (error != null) debugPrint('$error');
      expect(error, isNull);
    });
  }

  testWidgets('without a budget shows total spent instead of a projection',
      skip: !_hasArial, (tester) async {
    await pump(tester, 393, budget: null);
    expect(find.text('Spent this cycle'), findsOneWidget);
    expect(find.text('Set a monthly budget to see projections'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
