import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/category_repository.dart';
import '../data/models/custom_category_model.dart';

/// Provider for the CategoryRepository.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

/// Provider for custom categories list state.
final customCategoriesProvider = StateNotifierProvider<
    CustomCategoriesNotifier, AsyncValue<List<CustomCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(ref.watch(categoryRepositoryProvider));
});

/// StateNotifier for custom category list operations.
class CustomCategoriesNotifier
    extends StateNotifier<AsyncValue<List<CustomCategoryModel>>> {
  final CategoryRepository _repo;

  CustomCategoriesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  /// Load user's custom categories.
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repo.getCustomCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a new custom category.
  Future<void> addCategory({
    required String name,
    required String emoji,
    required String colorHex,
  }) async {
    try {
      final newCat = await _repo.createCustomCategory(
        name: name,
        emoji: emoji,
        colorHex: colorHex,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([...current, newCat]);
    } catch (e) {
      // Keep existing state, but rethrow error for UI feedback if needed
      rethrow;
    }
  }

  /// Delete a custom category by ID.
  Future<void> deleteCategory(String id) async {
    try {
      await _repo.deleteCustomCategory(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((c) => c.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }
}
