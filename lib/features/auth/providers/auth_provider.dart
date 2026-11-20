import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

/// Provider for the Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Provider for the current auth state.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider for the current user.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

/// Auth actions notifier for sign in/up/out.
final authActionsProvider =
    StateNotifierProvider<AuthActionsNotifier, AuthActionState>((ref) {
  return AuthActionsNotifier(ref.watch(authRepositoryProvider));
});

/// State for auth actions.
class AuthActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AuthActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AuthActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier handling auth actions.
class AuthActionsNotifier extends StateNotifier<AuthActionState> {
  final AuthRepository _repo;

  AuthActionsNotifier(this._repo) : super(const AuthActionState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthActionState(isLoading: true);
    try {
      await _repo.signIn(email: email, password: password);
      state = const AuthActionState(isSuccess: true);
    } on AuthException catch (e) {
      state = AuthActionState(error: e.message);
    } catch (e) {
      state = AuthActionState(error: e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AuthActionState(isLoading: true);
    try {
      await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AuthActionState(isSuccess: true);
    } on AuthException catch (e) {
      state = AuthActionState(error: e.message);
    } catch (e) {
      state = AuthActionState(error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthActionState();
  }

  void clearError() {
    state = const AuthActionState();
  }
}
