import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/bounceable.dart';
import '../data/models/recurring_bill_model.dart';
import '../domain/bill_status.dart';
import '../providers/recurring_bill_provider.dart';

/// 1 → "1st", 22 → "22nd".
String ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

/// Short status line for a bill, e.g. "Due 5 Dec" or "Paid 3 Dec".
String billStatusText(BillStatus s) {
  if (!s.bill.isActive && !s.isPaid) return 'Paused';
  if (s.isPaid) return 'Paid ${AppDateUtils.formatCompact(s.payment!.expenseDate)}';
  if (!s.dueThisCycle) return 'Next due ${AppDateUtils.formatCompact(s.nextCycleDueDate)}';
  if (s.isDueToday) return 'Due today';
  if (s.isOverdue) return 'Overdue · was due ${AppDateUtils.formatCompact(s.dueDate)}';
  return 'Due ${AppDateUtils.formatCompact(s.dueDate)}';
}

Color billStatusColor(BillStatus s) {
  if (s.isPaid) return AppColors.success;
  if (s.isOverdue) return AppColors.danger;
  if (s.isDueToday) return AppColors.warning;
  return AppColors.textTertiary;
}

/// Logs this cycle's payment for [bill] and confirms with a snackbar.
Future<void> markBillPaid(
    BuildContext context, WidgetRef ref, RecurringBillModel bill) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(recurringBillsProvider.notifier).markPaid(bill);
    messenger.showSnackBar(SnackBar(
      content: Text('${bill.name} paid · ${CurrencyFormatter.format(bill.amount)} logged'),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Couldn\'t mark as paid: $e')));
  }
}

/// Small black "Mark paid" pill.
class MarkPaidButton extends StatelessWidget {
  const MarkPaidButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accentPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Mark paid',
          style: AppTypography.captionSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
