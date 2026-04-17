import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool   isLoading     = false;
  String errorMessage  = '';
  User?  currentUser;

  AuthController() {
    currentUser = _authService.currentUser;
    _authService.authStateChanges.listen((state) {
      currentUser = state.session?.user;
      notifyListeners();
    });
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    isLoading     = true;
    errorMessage  = '';
    notifyListeners();

    try {
      final response = await _authService.login(
        email:    email.trim(),
        password: password,
      );
      currentUser = response.user;
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    isLoading     = true;
    errorMessage  = '';
    notifyListeners();

    try {
      final response = await _authService.register(
        email:    email.trim(),
        password: password,
      );
      currentUser = response.user;
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    currentUser  = null;
    errorMessage = '';
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<String?> getUserRole()  => _authService.getUserRole();
  Future<bool>    hasProfile()   => _authService.hasProfile();
  bool get        isLoggedIn     => currentUser != null;
}
