import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../features/expenses/providers/category_provider.dart';
import '../../features/expenses/data/models/custom_category_model.dart';

/// Maps expense categories to icons and colors.
class CategoryIcon extends ConsumerWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
    this.iconSize = 20,
  });

  final String category;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = category.toLowerCase().trim();
    final customCategoriesAsync = ref.watch(customCategoriesProvider);
    
    // Check if it matches any custom category
    final customList = customCategoriesAsync.value;
    CustomCategoryModel? customMatch;
    if (customList != null) {
      for (final c in customList) {
        if (c.name.toLowerCase().trim() == key) {
          customMatch = c;
          break;
        }
      }
    }

    if (customMatch != null) {
      final customColor = _hexToColor(customMatch.color);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: customColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            customMatch.iconName,
            style: TextStyle(fontSize: iconSize),
          ),
        ),
      );
    }

    final data = getCategoryData(category);
    final isIncome = key == 'allowance' ||
        key == 'salary' ||
        key == 'gift' ||
        key == 'refund' ||
        key == 'other income' ||
        data.color == AppColors.success;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isIncome
            ? AppColors.success.withValues(alpha: 0.12)
            : const Color(0xFFEFF1F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        data.icon,
        size: iconSize,
        color: isIncome ? AppColors.success : AppColors.accentPrimary,
      ),
    );
  }

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Static access to category data.
  static CategoryData getCategoryData(String category) {
    final key = category.toLowerCase().trim();
    return _categoryMap[key] ?? _categoryMap['miscellaneous']!;
  }

  static const Map<String, CategoryData> _categoryMap = {
    // Transport
    'transport': CategoryData(Icons.directions_car_rounded, AppColors.categoryTransport, 'Transport'),
    'metro': CategoryData(Icons.subway_rounded, AppColors.categoryTransport, 'Metro'),
    'petrol': CategoryData(Icons.local_gas_station_rounded, AppColors.categoryTransport, 'Petrol'),
    'fuel': CategoryData(Icons.local_gas_station_rounded, AppColors.categoryTransport, 'Fuel'),
    'parking': CategoryData(Icons.local_parking_rounded, AppColors.categoryTransport, 'Parking'),
    'bus': CategoryData(Icons.directions_bus_rounded, AppColors.categoryTransport, 'Bus'),
    'auto': CategoryData(Icons.electric_rickshaw_rounded, AppColors.categoryTransport, 'Auto'),
    'cab': CategoryData(Icons.local_taxi_rounded, AppColors.categoryTransport, 'Cab'),
    'uber': CategoryData(Icons.local_taxi_rounded, AppColors.categoryTransport, 'Uber'),

    // Food
    'food': CategoryData(Icons.restaurant_rounded, AppColors.categoryFood, 'Food'),
    'tea': CategoryData(Icons.local_cafe_rounded, AppColors.categoryFood, 'Tea'),
    'coffee': CategoryData(Icons.coffee_rounded, AppColors.categoryFood, 'Coffee'),
    'snacks': CategoryData(Icons.fastfood_rounded, AppColors.categoryFood, 'Snacks'),
    'groceries': CategoryData(Icons.shopping_basket_rounded, AppColors.categoryFood, 'Groceries'),
    'dining': CategoryData(Icons.dinner_dining_rounded, AppColors.categoryFood, 'Dining'),

    // Entertainment
    'entertainment': CategoryData(Icons.movie_rounded, AppColors.categoryEntertainment, 'Entertainment'),
    'movies': CategoryData(Icons.movie_rounded, AppColors.categoryEntertainment, 'Movies'),
    'dates': CategoryData(Icons.favorite_rounded, AppColors.categoryEntertainment, 'Dates'),
    'date': CategoryData(Icons.favorite_rounded, AppColors.categoryEntertainment, 'Date'),
    'games': CategoryData(Icons.sports_esports_rounded, AppColors.categoryEntertainment, 'Games'),
    'subscriptions': CategoryData(Icons.subscriptions_rounded, AppColors.categoryEntertainment, 'Subscriptions'),

    // Shopping
    'shopping': CategoryData(Icons.shopping_bag_rounded, AppColors.categoryShopping, 'Shopping'),
    'clothes': CategoryData(Icons.checkroom_rounded, AppColors.categoryShopping, 'Clothes'),
    'gadgets': CategoryData(Icons.devices_rounded, AppColors.categoryShopping, 'Gadgets'),
    'books': CategoryData(Icons.menu_book_rounded, AppColors.categoryShopping, 'Books'),

    // Bills
    'bills': CategoryData(Icons.receipt_rounded, AppColors.categoryBills, 'Bills'),
    'recharge': CategoryData(Icons.phone_android_rounded, AppColors.categoryBills, 'Recharge'),
    'rent': CategoryData(Icons.home_rounded, AppColors.categoryBills, 'Rent'),

    // Health
    'health': CategoryData(Icons.local_hospital_rounded, AppColors.categoryHealth, 'Health'),
    'medicine': CategoryData(Icons.medication_rounded, AppColors.categoryHealth, 'Medicine'),
    'gym': CategoryData(Icons.fitness_center_rounded, AppColors.categoryHealth, 'Gym'),

    // Education
    'education': CategoryData(Icons.school_rounded, AppColors.categoryEducation, 'Education'),
    'stationery': CategoryData(Icons.edit_rounded, AppColors.categoryEducation, 'Stationery'),

    // Miscellaneous
    'miscellaneous': CategoryData(Icons.more_horiz_rounded, AppColors.categoryMisc, 'Miscellaneous'),
    'other': CategoryData(Icons.more_horiz_rounded, AppColors.categoryMisc, 'Other'),

    // Income
    'allowance': CategoryData(Icons.account_balance_wallet_rounded, AppColors.success, 'Allowance'),
    'salary': CategoryData(Icons.payments_rounded, AppColors.success, 'Salary'),
    'gift': CategoryData(Icons.card_giftcard_rounded, AppColors.success, 'Gift'),
    'refund': CategoryData(Icons.keyboard_return_rounded, AppColors.success, 'Refund'),
    'other income': CategoryData(Icons.add_card_rounded, AppColors.success, 'Other Income'),
  };

  /// Get all default category names.
  static List<String> get defaultCategories => [
    'Food', 'Transport', 'Metro', 'Petrol', 'Parking',
    'Entertainment', 'Dates', 'Shopping', 'Bills',
    'Health', 'Education', 'Groceries', 'Subscriptions',
    'Miscellaneous',
  ];

  /// Get all default income category names.
  static List<String> get defaultIncomeCategories => [
    'Allowance', 'Salary', 'Gift', 'Refund', 'Other Income',
  ];

  /// Get all category data entries.
  static Map<String, CategoryData> get allCategories => _categoryMap;
}

/// Data class for category icon + color mapping.
class CategoryData {
  const CategoryData(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}
