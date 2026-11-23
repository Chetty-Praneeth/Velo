import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/bounceable.dart';
import '../../../core/widgets/home_style.dart';
import '../providers/dashboard_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../expenses/data/models/expense_model.dart';
import '../../bills/presentation/bill_widgets.dart';
import '../../bills/providers/recurring_bill_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TxnFilter _filter = TxnFilter.all;
  String? _query; // null when the search field is closed
  final _searchController = TextEditingController();

  // Swiped-away rows, hidden at once while the delete request runs.
  final _dismissed = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      if (_query == null) {
        _query = '';
      } else {
        _query = null;
        _searchController.clear();
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardStateProvider);
    final guidance = ref.watch(smartGuidanceProvider);
    final expensesAsync = ref.watch(currentMonthExpensesProvider);

    final expenses = (expensesAsync.valueOrNull ?? const <ExpenseModel>[])
        .where((e) => !_dismissed.contains(e.id))
        .toList();

    return DarkSheetPage(
      header: [
        const HomeTopBar(),
        const SizedBox(height: 28),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(right: -80, top: -24, child: _CardFan()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 60, 0),
              child: _BalanceHero(state: state),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SafeSpendCard(state: state),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SpendingCard(total: state.totalSpent, expenses: expenses),
        ),
      ],
      sheet: [
        SheetHeader(
          title: _filter.title,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
          searching: _query != null,
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _query = v),
          onToggleSearch: _toggleSearch,
        ),
        _transactions(expensesAsync, expenses),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _UpcomingBillsCard(),
        ),
        if (guidance.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GuidanceCard(messages: guidance),
          ),
      ],
    );
  }

  Widget _transactions(AsyncValue<List<ExpenseModel>> async, List<ExpenseModel> all) {
    if (!async.hasValue && async.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.ink),
          ),
        ),
      );
    }
    if (!async.hasValue && async.hasError) {
      return SheetMessage(
        emoji: '⚠️',
        title: 'Couldn\'t load transactions',
        action: TextButton(
          onPressed: () => ref.read(currentMonthExpensesProvider.notifier).loadExpenses(),
          child: Text('Try again', style: homeText(14, FontWeight.w600, HomeColors.ink)),
        ),
      );
    }

    final matches = all.where(_filter.matches).where((e) => matchesSearch(e, _query)).toList();
    final browsing = _filter == TxnFilter.all && (_query ?? '').trim().isEmpty;
    final shown = browsing ? matches.take(6).toList() : matches;

    if (shown.isEmpty) {
      return browsing
          ? const SheetMessage(
              emoji: '💸',
              title: 'No transactions yet',
              subtitle: 'Tap Add expense to log your first one.',
            )
          : const SheetMessage(
              emoji: '🔍',
              title: 'Nothing matches',
              subtitle: 'Try a different search or filter.',
            );
    }

    return Column(
      children: [
        for (final e in shown)
          TransactionRow(
            expense: e,
            onDismissed: () {
              setState(() => _dismissed.add(e.id));
              ref.read(currentMonthExpensesProvider.notifier).deleteExpense(e.id);
            },
          ),
        if (browsing && matches.length > shown.length)
          TextButton(
            onPressed: () => context.go('/expenses'),
            child: Text('See all transactions',
                style: homeText(14, FontWeight.w600, HomeColors.inkSoft)),
          ),
      ],
    );
  }
}

// ─── Balance ──────────────────────────────────────────────────

class _BalanceHero extends StatefulWidget {
  const _BalanceHero({required this.state});
  final DashboardState state;

  @override
  State<_BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<_BalanceHero> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _hidden = !_hidden),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Total balance',
                      style: homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(width: 6),
                  Icon(
                    _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              BigAmount(value: widget.state.remainingBalance, hidden: _hidden),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              label: 'Add expense',
              icon: Icons.north_east_rounded,
              light: true,
              onTap: () => context.push('/add-expense'),
            ),
            _Pill(
              label: 'Add income',
              onTap: () => context.push('/add-expense?type=income'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.icon, this.light = false});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: EdgeInsets.only(left: icon != null ? 5 : 16, right: 16),
        decoration: BoxDecoration(
          color: light ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFF111214), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: homeText(14, FontWeight.w600, light ? const Color(0xFF111214) : Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Decorative stack of cards peeking in from the right edge.
class _CardFan extends StatelessWidget {
  const _CardFan();

  static Widget _card(List<Color> colors, double height) => Container(
        width: 122,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 146,
        height: 176,
        child: Stack(
          children: [
            Positioned(
                left: 0, top: 6, child: _card(const [Color(0xFFFFEE58), Color(0xFFF2D930)], 164)),
            Positioned(
                left: 9, top: 3, child: _card(const [Color(0xFF3BE8A0), Color(0xFF1FC8D8)], 170)),
            Positioned(
                left: 22, top: 0, child: _card(const [Color(0xFF38A7FF), Color(0xFF1570EF)], 176)),
          ],
        ),
      ),
    );
  }
}

