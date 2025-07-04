import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/main.dart';

class AuthService {
  final SupabaseClient _supabase = supabase;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email, 
    required String password
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email, 
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    
    if (response.user != null) {
      // Create user record in the database
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
      });
    }
    
    return response;
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // Update user profile
  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    
    if (updates.isNotEmpty) {
      await _supabase.from('users').update(updates).eq('id', userId);
    }
  }
  
  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
}