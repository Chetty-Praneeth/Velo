import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/glass_card.dart';
import '../../expenses/providers/category_provider.dart';
import '../data/models/recurring_bill_model.dart';
import '../domain/bill_status.dart';
import '../providers/recurring_bill_provider.dart';
import 'bill_widgets.dart';

class RecurringBillsScreen extends ConsumerWidget {
  const RecurringBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(recurringBillsProvider);
    final statuses = ref.watch(billStatusesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Bounceable(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.accentPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Bills & Subscriptions',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Content ──────────────────────────────────────────────
            Expanded(
              child: billsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _LoadError(
                  error: e,
                  onRetry: () => ref.read(recurringBillsProvider.notifier).load(),
                ),
                data: (_) => ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _SummaryCard(statuses: statuses),
                    const SizedBox(height: AppSpacing.md),
                    if (statuses.isEmpty)
                      const _EmptyState()
                    else
                      ...statuses.map((s) => _BillTile(status: s)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: billsAsync.hasError
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Bounceable(
                  onTap: () => showBillSheet(context),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Add Bill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Opens the add sheet, or the edit sheet when [bill] is given.
void showBillSheet(BuildContext context, [RecurringBillModel? bill]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BillSheet(bill: bill),
  );
}

// ─── Summary ──────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.statuses});
  final List<BillStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final monthly = statuses
        .where((s) => s.bill.isActive)
        .fold<double>(0, (sum, s) => sum + s.bill.amount);
    final toPay = statuses.fold<double>(0, (sum, s) => sum + s.reservedAmount);
    final paid = statuses
        .where((s) => s.isPaid)
        .fold<double>(0, (sum, s) => sum + s.payment!.amount);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Still to pay this cycle',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(toPay),
            style: AppTypography.display.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(paid)} paid · ${CurrencyFormatter.format(monthly)} a month in total',
            style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bills are set aside from your budget at the start of each cycle, '
            'so your safe daily spend only covers everyday spending and '
            "doesn't drop when a bill is paid.",
            style: AppTypography.captionSmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          const Text('🧾', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No bills yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add rent, your phone recharge or subscriptions like Spotify.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Couldn't load your bills",
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: AppTypography.captionSmall.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

// ─── Bill Tile ────────────────────────────────────────────────

class _BillTile extends ConsumerWidget {
  const _BillTile({required this.status});
  final BillStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = status.bill;

    return Bounceable(
      onTap: () => showBillSheet(context, bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: bill.isActive ? 1 : 0.4,
              child: CategoryIcon(category: bill.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${CurrencyFormatter.format(bill.amount)} · every month on the ${ordinal(bill.dueDay)}',
                    style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    billStatusText(status),
                    style: AppTypography.captionSmall.copyWith(
                      color: billStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (status.isPending) ...[
              const SizedBox(width: 8),
              MarkPaidButton(onTap: () => markBillPaid(context, ref, bill)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit Sheet ─────────────────────────────────────────

class _BillSheet extends ConsumerStatefulWidget {
  const _BillSheet({this.bill});
  final RecurringBillModel? bill;

  @override
  ConsumerState<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends ConsumerState<_BillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late String _category;
  late int _dueDay;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.bill != null;

  /// Quick-fill: name → category.
  static const _suggestions = {
    'Rent': 'Bills',
    'Phone recharge': 'Bills',
    'Wi-Fi': 'Bills',
    'Spotify': 'Subscriptions',
    'Netflix': 'Subscriptions',
    'Gym': 'Health',
  };

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _name = TextEditingController(text: bill?.name ?? '');
    _amount = TextEditingController(
      text: bill == null
          ? ''
          : (bill.amount == bill.amount.roundToDouble()
              ? bill.amount.toStringAsFixed(0)
              : bill.amount.toString()),
    );
    _category = bill?.category ?? 'Bills';
    _dueDay = bill?.dueDay ?? DateTime.now().day;
    _isActive = bill?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  InputDecoration _input(String hint, {String? prefix}) => InputDecoration(
        hintText: hint,
        prefixText: prefix,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: AppTypography.captionSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Bounceable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accentPrimary : AppColors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Shown when adding a bill whose due date has already passed this cycle.
  String? _startsNextCycleHint() {
    if (_isEditing) return null;
    final now = DateTime.now();
    final cycleStartDay = ref.read(cycleStartDayProvider);
    if (BillSchedule.firstDueThisCycle(now, cycleStartDay, _dueDay)) return null;
    final thisCycle = BillSchedule.dueDateInCycle(now, cycleStartDay, _dueDay);
    final next = BillSchedule.dueDateInNextCycle(now, cycleStartDay, _dueDay);
    return "This cycle's due date (${AppDateUtils.formatCompact(thisCycle)}) has passed, "
        "so it'll be set aside from ${AppDateUtils.formatCompact(next)}. "
        'If you still owe it this cycle, log it as a normal expense.';
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final customCategories =
        ref.watch(customCategoriesProvider).valueOrNull ?? const [];
    // Categories bills usually use come first so the selection is visible.
    const billFirst = ['Bills', 'Subscriptions', 'Health', 'Education'];
    final categories = [
      ...billFirst,
      ...CategoryIcon.defaultCategories.where((c) => !billFirst.contains(c)),
      ...customCategories.map((c) => c.name),
    ];
    if (!categories.contains(_category)) categories.insert(0, _category);
    final hint = _startsNextCycleHint();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + keyboardHeight),
      child: Form(
        key: _formKey,
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
                _isEditing ? 'Edit Bill' : 'New Bill',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              if (!_isEditing) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _suggestions.entries
                        .map((s) => _chip(s.key, _name.text == s.key, () {
                              setState(() {
                                _name.text = s.key;
                                _category = s.value;
                              });
                            }))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                decoration: _input('Name (e.g. Rent)'),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                decoration: _input('Amount', prefix: '₹ '),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  return (amount == null || amount <= 0) ? 'Enter a valid amount' : null;
                },
              ),
              const SizedBox(height: 20),

              _label('Due date'),
              Row(
                children: [
                  Text('Every month on the',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _dueDay,
                        menuMaxHeight: 320,
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          for (var d = 1; d <= 31; d++)
                            DropdownMenuItem(value: d, child: Text(ordinal(d))),
                        ],
                        onChanged: (d) => setState(() => _dueDay = d ?? _dueDay),
                      ),
                    ),
                  ),
                ],
              ),
              if (_dueDay > 28)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'In shorter months it falls on the last day.',
                    style: AppTypography.captionSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    hint,
                    style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 20),

              _label('Category'),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories
                      .map((c) => _chip(c, c == _category,
                          () => setState(() => _category = c)))
                      .toList(),
                ),
              ),

              if (_isEditing) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set aside every cycle',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textPrimary)),
                          Text('Turn off to pause it without deleting',
                              style: AppTypography.captionSmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              Bounceable(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditing ? 'Save Changes' : 'Add Bill',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              if (_isEditing)
                Center(
                  child: TextButton(
                    onPressed: _saving ? null : _confirmDelete,
                    child: const Text(
                      'Delete Bill',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(recurringBillsProvider.notifier);
    final name = _name.text.trim();
    final amount = double.parse(_amount.text);

    try {
      if (_isEditing) {
        await notifier.updateBill(widget.bill!.copyWith(
          name: name,
          amount: amount,
          category: _category,
          dueDay: _dueDay,
          isActive: _isActive,
        ));
      } else {
        await notifier.addBill(
          name: name,
          amount: amount,
          category: _category,
          dueDay: _dueDay,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save bill: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final bill = widget.bill!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${bill.name}?'),
        content: const Text(
            "Payments you've already logged stay in your expenses."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(recurringBillsProvider.notifier).deleteBill(bill.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't delete bill: $e")),
        );
      }
    }
  }
}
