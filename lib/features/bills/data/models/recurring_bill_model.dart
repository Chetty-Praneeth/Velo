/// A bill or subscription that repeats every cycle (rent, phone recharge,
/// Spotify…). Its amount is set aside from the budget until it's paid.
class RecurringBillModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String category;

  /// Day of the month it's due (1–31). Clamped to the month's length, so 31
  /// means "last day of the month".
  final int dueDay;
  final bool isActive;
  final DateTime createdAt;

  const RecurringBillModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.category,
    required this.dueDay,
    required this.isActive,
    required this.createdAt,
  });

  factory RecurringBillModel.fromJson(Map<String, dynamic> json) {
    return RecurringBillModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'Bills',
      dueDay: json['due_day'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  RecurringBillModel copyWith({
    String? name,
    double? amount,
    String? category,
    int? dueDay,
    bool? isActive,
  }) {
    return RecurringBillModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
