import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for authentication operations via Supabase Auth.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Get the current authenticated user.
  User? get currentUser => _client.auth.currentUser;

  /// Listen to auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );

    // Create profile record
    if (response.user != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': fullName ?? '',
      });
    }

    return response;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if user is authenticated.
  bool get isAuthenticated => currentUser != null;
}
