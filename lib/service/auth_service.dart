import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_conn.dart';

// SIGN UP + LOG IN — SUPABASE CONNECTION

class AuthService {
  // Current session
  User? get currentUser => supabase.auth.currentUser;
  bool  get isLoggedIn  => currentUser != null;

  // Register
  /// Creates auth user + inserts row in public.users (name, phone, role='user').
  /// Does NOT create a profiles row — that happens during onboarding.
  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email:    email,
      password: password,
    );

    if (response.user != null) {
      await supabase.from('user').insert({
        'user_id':    response.user!.id,
        'email':      email,
        'first_name': '',
        'last_name':  '',
        'phone':      '',
        'role':       'customer',
      });
    }

    return response;
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email:    email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Fetch role from public.user
  Future<String?> getUserRole() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await supabase
        .from('user')
        .select('role')
        .eq('user_id', uid)
        .maybeSingle();
    return row?['role'] as String?;
  }

  // Check if onboarding profile exists
  Future<bool> hasProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return false;
    final row = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
