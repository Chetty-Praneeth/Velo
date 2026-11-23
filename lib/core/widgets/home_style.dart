import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_utils.dart';
import 'bounceable.dart';
import 'category_icon.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/bills/providers/recurring_bill_provider.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/expenses/providers/category_provider.dart';

/// Shared look for the main tabs: a dark header over a white sheet.
class HomeColors {
  HomeColors._();
  static const bg = Color(0xFF0E1012);
  static const glow = Color(0xFF2B2F35);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x0FFFFFFF);
  static const sheet = Colors.white;
  static const tile = Color(0xFFF5F6F8);
  static const chip = Color(0xFFF2F3F5);
  static const ink = Color(0xFF26282C);
  static const inkSoft = Color(0xFF55595F);
  static const muted = Color(0xFF9A9FA6);
  static const income = Color(0xFF2F9E5B);
  static const danger = Color(0xFFFF6B6B);
}

TextStyle homeText(double size, FontWeight weight, Color color,
        {double? height, double? spacing}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

/// Page layout: [header] widgets on a dark background, then a white
/// rounded sheet holding [sheet]. Scrolls as one piece.
class DarkSheetPage extends StatelessWidget {
  const DarkSheetPage({super.key, required this.header, required this.sheet});
  final List<Widget> header;
  final List<Widget> sheet;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: HomeColors.sheet,
        body: Stack(
          children: [
            // Dark backdrop so pulling down past the top shows dark, not white.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: media.size.height / 2,
              child: const ColoredBox(color: HomeColors.bg),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: HomeColors.bg,
                      gradient: RadialGradient(
                        center: Alignment(-0.9, -1.0),
                        radius: 1.1,
                        colors: [HomeColors.glow, HomeColors.bg],
                      ),
                    ),
                    padding: EdgeInsets.only(top: media.padding.top + 8, bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: header,
                    ),
                  ),
                  ColoredBox(
                    color: HomeColors.bg,
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: media.size.height * 0.55),
                      decoration: const BoxDecoration(
                        color: HomeColors.sheet,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3E5E8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ...sheet,
                          SizedBox(height: media.padding.bottom + 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar on the left, bell on the right, optional [center] widget.
/// The bell shows a dot when a bill is overdue or due within 3 days.
class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key, this.center});
  final Widget? center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final fullName = (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'T';

    final dueSoon = ref
        .watch(billStatusesProvider)
        .where((s) => s.isPending && s.dueDate.difference(s.today).inDays <= 3)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Settings',
            child: Bounceable(
              onTap: () => context.go('/settings'),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orangeAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                ),
                child: Text(initial, style: homeText(16, FontWeight.w700, Colors.white)),
              ),
            ),
          ),
          Expanded(child: Center(child: center ?? const SizedBox.shrink())),
          Semantics(
            button: true,
            label: dueSoon.isEmpty ? 'Notifications' : '${dueSoon.length} bills due soon',
            child: Bounceable(
              onTap: () {
                if (dueSoon.isNotEmpty) {
                  context.push('/bills');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                }
              },
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_rounded,
                        color: Colors.white.withValues(alpha: 0.9), size: 26),
                    if (dueSoon.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.orangeAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: HomeColors.bg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large white amount with smaller grey paise, e.g. ₹7,854.43.
/// Counts up from zero the first time it appears.
class BigAmount extends StatelessWidget {
  const BigAmount({super.key, required this.value, this.hidden = false});
  final double value;
  final bool hidden;

  static final _big = homeText(46, FontWeight.w600, Colors.white, height: 1.15, spacing: -1.5);
  static final _small =
      homeText(28, FontWeight.w500, Colors.white.withValues(alpha: 0.4), spacing: -0.5);

  static InlineSpan _spans(double v) {
    final cents = (v.abs() * 100).round();
    final whole = CurrencyFormatter.format((cents ~/ 100).toDouble());
    return TextSpan(children: [
      TextSpan(text: '${v < 0 ? '−' : ''}$whole', style: _big),
      TextSpan(text: '.${(cents % 100).toString().padLeft(2, '0')}', style: _small),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: hidden
          ? Text('••••••', style: _big)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text.rich(_spans(v)),
            ),
    );
  }
}

/// Translucent card for the dark header.
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 16, 16),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: HomeColors.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeColors.glassBorder),
      ),
      child: child,
    );
    return onTap == null ? box : Bounceable(onTap: onTap, child: box);
  }
}

/// Light grey card for the white sheet.
class SheetTile extends StatelessWidget {
  const SheetTile({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeColors.tile,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
    return onTap == null ? box : Bounceable(onTap: onTap, child: box);
  }
}

const _avatarGroups = <(Set<String>, Color, Color)>[
  ({'food', 'tea', 'coffee', 'snacks', 'groceries', 'dining'}, Color(0xFFFF6A2B), Colors.white),
  ({'transport', 'metro', 'petrol', 'fuel', 'parking', 'bus', 'auto', 'cab', 'uber'},
      Color(0xFF2F80ED), Colors.white),
  ({'entertainment', 'movies', 'dates', 'date', 'games', 'subscriptions'},
      Color(0xFF111214), Colors.white),
  ({'shopping', 'clothes', 'gadgets', 'books'}, Color(0xFFFFD233), Color(0xFF111214)),
  ({'bills', 'recharge', 'rent'}, Colors.white, Color(0xFF111214)),
  ({'health', 'medicine', 'gym'}, Color(0xFF8CE600), Color(0xFF111214)),
  ({'education', 'stationery'}, Color(0xFF7C5CFF), Colors.white),
  ({'allowance', 'salary', 'gift', 'refund', 'other income'}, Color(0xFF22B573), Colors.white),
];

Color _hex(String s) {
  final h = s.replaceFirst('#', '');
  return Color(int.tryParse(h.length == 6 ? 'ff$h' : h, radix: 16) ?? 0xFF3A3D42);
}

/// Round category icon, coloured by category group (or the custom
/// category's own colour and emoji).
class CategoryAvatar extends ConsumerWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 44, this.onDark = false});
  final String category;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = category.toLowerCase().trim();
    final custom = ref
        .watch(customCategoriesProvider)
        .valueOrNull
        ?.where((c) => c.name.toLowerCase().trim() == key)
        .firstOrNull;

    final Color bg;
    final Widget glyph;
    if (custom != null) {
      bg = _hex(custom.color);
      glyph = Text(custom.iconName, style: TextStyle(fontSize: size * 0.45));
    } else {
      final group = _avatarGroups.where((g) => g.$1.contains(key)).firstOrNull;
      bg = group?.$2 ?? const Color(0xFF3A3D42);
      glyph = Icon(
        CategoryIcon.getCategoryData(category).icon,
        size: size * 0.46,
        color: group?.$3 ?? Colors.white,
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: glyph,
    );
  }
}

