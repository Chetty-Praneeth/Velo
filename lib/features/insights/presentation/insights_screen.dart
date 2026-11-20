import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/bounceable.dart';
import '../../expenses/providers/expense_provider.dart';
import '../providers/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final cycleStartDay = ref.watch(cycleStartDayProvider);

    final now = DateTime.now();
    final isCurrent = selectedMonth.month == now.month && selectedMonth.year == now.year;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: insightsAsync.when(
          data: (insights) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Bounceable(
                        onTap: () => context.go('/'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_left_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
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
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
              ),

              // Calendar Bar / Date Range Banner
              SliverToBoxAdapter(
                child: isCurrent
                    ? _CalendarBar()
                    : Padding(
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
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SpendSummaryCard(insights: insights, selectedMonth: selectedMonth),
                    const SizedBox(height: AppSpacing.md),
                    _AnalyticsChartCard(insights: insights),
                    const SizedBox(height: AppSpacing.md),
                    _PredictionCard(insights: insights, selectedMonth: selectedMonth, cycleStartDay: cycleStartDay),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPrimary),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insights_rounded, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('Unable to load insights', style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() => selectedYear--),
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                      ),
                      Text('$selectedYear', style: AppTypography.title.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(
                        onPressed: () => setModalState(() => selectedYear++),
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (isToday)
                  Container(
                    width: 32,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.orangeAccent, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${date.day}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ],
                    ),
                  )
                else
                  Text('${date.day}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Spend Summary Card ────────────────────────────────────────

class _SpendSummaryCard extends StatelessWidget {
  const _SpendSummaryCard({required this.insights, required this.selectedMonth});
  final InsightsData insights;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final double totalSpent = insights.totalSpent;
    final double pctSpent = insights.spendPercentage.clamp(0.0, 1.0);
    final double pctRemaining = (1.0 - pctSpent).clamp(0.0, 1.0);

    final String pctSpentText = (pctSpent * 100).toStringAsFixed(2);
    final String pctRemainingText = (pctRemaining * 100).toStringAsFixed(2);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have spent ${CurrencyFormatter.format(totalSpent)} this month.',
            style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppDateUtils.monthName(selectedMonth.month)}, ${selectedMonth.year}',
            style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: (pctSpent * 100).round().clamp(1, 99),
                child: Container(height: 10, decoration: const BoxDecoration(color: Color(0xFF6C25E9), borderRadius: BorderRadius.horizontal(left: Radius.circular(5)))),
              ),
              Expanded(
                flex: (pctRemaining * 100).round().clamp(1, 99),
                child: Container(height: 10, decoration: const BoxDecoration(color: Color(0xFFE4E6EA), borderRadius: BorderRadius.horizontal(right: Radius.circular(5)))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF6C25E9), borderRadius: BorderRadius.circular(8)),
                child: Text('$pctSpentText%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text('$pctRemainingText%', style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Analytics Pie / Donut Chart Card ──────────────────────────

class _AnalyticsChartCard extends StatelessWidget {
  const _AnalyticsChartCard({required this.insights});
  final InsightsData insights;

  @override
  Widget build(BuildContext context) {
    final sortedBreakdown = insights.categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final double total = insights.totalSpent > 0 ? insights.totalSpent : 1.0;
    final hasData = sortedBreakdown.isNotEmpty;
    final colors = [AppColors.orangeAccent, AppColors.accentPrimary, const Color(0xFF6C25E9), AppColors.accentSecondary];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Analytics', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('View All', style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 55,
                sections: hasData
                    ? List.generate(
                        sortedBreakdown.length.clamp(0, 4),
                        (index) {
                          final entry = sortedBreakdown[index];
                          final pct = (entry.value / total * 100);
                          return PieChartSectionData(
                            value: entry.value,
                            color: colors[index % colors.length],
                            radius: 26,
                            title: '${pct.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        },
                      )
                    : [PieChartSectionData(value: 1.0, color: const Color(0xFFEFF1F4), radius: 26, title: '0%', titleStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary))],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('No expenses logged yet.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))))
          else
            Column(
              children: List.generate(
                sortedBreakdown.length.clamp(0, 4),
                (index) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _legendItem(colors[index % colors.length], sortedBreakdown[index].key, sortedBreakdown[index].value)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, double amount) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
        Text(CurrencyFormatter.format(amount), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ─── Prediction Card ──────────────────────────────────────────

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.insights, required this.selectedMonth, required this.cycleStartDay});
  final InsightsData insights;
  final DateTime selectedMonth;
  final int cycleStartDay;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = selectedMonth.month == now.month && selectedMonth.year == now.year;
    final isPositive = insights.predictedEndBalance >= 0;
    final totalDays = AppDateUtils.daysInCycle(selectedMonth, cycleStartDay);

    return GlassCard(
      borderColor: (isPositive ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: isPositive ? AppColors.success : AppColors.danger),
              const SizedBox(width: 8),
              Text(isCurrent ? 'Month-End Prediction' : 'Month-End Actual Outcome', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                Text(
                  isCurrent ? (isPositive ? 'Projected Savings' : 'Projected Deficit') : (isPositive ? 'Final Savings' : 'Final Deficit'),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(insights.predictedEndBalance.abs()),
                  style: AppTypography.numericLarge.copyWith(color: isPositive ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (isPositive ? AppColors.success : AppColors.danger).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    isPositive ? (isCurrent ? '✓ Savings goal achievable' : '✓ Savings goal achieved') : (isCurrent ? '⚠ Budget may be exceeded' : '⚠ Budget exceeded'),
                    style: AppTypography.captionSmall.copyWith(color: isPositive ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Avg/day', CurrencyFormatter.format(insights.avgDailySpend)),
              if (isCurrent) ...[
                _miniStat('Safe/day', CurrencyFormatter.format((insights.spendableBudget - insights.totalSpent).clamp(0.0, double.infinity) / AppDateUtils.daysRemainingInCycle(now, cycleStartDay))),
                _miniStat('Days left', '${AppDateUtils.daysRemainingInCycle(now, cycleStartDay)}'),
              ] else ...[
                _miniStat('Cycle Days', '$totalDays'),
                _miniStat('Days left', '0'),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
