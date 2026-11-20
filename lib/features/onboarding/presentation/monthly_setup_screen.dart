import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class MonthlySetupScreen extends ConsumerStatefulWidget {
  const MonthlySetupScreen({super.key});

  @override
  ConsumerState<MonthlySetupScreen> createState() => _MonthlySetupScreenState();
}

class _MonthlySetupScreenState extends ConsumerState<MonthlySetupScreen>
    with SingleTickerProviderStateMixin {
  final _allowanceController = TextEditingController();
  final _savingsController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _allowanceController.dispose();
    _savingsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  double get _allowance =>
      double.tryParse(_allowanceController.text.replaceAll(',', '')) ?? 0;
  double get _savings =>
      double.tryParse(_savingsController.text.replaceAll(',', '')) ?? 0;
  double get _spendable => _allowance - _savings;

  Future<void> _handleSave() async {
    if (_allowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your monthly allowance')),
      );
      return;
    }
    if (_savings >= _allowance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Savings goal must be less than allowance')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(currentBudgetProvider.notifier).saveBudget(
            monthlyAllowance: _allowance,
            savingsGoal: _savings,
          );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1128),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.huge),
                  // Header
                  Text('Monthly Setup', style: AppTypography.headline),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Set your budget for this month to get started.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Allowance Input
                  _buildLabel('Monthly Allowance / Income'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAmountField(
                    controller: _allowanceController,
                    hint: 'e.g. 10000',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Savings Goal Input
                  _buildLabel('Savings Goal'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAmountField(
                    controller: _savingsController,
                    hint: 'e.g. 2000',
                    icon: Icons.savings_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Spendable Budget Display
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _allowanceController,
                      _savingsController,
                    ]),
                    builder: (context, _) {
                      return GlassCard(
                        gradient: _spendable > 0
                            ? LinearGradient(
                                colors: [
                                  AppColors.accentPrimary.withValues(alpha: 0.15),
                                  AppColors.accentSecondary.withValues(alpha: 0.08),
                                ],
                              )
                            : null,
                        child: Column(
                          children: [
                            Text(
                              'Your Spendable Budget',
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              CurrencyFormatter.format(
                                  _spendable > 0 ? _spendable : 0),
                              style: AppTypography.display.copyWith(
                                color: _spendable > 0
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                            ),
                            if (_spendable > 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${CurrencyFormatter.format(_allowance)} allowance − ${CurrencyFormatter.format(_savings)} savings',
                                style: AppTypography.captionSmall,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Save Button
                  GlassButton(
                    label: 'Start Tracking',
                    isFullWidth: true,
                    isLoading: _isLoading,
                    gradient: AppColors.primaryGradient,
                    onPressed: _isLoading ? null : _handleSave,
                    icon: Icons.rocket_launch_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTypography.headlineSmall,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
        prefixText: '₹ ',
        prefixStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.accentPrimary,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
