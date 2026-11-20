import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/bounceable.dart';
import '../../../core/widgets/category_icon.dart';
import '../providers/expense_provider.dart';
import '../data/models/expense_model.dart';
import '../../auth/providers/auth_provider.dart';

enum TransactionFilter { all, expense, income }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter.all);

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final cycleStartDay = ref.watch(cycleStartDayProvider);
    final expensesAsync = ref.watch(selectedMonthExpensesProvider);
    final totalSpent = ref.watch(selectedMonthTotalSpentProvider);
    final user = ref.watch(currentUserProvider);
    
    // Load monthly budget for selected month
    final budgetAsync = ref.watch(selectedMonthBudgetProvider);
    final budget = budgetAsync.value;
    final monthlyAllowance = budget?.monthlyAllowance ?? 0.0;
    final spendableBudget = budget?.spendableBudget ?? 0.0;

    final fullName = user?.userMetadata?['full_name'] as String?;
    final firstName = fullName != null && fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').first
        : 'Terry';

    final isCurrent = selectedMonth.month == DateTime.now().month && selectedMonth.year == DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Mockup Screen 2 style)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/settings'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentPrimary,
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Bounceable(
                        onTap: () => _showMonthPicker(context, ref, selectedMonth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${AppDateUtils.monthName(selectedMonth.month)} ${selectedMonth.year}',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textPrimary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      Bounceable(
                        onTap: () {},
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 26,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Calendar Bar / Date Range Banner
            if (isCurrent)
              _CalendarBar()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accentPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billing Cycle Period',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppDateUtils.formatShort(AppDateUtils.startOfCycle(selectedMonth, cycleStartDay))} – ${AppDateUtils.formatShort(AppDateUtils.endOfCycle(selectedMonth, cycleStartDay))}',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Side-by-side purple & orange cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TotalCard(
                      label: 'Total Salary',
                      amount: monthlyAllowance,
                      color: const Color(0xFF6C25E9),
                      cardNumber: '•••• •••• •••• 1965',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _TotalCard(
                      label: 'Total Expense',
                      amount: totalSpent,
                      color: AppColors.orangeAccent,
                      cardNumber: '•••• •••• •••• 1965',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Segmented Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildFilterTab(ref, TransactionFilter.all, 'All'),
                    _buildFilterTab(ref, TransactionFilter.expense, 'Expenses'),
                    _buildFilterTab(ref, TransactionFilter.income, 'Income'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ref.watch(transactionFilterProvider) == TransactionFilter.expense
                        ? 'Expenses'
                        : (ref.watch(transactionFilterProvider) == TransactionFilter.income ? 'Income' : 'Transactions'),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'View All',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Expense List
            Expanded(
              child: expensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return _buildEmptyState();
                  }
                  final activeFilter = ref.watch(transactionFilterProvider);
                  final filteredExpenses = expenses.where((e) {
                    if (activeFilter == TransactionFilter.expense) {
                      return e.type == 'expense';
                    } else if (activeFilter == TransactionFilter.income) {
                      return e.type == 'income';
                    }
                    return true;
                  }).toList();

                  if (filteredExpenses.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 100,
                    ),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final item = filteredExpenses[index];
                      final budgetLimit = spendableBudget > 0 
                          ? spendableBudget 
                          : 3000.0;
                      return _ExpenseMockCard(expense: item, budgetLimit: budgetLimit, ref: ref);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentPrimary),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(WidgetRef ref, TransactionFilter filter, String label) {
    final activeFilter = ref.watch(transactionFilterProvider);
    final isActive = activeFilter == filter;

    return Expanded(
      child: Bounceable(
        onTap: () => ref.read(transactionFilterProvider.notifier).state = filter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No expenses logged yet',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Logged expenses will appear here',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime currentMonth) {
    int selectedYear = currentMonth.year;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setModalState(() => selectedYear--);
                        },
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                      ),
                      Text(
                        '$selectedYear',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setModalState(() => selectedYear++);
                        },
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final monthNameShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index];
                      final isSelected = currentMonth.month == monthNum && currentMonth.year == selectedYear;

                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedMonthProvider.notifier).state = DateTime(selectedYear, monthNum);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Center(
                            child: Text(
                              monthNameShort,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Calendar Bar ─────────────────────────────────────────────

class _CalendarBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int weekday = now.weekday;
    final DateTime monday = now.subtract(Duration(days: weekday - 1));
    final List<DateTime> weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(days.length, (index) {
          final date = weekDates[index];
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;

          return Container(
            margin: const EdgeInsets.only(right: 20),
            child: Column(
              children: [
                Text(
                  days[index],
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (isToday)
                  Container(
                    width: 32,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.orangeAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Purple & Orange Total Cards ───────────────────────────────

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.cardNumber,
  });

  final String label;
  final double amount;
  final Color color;
  final String cardNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.credit_card_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bank Account',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            cardNumber,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom List Row Widget ────────────────────────────────────

class _ExpenseMockCard extends StatelessWidget {
  const _ExpenseMockCard({
    required this.expense,
    required this.budgetLimit,
    required this.ref,
  });

  final ExpenseModel expense;
  final double budgetLimit;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';

    if (isIncome) {
      return Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_rounded, color: AppColors.danger),
        ),
        onDismissed: (_) {
          ref.read(selectedMonthExpensesProvider.notifier).deleteExpense(expense.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CategoryIcon(
                category: expense.category,
                size: 36,
                iconSize: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      AppDateUtils.formatRelative(expense.expenseDate),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+ ${CurrencyFormatter.format(expense.amount)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pct = (expense.amount / budgetLimit).clamp(0.0, 1.0);
    final pctText = (pct * 100).toStringAsFixed(1);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) {
        ref.read(selectedMonthExpensesProvider.notifier).deleteExpense(expense.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Custom Icon layout matching shopping cart mockup icon
                CategoryIcon(
                  category: expense.category,
                  size: 36,
                  iconSize: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        AppDateUtils.formatRelative(expense.expenseDate),
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spend',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(expense.amount),
                      style: const TextStyle(
                        color: Color(0xFF6C25E9),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(budgetLimit),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE4E6EA),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6C25E9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pctText%',
                  style: const TextStyle(
                    color: Color(0xFF6C25E9),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
