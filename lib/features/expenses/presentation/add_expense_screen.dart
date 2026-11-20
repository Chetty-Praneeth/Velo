import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/bounceable.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../data/models/custom_category_model.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialType});

  final String? initialType;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  String _amount = '';
  String _selectedCategory = 'Food';
  String _type = 'expense'; // 'expense' or 'income'
  final _noteController = TextEditingController();
  bool _showNote = false;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  Color get _accentColor =>
      _type == 'income' ? AppColors.success : AppColors.accentPrimary;

  LinearGradient get _buttonGradient =>
      _type == 'income' ? AppColors.successGradient : AppColors.primaryGradient;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null &&
        (widget.initialType == 'expense' || widget.initialType == 'income')) {
      _type = widget.initialType!;
      _selectedCategory = _type == 'income' ? 'Allowance' : 'Food';
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    HapticFeedback.lightImpact();
    if (_amount.length > 7) return;
    if (digit == '.' && _amount.contains('.')) return;
    setState(() => _amount += digit);
  }

  void _removeDigit() {
    HapticFeedback.lightImpact();
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    }
  }

  Future<void> _saveExpense() async {
    final amt = double.tryParse(_amount);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(currentMonthExpensesProvider.notifier).addExpense(
            amount: amt,
            category: _selectedCategory,
            note: _noteController.text.isNotEmpty
                ? _noteController.text
                : null,
            type: _type,
          );
      if (mounted) {
        HapticFeedback.mediumImpact();
        context.pop();
      }
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Text(_type == 'income' ? 'Add Income' : 'Add Expense',
                        style: AppTypography.titleSmall),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Expense / Income Segmented Control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = 'expense';
                              _selectedCategory = 'Food';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _type == 'expense'
                                  ? AppColors.accentPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Expense',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _type == 'expense'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: _type == 'expense'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = 'income';
                              _selectedCategory = 'Allowance';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _type == 'income'
                                  ? AppColors.success
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Income',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _type == 'income'
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: _type == 'income'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Amount Display
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _amount.isEmpty ? '₹0' : '₹$_amount',
                        style: AppTypography.numericHero.copyWith(
                          color: _amount.isEmpty
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          fontSize: _amount.length > 5 ? 40 : 48,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Category chip
                      Builder(
                        builder: (context) {
                          final isIncome = _type == 'income';
                          final customCategories = ref.watch(customCategoriesProvider).value ?? [];
                          CustomCategoryModel? customMatch;
                          for (final c in customCategories) {
                            if (c.name.toLowerCase().trim() == _selectedCategory.toLowerCase().trim()) {
                              customMatch = c;
                              break;
                            }
                          }

                          final Color chipTextColor;
                          final Color chipBgColor;
                          final Color chipBorderColor;
                          final Widget iconWidget;

                          if (isIncome) {
                            final catData = CategoryIcon.getCategoryData(_selectedCategory);
                            chipTextColor = AppColors.success;
                            chipBgColor = AppColors.success.withValues(alpha: 0.12);
                            chipBorderColor = AppColors.success.withValues(alpha: 0.3);
                            iconWidget = Icon(catData.icon, size: 16, color: chipTextColor);
                          } else if (customMatch != null) {
                            final customColor = _hexToColor(customMatch.color);
                            chipTextColor = customColor;
                            chipBgColor = customColor.withValues(alpha: 0.12);
                            chipBorderColor = customColor.withValues(alpha: 0.3);
                            iconWidget = Text(customMatch.iconName, style: const TextStyle(fontSize: 14));
                          } else {
                            final catData = CategoryIcon.getCategoryData(_selectedCategory);
                            chipTextColor = AppColors.textPrimary;
                            chipBgColor = const Color(0xFFEFF1F4);
                            chipBorderColor = AppColors.glassBorder;
                            iconWidget = Icon(catData.icon, size: 16, color: chipTextColor);
                          }

                          return Bounceable(
                            onTap: () => _showCategoryPicker(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: chipBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: chipBorderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  iconWidget,
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCategory,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: chipTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Note toggle
                      if (!_showNote)
                        Bounceable(
                          onTap: () => setState(() => _showNote = true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              '+ Add note',
                              style: AppTypography.caption.copyWith(
                                color: _accentColor,
                              ),
                            ),
                          ),
                        ),
                      if (_showNote)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: TextField(
                            controller: _noteController,
                            textAlign: TextAlign.center,
                            style: AppTypography.body,
                            decoration: InputDecoration(
                              hintText: 'e.g. Coffee with friends',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                  color: AppColors.textHint),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Number Pad + Save
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(color: AppColors.glassBorder),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: _buildNumberPad(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassButton(
                        label: _type == 'income' ? 'Save Income' : 'Save Expense',
                        isFullWidth: true,
                        isLoading: _isLoading,
                        gradient: _buttonGradient,
                        onPressed: _isLoading ? null : _saveExpense,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow(['.', '0', '⌫']),
      ].map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys
          .map((key) => Expanded(
                child: _NumKey(
                  label: key,
                  onTap: () {
                    if (key == '⌫') {
                      _removeDigit();
                    } else {
                      _addDigit(key);
                    }
                  },
                ),
              ))
          .toList(),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final customCats = ref.read(customCategoriesProvider).value ?? [];
        final categoriesToDisplay = _type == 'income'
            ? CategoryIcon.defaultIncomeCategories
            : [...CategoryIcon.defaultCategories, ...customCats.map((c) => c.name)];

        return Container(
          padding: const EdgeInsets.all(20),
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
              Text('Select Category', style: AppTypography.titleSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoriesToDisplay.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  
                  // Resolve color and icon dynamically
                  final Color catColor;
                  final Widget catIcon;
                  CustomCategoryModel? customMatch;
                  for (final c in customCats) {
                    if (c.name.toLowerCase().trim() == cat.toLowerCase().trim()) {
                      customMatch = c;
                      break;
                    }
                  }

                  if (customMatch != null) {
                    catColor = _hexToColor(customMatch.color);
                    catIcon = Text(customMatch.iconName, style: const TextStyle(fontSize: 16));
                  } else {
                    final data = CategoryIcon.getCategoryData(cat);
                    catColor = _type == 'income' ? AppColors.success : data.color;
                    catIcon = Icon(data.icon, size: 16, color: catColor);
                  }

                  return Bounceable(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.2)
                            : AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? catColor
                              : AppColors.glassBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          catIcon,
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: AppTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? catColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    return Bounceable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6F8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                )
              : Text(
                  label,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
        ),
      ),
    );
  }
}
