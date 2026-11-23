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
import 'package:project_m/features/expenses/data/category_repository.dart';
import 'package:project_m/features/expenses/data/expense_repository.dart';
import 'package:project_m/features/expenses/data/models/custom_category_model.dart';
import 'package:project_m/features/expenses/data/models/expense_model.dart';
import 'package:project_m/features/expenses/presentation/expense_list_screen.dart';
import 'package:project_m/features/expenses/providers/category_provider.dart';
import 'package:project_m/features/expenses/providers/expense_provider.dart';
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
  DateTime ago(int d) => DateTime(now.year, now.month, now.day - d);

  var n = 0;
  ExpenseModel tx(double amount, String category, DateTime date,
          {String? note, String type = 'expense'}) =>
      ExpenseModel(
        id: '${n++}',
        userId: 'u',
        amount: amount,
        category: category,
        note: note,
        expenseDate: date,
        createdAt: date,
        type: type,
      );

  final expenses = [
    tx(180, 'Food', ago(0), note: 'Lunch with a very long note that should be cut off'),
    tx(2000, 'Gift', ago(1), type: 'income'),
    tx(1299, 'Shopping', ago(1), note: 'Shoes'),
    tx(250, 'Entertainment', ago(3), note: 'Movie'),
    tx(320, 'Food', ago(7)),
    tx(140, 'Education', ago(8), note: 'Notebooks'),
  ];

  Future<void> pump(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(null),
        selectedMonthExpensesProvider.overrideWith((ref) => _Expenses(expenses)),
        currentMonthExpensesProvider.overrideWith((ref) => _Expenses(expenses)),
        selectedMonthBudgetProvider.overrideWith((ref) async => MonthlyBudgetModel(
              id: 'b',
              userId: 'u',
              month: now.month,
              year: now.year,
              monthlyAllowance: 15000,
              savingsGoal: 2000,
              createdAt: now,
            )),
        weekExpensesProvider.overrideWith((ref, weekStart) async {
          final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
          return expenses
              .where((e) => !e.expenseDate.isBefore(weekStart) && e.expenseDate.isBefore(end))
              .toList();
        }),
        recurringBillsProvider.overrideWith((ref) => _Bills(ref)),
        customCategoriesProvider.overrideWith((ref) => _Categories()),
      ],
      child: const MaterialApp(home: ExpenseListScreen()),
    ));
    await tester.pumpAndSettle();
  }

  for (final width in [393.0, 350.0]) {
    testWidgets('expenses screen, week chart and day filter render at ${width}pt',
        skip: !_hasArial, (tester) async {
      await pump(tester, width);

      expect(find.text('Spent this cycle'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);

      // Go back a week; the chart relabels and the day filter resets.
      await tester.tap(find.bySemanticsLabel('Previous week'));
      await tester.pumpAndSettle();
      expect(find.text('Last week'), findsOneWidget);

      // Tap a day with spending: the list narrows to that day.
      final bar = find.bySemanticsLabel(RegExp(r', ₹[1-9]'));
      expect(bar, findsWidgets);
      await tester.tap(bar.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Showing '), findsOneWidget);

      // Can't go past the current week.
      await tester.tap(find.bySemanticsLabel('Next week'));
      await tester.pumpAndSettle();
      expect(find.text('This week'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next week'));
      await tester.pumpAndSettle();
      expect(find.text('This week'), findsOneWidget);

      final error = tester.takeException();
      if (error != null) debugPrint('$error');
      expect(error, isNull);
    });
  }
}
