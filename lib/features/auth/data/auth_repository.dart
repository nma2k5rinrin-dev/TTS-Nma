import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'models/user_profile.dart';

class AuthRepository {
  static const _sadminCanonicalEmail = 'nma2k5rinrin@gmail.com';

  bool _isSadminEmail(String? email) {
    if (email == null) return false;
    final normalized = _normalizeEmail(email);
    return normalized == _sadminCanonicalEmail;
  }

  String _normalizeEmail(String email) {
    final lower = email.trim().toLowerCase();
    final parts = lower.split('@');
    if (parts.length != 2) return lower;
    final domain = parts[1] == 'googlemail.com' ? 'gmail.com' : parts[1];
    final local = domain == 'gmail.com'
        ? parts[0].replaceAll('.', '')
        : parts[0];
    return '$local@$domain';
  }

  // Sign in with email/password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await SupabaseService.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email/password
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final response = await SupabaseService.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return response;
  }

  // Sign in with Google (handles both web and mobile)
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: redirect to Google OAuth, returns to current URL
      return await SupabaseService.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
    } else {
      // Mobile: deep link callback
      return await SupabaseService.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.tts.nma://callback',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
  }

  // Get current user profile (wait for DB trigger to create it)
  Future<UserProfile?> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    // Retry logic: DB trigger may take a moment to create the profile
    for (int i = 0; i < 3; i++) {
      final data = await SupabaseService.table(
        'profiles',
      ).select().eq('id', user.id).maybeSingle();

      if (data != null) return UserProfile.fromJson(data);

      // Wait a bit for the DB trigger to run
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return null;
  }

  // Ensure profile exists (for Google OAuth where trigger might not fire properly)
  Future<UserProfile> ensureProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Try to get existing profile
    final existing = await getCurrentProfile();
    if (existing != null) return existing;

    // If no profile (e.g. OAuth user), create one
    final data = {
      'id': user.id,
      'email': user.email ?? '',
      'display_name':
          user.userMetadata?['display_name'] ??
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'User',
      'role': _isSadminEmail(user.email) ? 'sadmin' : 'user',
      'credits': _isSadminEmail(user.email) ? 99999 : 0,
    };

    final result = await SupabaseService.table(
      'profiles',
    ).upsert(data).select().single();

    return UserProfile.fromJson(result);
  }

  // Update profile
  Future<UserProfile> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final result = await SupabaseService.table(
      'profiles',
    ).update(updates).eq('id', userId).select().single();

    return UserProfile.fromJson(result);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges =>
      SupabaseService.auth.onAuthStateChange;
}
