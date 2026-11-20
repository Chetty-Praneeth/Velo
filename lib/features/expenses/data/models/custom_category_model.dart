/// Custom category model for Supabase serialization.
class CustomCategoryModel {
  final String id;
  final String userId;
  final String name;
  final String iconName; // Stores emoji, e.g. "🍕"
  final String color; // Stores color hex code, e.g. "#6C63FF"
  final DateTime createdAt;

  const CustomCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconName,
    required this.color,
    required this.createdAt,
  });

  factory CustomCategoryModel.fromJson(Map<String, dynamic> json) {
    return CustomCategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String? ?? 'category',
      color: json['color'] as String? ?? '#6C63FF',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon_name': iconName,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'icon_name': iconName,
      'color': color,
    };
  }

  CustomCategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? iconName,
    String? color,
    DateTime? createdAt,
  }) {
    return CustomCategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'CustomCategoryModel(id: $id, name: $name, emoji: $iconName, color: $color)';
}
