import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/bounceable.dart';
import '../../../core/widgets/home_style.dart';
import '../providers/expense_provider.dart';

/// Glass "November 2026 ▾" pill for the dark header.
class MonthPill extends StatelessWidget {
  const MonthPill({super.key, required this.month, required this.onTap});
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${AppDateUtils.monthName(month.month)} ${month.year}';
    return Semantics(
      button: true,
      label: 'Change month, $label',
      child: Bounceable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: homeText(14, FontWeight.w600, Colors.white)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet for picking which cycle the Expenses and Insights tabs show.
/// Future months are disabled.
void showCycleMonthPicker(
  BuildContext context,
  WidgetRef ref, {
  required DateTime current,
  required int cycleStartDay,
}) {
  final thisCycle = AppDateUtils.startOfCycle(DateTime.now(), cycleStartDay);
  final thisMonth = DateTime(thisCycle.year, thisCycle.month);
  final viewingThis = current.year == thisMonth.year && current.month == thisMonth.month;
  var year = current.year;

  void pick(BuildContext sheetContext, DateTime month) {
    ref.read(selectedMonthProvider.notifier).state = month;
    Navigator.pop(sheetContext);
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        return Container(
          padding:
              EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.paddingOf(sheetContext).bottom),
          decoration: const BoxDecoration(
            color: HomeColors.sheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E5E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Bounceable(
                    onTap: () => setSheet(() => year--),
                    child: const RoundIcon(icon: Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text('$year',
                        textAlign: TextAlign.center,
                        style: homeText(18, FontWeight.w700, HomeColors.ink)),
                  ),
                  Opacity(
                    opacity: year < thisMonth.year ? 1 : 0.35,
                    child: Bounceable(
                      onTap: year < thisMonth.year ? () => setSheet(() => year++) : null,
                      child: const RoundIcon(icon: Icons.chevron_right_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: 12,
                itemBuilder: (_, index) {
                  final month = DateTime(year, index + 1);
                  final isSelected = current.year == year && current.month == index + 1;
                  final isThis = month == thisMonth;
                  final isFuture = month.isAfter(thisMonth);
                  return Bounceable(
                    onTap: isFuture ? null : () => pick(sheetContext, month),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? HomeColors.ink : HomeColors.tile,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(month),
                            style: homeText(
                              14,
                              FontWeight.w600,
                              isSelected
                                  ? Colors.white
                                  : isFuture
                                      ? HomeColors.muted.withValues(alpha: 0.6)
                                      : HomeColors.ink,
                            ),
                          ),
                          if (isThis) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (!viewingThis) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => pick(sheetContext, thisMonth),
                  child: Text('Back to this cycle',
                      style: homeText(14, FontWeight.w600, HomeColors.ink)),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
