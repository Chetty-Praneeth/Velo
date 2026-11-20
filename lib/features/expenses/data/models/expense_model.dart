/// Expense data model for Supabase serialization.
class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String type;

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    this.type = 'expense',
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      note: json['note'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      type: json['type'] as String? ?? 'expense',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
  }

  /// For inserting (no id/created_at — handled by Supabase).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      'type': type,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? note,
    DateTime? expenseDate,
    DateTime? createdAt,
    String? type,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  @override
  String toString() =>
      'ExpenseModel(id: $id, amount: $amount, category: $category, note: $note, date: $expenseDate, type: $type)';
}

/// Monthly budget configuration model.
class MonthlyBudgetModel {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double monthlyAllowance;
  final double savingsGoal;
  final DateTime createdAt;

  const MonthlyBudgetModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.monthlyAllowance,
    required this.savingsGoal,
    required this.createdAt,
  });

  double get spendableBudget => monthlyAllowance - savingsGoal;

  factory MonthlyBudgetModel.fromJson(Map<String, dynamic> json) {
    return MonthlyBudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      monthlyAllowance: (json['monthly_allowance'] as num).toDouble(),
      savingsGoal: (json['savings_goal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'month': month,
      'year': year,
      'monthly_allowance': monthlyAllowance,
      'savings_goal': savingsGoal,
    };
  }
}
