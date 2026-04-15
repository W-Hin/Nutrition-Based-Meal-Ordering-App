import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_conn.dart';

// SIGN UP + LOG IN SUPABASE CONNECTION

class AuthService {
  // ── Current session ──────────────────────────────────────────
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn   => currentUser != null;

  // ── Register ─────────────────────────────────────────────────
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final response = await supabase.auth.signUp(
      email:    email,
      password: password,
    );

    // Create profile row after signup
    if (response.user != null) {
      await supabase.from('profiles').insert({
        'id':    response.user!.id,
        'name':  name,
        'phone': phone,
      });
    }

    return response;
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email:    email,
      password: password,
    );
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // ── Listen to auth state changes ──────────────────────────────
  Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;
}