import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/gradient_progress_bar.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/bounceable.dart';
import '../providers/dashboard_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../expenses/data/models/expense_model.dart';
import '../../auth/providers/auth_provider.dart';

final selectedAnalyticsDateProvider = StateProvider<DateTime?>((ref) => null);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardStateProvider);
    final guidance = ref.watch(smartGuidanceProvider);
    final recentExpenses = ref.watch(recentExpensesProvider);
    final user = ref.watch(currentUserProvider);
    final selectedDate = ref.watch(selectedAnalyticsDateProvider);
    final allExpensesAsync = ref.watch(currentMonthExpensesProvider);

    final fullName = user?.userMetadata?['full_name'] as String?;
    final firstName = fullName != null && fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').first
        : 'Terry';

    // Filter transactions based on selection
    final List<ExpenseModel> transactionsToShow;
    bool hasNoSelectedTransactions = false;

    if (selectedDate != null) {
      final allList = allExpensesAsync.value ?? [];
      transactionsToShow = allList.where((e) {
        return e.expenseDate.day == selectedDate.day &&
            e.expenseDate.month == selectedDate.month &&
            e.expenseDate.year == selectedDate.year;
      }).toList();
      hasNoSelectedTransactions = transactionsToShow.isEmpty;
    } else {
      transactionsToShow = recentExpenses;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header (Mockup Screen 1 style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Avatar (Left)
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
                    // Centered Title "Home"
                    Expanded(
                      child: Center(
                        child: Text(
                          'Home',
                          style: AppTypography.title.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Notification Bell with Badge (Right)
                    Stack(
                      children: [
                        Bounceable(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No new notifications')),
                            );
                          },
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
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Balance Card (Mockup Style)
                  _BalanceCard(state: state),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Analytics Monthly Bar Chart (Mockup Style)
                  _AnalyticsBarChart(state: state),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Safe Daily Spend
                  _SafeSpendCard(state: state),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Budget Progress
                  _BudgetProgressCard(state: state),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Quick Stats
                  _QuickStatsRow(state: state),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Smart Guidance
                  if (guidance.isNotEmpty) ...[
                    _GuidanceCard(messages: guidance),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 7. Recent Transactions / Expenses
                  if (recentExpenses.isNotEmpty || selectedDate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? 'Transactions on ${AppDateUtils.formatRelative(selectedDate)}'
                              : 'Transactions',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (selectedDate != null)
                          Bounceable(
                            onTap: () {
                              ref.read(selectedAnalyticsDateProvider.notifier).state = null;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'Show Recent',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Bounceable(
                            onTap: () {
                              context.go('/expenses');
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'View All',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (hasNoSelectedTransactions)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Column(
                          children: [
                            const Text('💸', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              'No transactions on this day',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...transactionsToShow.map(
                        (e) => _ExpenseTile(expense: e, ref: ref),
                      ),
                  ],
                  const SizedBox(height: 100), // Bottom padding for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.state});
  final DashboardState state;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _isObscured = false;

  @override
  Widget build(BuildContext context) {
    final balanceText = _isObscured 
        ? '••••••' 
        : CurrencyFormatter.format(widget.state.remainingBalance);

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF261D4C),
            Color(0xFF0F1128),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1128).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WavyCardPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balanceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isObscured = !_isObscured),
                      icon: Icon(
                        _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2644  7545  3867  1965',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A26).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9E1B).withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavyCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.75,
      size.width,
      size.height * 0.4,
    );
    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.5,
      size.width * 0.65,
      size.height * 0.7,
    );
    path2.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.85,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Analytics Bar Chart ──────────────────────────────────────

class _AnalyticsBarChart extends ConsumerWidget {
  const _AnalyticsBarChart({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(currentMonthExpensesProvider);
    final currentYear = DateTime.now().year;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orangeAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      'Year - $currentYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          expensesAsync.when(
            data: (expenses) {
              final DateTime now = DateTime.now();
              // Generate last 7 days ending today (index 6 is today)
              final List<DateTime> last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
              final List<double> dailyValues = List.generate(7, (i) => 0.0);

              for (final exp in expenses) {
                if (exp.type == 'expense') {
                  final date = exp.expenseDate;
                  for (int i = 0; i < 7; i++) {
                    final day = last7Days[i];
                    if (date.day == day.day && date.month == day.month && date.year == day.year) {
                      dailyValues[i] += exp.amount;
                    }
                  }
                }
              }

              final double maxValue = dailyValues.reduce((a, b) => a > b ? a : b);
              final double effectiveMax = maxValue > 0 ? maxValue : 1000.0;

              final List<String> daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final List<String> labels = last7Days.map((d) {
                return daysOfWeek[d.weekday - 1];
              }).toList();

              final selectedDate = ref.watch(selectedAnalyticsDateProvider);
              return SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final val = dailyValues[index];
                    final label = labels[index];
                    final date = last7Days[index];
                    final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
                    final isSelected = selectedDate != null &&
                        date.day == selectedDate.day &&
                        date.month == selectedDate.month &&
                        date.year == selectedDate.year;

                    final pct = val / effectiveMax;
                    final barHeight = (pct * 90).clamp(4.0, 90.0);

                    final Color barColor;
                    if (isSelected) {
                      barColor = AppColors.orangeAccent;
                    } else if (isToday) {
                      barColor = const Color(0xFF6C25E9);
                    } else {
                      barColor = const Color(0xFFE4E6EA);
                    }

                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          ref.read(selectedAnalyticsDateProvider.notifier).state = null;
                        } else {
                          ref.read(selectedAnalyticsDateProvider.notifier).state = date;
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (val > 0)
                            Text(
                              CurrencyFormatter.formatCompact(val),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.orangeAccent
                                    : (isToday ? const Color(0xFF6C25E9) : AppColors.textSecondary),
                                fontSize: 8,
                                fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                              ),
                            )
                          else
                            Text(
                              '₹0',
                              style: TextStyle(
                                color: AppColors.textTertiary.withValues(alpha: 0.5),
                                fontSize: 8,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            width: 14,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.orangeAccent
                                  : (isToday ? const Color(0xFF6C25E9) : AppColors.textSecondary),
                              fontSize: 10,
                              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentPrimary),
              ),
            ),
            error: (e, _) => SizedBox(
              height: 150,
              child: Center(
                child: Text('Unable to load chart data', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Safe Daily Spend Card ────────────────────────────────────

class _SafeSpendCard extends StatelessWidget {
  const _SafeSpendCard({required this.state});
  final DashboardState state;

  Color get _statusColor {
    final ratio = state.safeDailySpend > 0 ? (state.todaySpent / state.safeDailySpend) : 0.0;
    if (ratio <= 0.6) {
      return AppColors.success;
    } else if (ratio <= 0.9) {
      return AppColors.warning;
    }
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final progress = state.safeDailySpend > 0 
        ? (state.todaySpent / state.safeDailySpend).clamp(0.0, 1.0) 
        : 0.0;
    final remainingToday = state.safeDailySpend - state.todaySpent;

    return GlassCard(
      borderColor: _statusColor.withValues(alpha: 0.25),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: _statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Safe Daily Spend',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedCounter(
                  value: state.safeDailySpend,
                  style: AppTypography.display.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'allocated per day',
                  style: AppTypography.captionSmall.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.todaySpent > 0
                      ? 'Spent today: ${CurrencyFormatter.format(state.todaySpent)}'
                      : 'No spending today yet!',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  remainingToday >= 0
                      ? '${CurrencyFormatter.format(remainingToday)} left for today'
                      : '${CurrencyFormatter.format(remainingToday.abs())} over today\'s limit!',
                  style: AppTypography.captionSmall.copyWith(
                    color: remainingToday >= 0 ? AppColors.textSecondary : AppColors.danger,
                    fontWeight: remainingToday >= 0 ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              GradientProgressRing(
                progress: progress,
                color: _statusColor,
                size: 96,
                strokeWidth: 10,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: AppTypography.numericMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                  Text(
                    'spent',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GradientProgressRing extends StatelessWidget {
  const GradientProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    this.strokeWidth = 12.0,
  });

  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;

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
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFEFF1F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
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
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ─── Budget Progress Card ─────────────────────────────────────

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Used',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(state.spendPercentage * 100).toStringAsFixed(0)}%',
                  style: AppTypography.captionSmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GradientProgressBar(
            progress: state.spendPercentage,
            height: 10,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(state.totalSpent)} spent',
                style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${CurrencyFormatter.format(state.spendableBudget)} budget',
                style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    if (state.spendPercentage <= 0.5) return AppColors.success;
    if (state.spendPercentage <= 0.75) return AppColors.warning;
    return AppColors.danger;
  }
}

// ─── Quick Stats Row ──────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.calendar_today_rounded,
            label: 'Days Left',
            value: '${state.daysRemaining}',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatItem(
            icon: Icons.trending_up_rounded,
            label: 'Predicted',
            value: CurrencyFormatter.format(state.predictedEndBalance),
            color: state.predictedEndBalance >= 0
                ? AppColors.success
                : AppColors.danger,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatItem(
            icon: state.isSavingsOnTrack
                ? Icons.check_circle_rounded
                : Icons.warning_rounded,
            label: 'Savings',
            value: state.isSavingsOnTrack ? 'On Track' : 'At Risk',
            color: state.isSavingsOnTrack
                ? AppColors.success
                : AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
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
    return GlassCard(
      borderColor: AppColors.accentPrimary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.accentPrimary),
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
          const SizedBox(height: AppSpacing.md),
          ...messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
    );
  }
}

// ─── Expense Tile ─────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.ref});
  final dynamic expense;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) {
        ref.read(currentMonthExpensesProvider.notifier).deleteExpense(
              expense.id,
            );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CategoryIcon(category: expense.category),
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
                    ),
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty)
                    Text(
                      expense.note!,
                      style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.success.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(expense.amount)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isIncome
                          ? AppColors.success
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateUtils.formatRelative(expense.expenseDate),
                  style: AppTypography.captionSmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
