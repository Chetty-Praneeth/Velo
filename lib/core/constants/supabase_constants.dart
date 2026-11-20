/// Supabase configuration.
///
/// Replace these with your actual Supabase project credentials
/// from the Supabase Dashboard → Settings → API.
class SupabaseConstants {
  SupabaseConstants._();

  /// Your Supabase project URL.
  static const String url = 'https://wjreggupadjjhpcyzqtj.supabase.co';

  /// Your Supabase publishable (anon) key.
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqcmVnZ3VwYWRqamhwY3l6cXRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3NTQ1MTksImV4cCI6MjA5NjMzMDUxOX0.nPpU2ESCndj2jQqj5uAocmeI-rs7t5tIp9x5B2xnQLo';

  // ─── Table Names ──────────────────────────────────────
  static const String profilesTable = 'profiles';
  static const String monthlyBudgetsTable = 'monthly_budgets';
  static const String expensesTable = 'expenses';
  static const String customCategoriesTable = 'custom_categories';
  static const String monthlySummariesTable = 'monthly_summaries';
}