// ─── Safe Daily Spend Card ────────────────────────────────────

class _SafeSpendCard extends StatelessWidget {
  const _SafeSpendCard({required this.state});
  final DashboardState state;

  Color get _statusColor {
    final s = state;
    if (s.safeDailySpend <= 0) {
      return s.availableFromToday < 0 || s.todaySpent > 0 ? HomeColors.danger : AppColors.success;
    }
    final ratio = s.todaySpent / s.safeDailySpend;
    if (ratio <= 0.6) return AppColors.success;
    if (ratio <= 0.9) return AppColors.warning;
    return HomeColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final color = _statusColor;
    final progress = s.safeDailySpend > 0
        ? (s.todaySpent / s.safeDailySpend).clamp(0.0, 1.0)
        : (s.todaySpent > 0 ? 1.0 : 0.0);
    final leftToday = s.safeDailySpend - s.todaySpent;
    final usedUp = s.availableFromToday < 0;
    final ok = !usedUp && leftToday >= 0;

    return GlassTile(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LimitBreakdownSheet(state: s),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Safe to spend today',
                        style: homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(width: 5),
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.white.withValues(alpha: 0.4)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(CurrencyFormatter.format(s.safeDailySpend),
                        style: homeText(26, FontWeight.w600, Colors.white, spacing: -0.5)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        usedUp
                            ? 'Budget used up'
                            : ok
                                ? s.todaySpent > 0
                                    ? '${CurrencyFormatter.format(leftToday)} left'
                                    : 'Nothing spent yet'
                                : '${CurrencyFormatter.format(-leftToday)} over',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: homeText(13, FontWeight.w600,
                            ok ? Colors.white.withValues(alpha: 0.85) : color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _limitChangeLine(s),
                  style: homeText(12, FontWeight.w400, Colors.white.withValues(alpha: 0.45),
                      height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              GradientProgressRing(
                progress: progress,
                color: color,
                size: 64,
                strokeWidth: 6,
                trackColor: Colors.white.withValues(alpha: 0.1),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(progress * 100).toStringAsFixed(0)}%',
                      style: homeText(14, FontWeight.w700, Colors.white)),
                  Text('spent',
                      style: homeText(9, FontWeight.w500, Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One line under today's limit saying why it moved since yesterday.
String _limitChangeLine(DashboardState s) {
  final fmt = CurrencyFormatter.format;
  final c = s.limitChange;
  if (s.safeDailySpend <= 0) return 'Tap to see how it\'s worked out';
  if (c == null) {
    return s.daysElapsed <= 1
        ? 'New cycle: budget spread over ${s.daysRemaining} days'
        : 'Tap to see how it\'s worked out';
  }

  final under = c.underBy.round();
  final perDay = c.fromYesterday.round().abs();
  final direction = under > 0 ? 'higher' : 'lower';

  // With new income today, "today's is lower" could be false overall, so
  // say what each cause did instead of comparing with yesterday's limit.
  final fromIncome = c.fromIncome.round();
  if (fromIncome >= 1) {
    final yesterdayPart = perDay == 0
        ? ''
        : c.yesterdaySpent == 0
            ? ' Spending nothing yesterday added ${fmt(perDay.toDouble())}.'
            : under > 0
                ? ' Spending ${fmt(under.toDouble())} under yesterday added ${fmt(perDay.toDouble())}.'
                : ' Going ${fmt(-under.toDouble())} over yesterday took off ${fmt(perDay.toDouble())}.';
    return 'Today\'s income added ${fmt(fromIncome.toDouble())} to your limit.$yesterdayPart';
  }

  if (c.yesterdaySpent == 0) {
    return perDay == 0
        ? 'Nothing spent yesterday'
        : 'Nothing spent yesterday, so today\'s is ${fmt(perDay.toDouble())} higher';
  }
  if (under == 0) return 'You spent right on yesterday\'s limit';
  final what = under > 0
      ? 'You spent ${fmt(under.toDouble())} under yesterday\'s limit'
      : 'You went ${fmt(-under.toDouble())} over yesterday\'s limit';
  if (perDay == 0) return what;
  return '$what, so today\'s is ${fmt(perDay.toDouble())} $direction';
}

// ─── Spending Card ────────────────────────────────────────────

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.total, required this.expenses});
  final double total;
  final List<ExpenseModel> expenses;

  // Where the category circles sit, measured from the card's top-right
  // corner: (centre from right, centre from top, diameter). Biggest first.
  static const _slots = <(double, double, double)>[
    (98, 44, 44),
    (52, 12, 30),
    (17, 38, 32),
    (55, 52, 26),
    (88, 3, 22),
  ];
  static const _badge = (12.0, 5.0, 22.0);

  static Widget _at((double, double, double) slot, Widget child) => Positioned(
        right: slot.$1 - slot.$3 / 2,
        top: slot.$2 - slot.$3 / 2,
        width: slot.$3,
        height: slot.$3,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, double>{};
    for (final e in expenses.where((e) => e.isExpense)) {
      byCategory.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final ranked = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shown = ranked.take(_slots.length).map((e) => e.key).toList();
    final extra = ranked.length - shown.length;

    return Bounceable(
      onTap: () => context.go('/insights'),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: HomeColors.glass,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HomeColors.glassBorder),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 18,
              top: 0,
              bottom: 0,
              right: 130,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spending',
                      style: homeText(15, FontWeight.w400, Colors.white.withValues(alpha: 0.65))),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(CurrencyFormatter.format(total),
                        style: homeText(20, FontWeight.w600, Colors.white)),
                  ),
                ],
              ),
            ),
            // Paint the biggest circle last so it sits on top.
            for (var i = shown.length - 1; i >= 0; i--)
              _at(_slots[i], CategoryAvatar(category: shown[i], size: _slots[i].$3, onDark: true)),
            if (extra > 0)
              _at(
                _badge,
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3D42),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1.5),
                  ),
                  child: Text('+$extra', style: homeText(9, FontWeight.w700, Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Limit Breakdown Sheet ────────────────────────────────────

class _LimitBreakdownSheet extends StatelessWidget {
  const _LimitBreakdownSheet({required this.state});
  final DashboardState state;

  static String _fmt(num v) => CurrencyFormatter.format(v.toDouble());
  static String _signed(int v) => v >= 0 ? '+ ${_fmt(v)}' : '− ${_fmt(-v)}';

  Widget _row(String label, String value,
      {String? sub, bool bold = false, Color? color}) {
    final style = (bold ? AppTypography.bodyMedium : AppTypography.bodySmall).copyWith(
      color: color ?? AppColors.textPrimary,
      fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (sub != null)
                  Text(sub,
                      style: AppTypography.captionSmall
                          .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _note(String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: AppTypography.captionSmall
              .copyWith(color: color ?? AppColors.textSecondary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = state;
    final c = s.limitChange;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How today\'s limit is worked out',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              _row('Monthly budget', _fmt(s.spendableBudget),
                  sub: s.savingsGoal > 0
                      ? '${_fmt(s.monthlyAllowance)} allowance − ${_fmt(s.savingsGoal)} savings goal'
                      : null),
              if (s.totalIncome > 0)
                _row('Extra income', '+ ${_fmt(s.totalIncome)}'),
              if (s.billsThisCycle > 0)
                _row('Bills this cycle', '− ${_fmt(s.billsThisCycle)}',
                    sub: '${_fmt(s.paidBills)} paid · ${_fmt(s.upcomingBills)} still to pay'),
              _row('Spent before today', '− ${_fmt(s.everydaySpentBeforeToday)}',
                  sub: 'Everyday spending this cycle'),
              const Divider(height: 16),
              _row('Left from today', _fmt(s.availableFromToday), bold: true),
              _row('Days left, including today', '÷ ${s.daysRemaining}'),
              const Divider(height: 16),
              _row('Today\'s limit', _fmt(s.safeDailySpend), bold: true),
              if (s.availableFromToday < 0)
                _note(
                  'You\'re ${_fmt(-s.availableFromToday)} over budget for this cycle, '
                  'so there\'s nothing left for everyday spending.',
                  color: AppColors.danger,
                ),

              if (c != null) ...() {
                // Round each step so the column visibly adds up.
                final yesterday = c.yesterdayLimit.round();
                final today = s.safeDailySpend.round();
                final fromIncome = c.fromIncome.round();
                final fromYesterday = today - yesterday - fromIncome;
                final under = c.underBy.round();
                final spentLabel = c.yesterdaySpent == 0
                    ? 'Nothing spent yesterday'
                    : under == 0
                        ? 'Spent ${_fmt(c.yesterdaySpent)}, right on the limit'
                        : 'Spent ${_fmt(c.yesterdaySpent)}, ${_fmt(under.abs())} ${under > 0 ? 'under' : 'over'}';
                return <Widget>[
                  const SizedBox(height: 20),
                  Text('Since yesterday',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  _row('Yesterday\'s limit', _fmt(yesterday)),
                  _row(spentLabel, _signed(fromYesterday)),
                  if (c.incomeSinceYesterday > 0)
                    _row('Income added today', _signed(fromIncome),
                        sub: '${_fmt(c.incomeSinceYesterday)} spread over ${c.daysLeft} days'),
                  _row('Today\'s limit', _fmt(today), bold: true),
                  if (under != 0)
                    _note(
                      'Whatever you don\'t spend is shared across the ${c.daysLeft} days left. '
                      '${under > 0 ? 'Saving' : 'Going over by'} ${_fmt(under.abs())} yesterday '
                      'moves each of them by ${_fmt(fromYesterday.abs())}.',
                    ),
                ];
              }(),

              const SizedBox(height: 16),
              _note(
                'Bill payments don\'t count against your daily limit. '
                'They\'re set aside at the start of the cycle.',
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming Bills Card ──────────────────────────────────────

class _UpcomingBillsCard extends ConsumerWidget {
  const _UpcomingBillsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(recurringBillsProvider);
    // Hidden until bills load, and if they can't (e.g. migration not run).
    if (!billsAsync.hasValue) return const SizedBox.shrink();

    final statuses = ref.watch(billStatusesProvider);
    if (statuses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SheetTile(
          onTap: () => context.push('/bills'),
          child: Row(
            children: [
              const Text('🧾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add your bills',
                        style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text(
                      'Rent, recharges and subscriptions get set aside up front, '
                      'so your daily limit stays steady.',
                      style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      );
    }

    final pending = statuses.where((s) => s.isPending).toList();
    final reserved = pending.fold<double>(0, (sum, s) => sum + s.reservedAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SheetTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bills this cycle',
                    style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Bounceable(
                  onTap: () => context.push('/bills'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Manage',
                        style: AppTypography.captionSmall.copyWith(
                            color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              pending.isEmpty
                  ? 'All paid for this cycle ✓'
                  : '${CurrencyFormatter.format(reserved)} set aside for '
                      '${pending.length} ${pending.length == 1 ? 'bill' : 'bills'}',
              style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...pending.take(3).map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CategoryAvatar(category: s.bill.category, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.bill.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold)),
                              Text(billStatusText(s),
                                  style: AppTypography.captionSmall.copyWith(
                                      color: billStatusColor(s),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text(CurrencyFormatter.format(s.bill.amount),
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        MarkPaidButton(onTap: () => markBillPaid(context, ref, s.bill)),
                      ],
                    ),
                  )),
              if (pending.length > 3)
                Text('+ ${pending.length - 3} more',
                    style: AppTypography.captionSmall.copyWith(color: AppColors.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Smart Guidance Card ──────────────────────────────────────

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.messages});
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SheetTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  'Smart Tips',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...messages.map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                            color: AppColors.accentPrimary,
                            fontWeight: FontWeight.bold,
                          )),
                      Expanded(
                        child: Text(
                          msg,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Ring ────────────────────────────────────────────

class GradientProgressRing extends StatelessWidget {
  const GradientProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    this.strokeWidth = 12.0,
    this.trackColor = const Color(0xFFEFF1F4),
  });

  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: color,
          strokeWidth: strokeWidth,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final angle = 2 * 3.141592653589793 * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.141592653589793 / 2,
        angle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