/// A transaction in the white sheet. Swipe left to delete.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.expense,
    required this.onDismissed,
    this.showDate = true,
  });
  final ExpenseModel expense;
  final VoidCallback onDismissed;

  /// False inside a list already grouped by day.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final note = e.note?.trim() ?? '';
    final kind = e.isIncome
        ? 'Income'
        : e.isBillPayment
            ? 'Bill payment'
            : 'Spending';
    final when = AppDateUtils.formatRelative(e.expenseDate);
    final subtitle = showDate
        ? (note.isNotEmpty ? '${e.category} · $when' : when)
        : (note.isNotEmpty ? e.category : kind);
    final amount = CurrencyFormatter.format(e.amount);
    final dot = e.isIncome
        ? const Color(0xFF2DD4BF)
        : e.isBillPayment
            ? const Color(0xFF3B82F6)
            : const Color(0xFFFACC15);

    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.danger.withValues(alpha: 0.12),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => onDismissed(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CategoryAvatar(category: e.category, size: 44),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.isNotEmpty ? note : e.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: homeText(16, FontWeight.w500, HomeColors.inkSoft),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: homeText(12, FontWeight.w400, HomeColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              e.isIncome ? '+$amount' : '−$amount',
              style: homeText(16, FontWeight.w600, e.isIncome ? HomeColors.income : HomeColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round grey button for the sheet header.
class RoundIcon extends StatelessWidget {
  const RoundIcon({super.key, required this.icon, this.active = false});
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: active ? HomeColors.ink : HomeColors.chip,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: active ? Colors.white : HomeColors.inkSoft),
    );
  }
}

class SheetMessage extends StatelessWidget {
  const SheetMessage({super.key, required this.emoji, required this.title, this.subtitle, this.action});
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(title, style: homeText(14, FontWeight.w600, HomeColors.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                textAlign: TextAlign.center, style: homeText(12, FontWeight.w400, HomeColors.muted)),
          ],
          if (action != null) action!,
        ],
      ),
    );
  }
}

enum TxnFilter {
  all('Transactions', 'All'),
  spending('Spending', 'Spending'),
  income('Income', 'Income'),
  bills('Bill payments', 'Bills');

  const TxnFilter(this.title, this.label);
  final String title;
  final String label;

  bool matches(ExpenseModel e) => switch (this) {
        TxnFilter.all => true,
        TxnFilter.spending => e.isEverydaySpend,
        TxnFilter.income => e.isIncome,
        TxnFilter.bills => e.isBillPayment,
      };
}

/// Search text matching a transaction's category, note or amount.
bool matchesSearch(ExpenseModel e, String? query) {
  final q = query?.trim().toLowerCase() ?? '';
  if (q.isEmpty) return true;
  return e.category.toLowerCase().contains(q) ||
      (e.note?.toLowerCase().contains(q) ?? false) ||
      e.amount.toStringAsFixed(0).contains(q);
}

/// Sheet header: filter menu on the left, [title] (or a search field)
/// in the middle, search toggle on the right.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    required this.filter,
    required this.onFilter,
    required this.searching,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSearch,
  });

  final String title;
  final TxnFilter filter;
  final ValueChanged<TxnFilter> onFilter;
  final bool searching;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          PopupMenuButton<TxnFilter>(
            tooltip: 'Filter',
            initialValue: filter,
            position: PopupMenuPosition.under,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: onFilter,
            itemBuilder: (_) => [
              for (final f in TxnFilter.values)
                PopupMenuItem(
                  value: f,
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(f.label, style: homeText(14, FontWeight.w500, HomeColors.ink))),
                      if (f == filter)
                        const Icon(Icons.check_rounded, size: 18, color: HomeColors.ink),
                    ],
                  ),
                ),
            ],
            child: RoundIcon(icon: Icons.filter_list_rounded, active: filter != TxnFilter.all),
          ),
          Expanded(
            child: searching
                ? TextField(
                    controller: searchController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.search,
                    style: homeText(16, FontWeight.w500, HomeColors.ink),
                    cursorColor: HomeColors.ink,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      hintText: 'Search transactions',
                      hintStyle: homeText(16, FontWeight.w400, HomeColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: onSearchChanged,
                  )
                : Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: homeText(17, FontWeight.w600, HomeColors.ink),
                  ),
          ),
          Semantics(
            button: true,
            label: searching ? 'Close search' : 'Search',
            child: Bounceable(
              onTap: onToggleSearch,
              child: RoundIcon(icon: searching ? Icons.close_rounded : Icons.search_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
