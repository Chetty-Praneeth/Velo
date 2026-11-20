import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import 'models/custom_category_model.dart';

/// Repository for custom category CRUD operations.
class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Fetch all custom categories for the current user.
  Future<List<CustomCategoryModel>> getCustomCategories() async {
    final response = await _client
        .from(SupabaseConstants.customCategoriesTable)
        .select()
        .eq('user_id', _userId)
        .order('name', ascending: true);

    return (response as List)
        .map((e) => CustomCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new custom category.
  Future<CustomCategoryModel> createCustomCategory({
    required String name,
    required String emoji,
    required String colorHex,
  }) async {
    final data = {
      'user_id': _userId,
      'name': name,
      'icon_name': emoji,
      'color': colorHex,
    };

    final response = await _client
        .from(SupabaseConstants.customCategoriesTable)
        .insert(data)
        .select()
        .single();

    return CustomCategoryModel.fromJson(response);
  }

  /// Delete a custom category by its ID.
  Future<void> deleteCustomCategory(String id) async {
    await _client
        .from(SupabaseConstants.customCategoriesTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
