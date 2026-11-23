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
import 'package:project_m/features/bills/domain/bill_status.dart';
import 'package:project_m/features/bills/presentation/recurring_bills_screen.dart';
import 'package:project_m/features/bills/providers/recurring_bill_provider.dart';
import 'package:project_m/features/dashboard/presentation/dashboard_screen.dart';
import 'package:project_m/features/dashboard/providers/dashboard_provider.dart';
import 'package:project_m/features/expenses/data/category_repository.dart';
import 'package:project_m/features/expenses/data/expense_repository.dart';
import 'package:project_m/features/expenses/data/models/custom_category_model.dart';
import 'package:project_m/features/expenses/data/models/expense_model.dart';
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
  _Bills(this.items, Ref ref) : super(RecurringBillRepository(_FakeClient()), ref);
  final List<RecurringBillModel> items;
  @override
  Future<void> load() async => state = AsyncValue.data(items);
}

class _Categories extends CustomCategoriesNotifier {
  _Categories() : super(CategoryRepository(_FakeClient()));
  @override
  Future<void> loadCategories() async =>
      state = const AsyncValue.data(<CustomCategoryModel>[]);
}

// Flutter's test font draws every glyph as a full-width square, so text is far
// wider than on a phone. Load a real font (macOS Arial) under the family names
// google_fonts gives Inter, so overflow checks use realistic widths.
const _arial = '/System/Library/Fonts/Supplemental/Arial.ttf';
const _arialBold = '/System/Library/Fonts/Supplemental/Arial Bold.ttf';
const _courier = '/System/Library/Fonts/Supplemental/Courier New Bold.ttf';
final _hasArial = [_arial, _arialBold, _courier].every((f) => File(f).existsSync());

Future<void> _loadRealFonts() async {
  final regular = File(_arial).readAsBytesSync();
  final bold = File(_arialBold).readAsBytesSync();
  await (FontLoader('Courier')
        ..addFont(Future.value(ByteData.sublistView(File(_courier).readAsBytesSync()))))
      .load();
  final families = [
    'Roboto',
    'Inter_regular',
    for (var w = 100; w <= 900; w += 100)
      if (w != 400) 'Inter_$w',
  ];
  for (final family in families) {
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
  final today = DateTime(now.year, now.month, now.day);
  final cycleStart = DateTime(now.year, now.month, 1);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  ExpenseModel tx(double amount, DateTime date, {String? billId, String type = 'expense'}) =>
      ExpenseModel(
        id: '${amount}_${date.day}_$billId',
        userId: 'u',
        amount: amount,
        category: 'Food',
        note: billId,
        expenseDate: date,
        createdAt: date,
        type: type,
        recurringBillId: billId,
      );

  RecurringBillModel bill(String id, String name, double amount, int dueDay) =>
      RecurringBillModel(
        id: id,
        userId: 'u',
        name: name,
        amount: amount,
        category: 'Bills',
        dueDay: dueDay,
        isActive: true,
        createdAt: cycleStart,
      );

  final bills = [
    bill('rent', 'Rent for the flat near college', 6000, 28),
    bill('phone', 'Phone recharge', 299, 28),
    bill('spotify', 'Spotify', 119, 28),
    bill('wifi', 'Wi-Fi', 599, 28),
    bill('gym', 'Gym', 800, 1),
  ];
  final expenses = [
    tx(800, cycleStart, billId: 'gym'),
    if (now.day > 1) tx(1200, yesterday),
    tx(150, today),
    tx(1000, today, type: 'income'),
  ];

  Future<void> pump(WidgetTester tester, Widget screen, double width) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(null),
        currentMonthExpensesProvider.overrideWith((ref) => _Expenses(expenses)),
        recurringBillsProvider.overrideWith((ref) => _Bills(bills, ref)),
        customCategoriesProvider.overrideWith((ref) => _Categories()),
        dashboardStateProvider.overrideWith((ref) => DashboardState.compute(
              monthlyAllowance: 15000,
              savingsGoal: 2000,
              expenses: expenses,
              bills: ref.watch(billStatusesProvider),
              now: now,
              cycleStartDay: 1,
            )),
      ],
      child: MaterialApp(home: screen),
    ));
    await tester.pump();
  }

  // 350pt with Arial ≈ 375pt (iPhone SE) with the slightly wider Inter.
  for (final width in [393.0, 350.0]) {
    testWidgets('dashboard cards and breakdown sheet render at ${width}pt',
        skip: !_hasArial, (tester) async {
      await pump(tester, const DashboardScreen(), width);

      expect(find.text('Safe to spend today'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Bills this cycle'), 200);
      expect(find.text('Mark paid'), findsNWidgets(3)); // shows top 3 pending
      expect(find.text('+ 1 more'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Safe to spend today'), -200);
      await tester.tap(find.text('Safe to spend today'));
      await tester.pumpAndSettle();
      expect(find.text('How today\'s limit is worked out'), findsOneWidget);
      expect(find.text('Bills this cycle'), findsWidgets);
      final error = tester.takeException();
      if (error != null) debugPrint("$error");
      expect(error, isNull);
    });

    testWidgets('bills screen and edit sheet render at ${width}pt',
        skip: !_hasArial, (tester) async {
      await pump(tester, const RecurringBillsScreen(), width);

      expect(find.text('Still to pay this cycle'), findsOneWidget);
      expect(find.text('Paid ${BillSchedule.dueDateInCycle(now, 1, 1).day} ${_mon(now)}'),
          findsOneWidget);

      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Bill'), findsOneWidget);
      expect(find.text('Set aside every cycle'), findsOneWidget);
      final error = tester.takeException();
      if (error != null) debugPrint("$error");
      expect(error, isNull);
    });
  }
}

String _mon(DateTime d) =>
    const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];
