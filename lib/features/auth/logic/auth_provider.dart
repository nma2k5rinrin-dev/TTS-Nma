import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/models/user_profile.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state stream provider (listens to Supabase auth changes)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

// User profile provider using Notifier
final userProfileProvider =
    NotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() {
    _init();
    // Listen to auth state changes (handles Google OAuth redirect back)
    ref.listen(authStateProvider, (prev, next) {
      next.whenData((authState) {
        final hasSession = authState.session != null;
        if ((authState.event == AuthChangeEvent.initialSession ||
                authState.event == AuthChangeEvent.signedIn ||
                authState.event == AuthChangeEvent.tokenRefreshed ||
                authState.event == AuthChangeEvent.userUpdated) &&
            hasSession) {
          _loadProfileAfterAuth();
        } else if (authState.event == AuthChangeEvent.signedOut) {
          state = const AsyncValue.data(null);
        }
      });
    });
    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final profile = user == null
          ? null
          : await ref.read(authRepositoryProvider).ensureProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Called after auth state changes to signedIn (email or OAuth)
  Future<void> _loadProfileAfterAuth() async {
    try {
      state = const AsyncValue.loading();
      final profile = await ref.read(authRepositoryProvider).ensureProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Email/Password sign in
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      // Profile will be loaded via authStateProvider listener (signedIn event)
      final profile = await ref.read(authRepositoryProvider).ensureProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Email/Password sign up
  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email, password, displayName);

      if (response.user != null) {
        // DB trigger will create profile — just wait and fetch it
        final profile = await ref.read(authRepositoryProvider).ensureProfile();
        state = AsyncValue.data(profile);
      } else {
        // Email confirmation required
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Google OAuth sign in (opens browser)
  Future<void> signInWithGoogle() async {
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // After OAuth redirect back, authStateProvider will fire signedIn
      // which triggers _loadProfileAfterAuth()
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }

  /// Manually refresh profile
  Future<void> refreshProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final profile = user == null
          ? null
          : await ref.read(authRepositoryProvider).ensureProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
