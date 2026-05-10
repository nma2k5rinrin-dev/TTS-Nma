import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'models/user_profile.dart';

class AuthRepository {
  // Sign in with email/password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await SupabaseService.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email/password
  Future<AuthResponse> signUpWithEmail(String email, String password, String displayName) async {
    final response = await SupabaseService.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return response;
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await SupabaseService.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.tts.nma://callback',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
  }

  // Get current user profile
  Future<UserProfile?> getCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    final data = await SupabaseService.table('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  // Create profile after sign up
  Future<UserProfile> createProfile(String userId, String email, String? displayName) async {
    final data = {
      'id': userId,
      'email': email,
      'display_name': displayName ?? email.split('@').first,
      'role': 'user',
      'credits': 0,
    };

    final result = await SupabaseService.table('profiles')
        .upsert(data)
        .select()
        .single();

    return UserProfile.fromJson(result);
  }

  // Update profile
  Future<UserProfile> updateProfile(String userId, Map<String, dynamic> updates) async {
    final result = await SupabaseService.table('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(result);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => SupabaseService.auth.onAuthStateChange;
}
