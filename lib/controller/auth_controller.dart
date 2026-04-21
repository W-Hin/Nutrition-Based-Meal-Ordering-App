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

  // Login
  Future<bool> login(String email, String password, {String? expectedRole}) async {
    isLoading     = true;
    errorMessage  = '';
    notifyListeners();

    try {
      final response = await _authService.login(
        email:    email.trim(),
        password: password,
      );

      // Verify role if requested
      if (expectedRole != null) {
        final dbRole = await getUserRole() ?? 'customer';
        if (dbRole != expectedRole) {
          // Cross-login detected; revert the auth flow.
          await _authService.logout();
          throw AuthException('Invalid access. Please sign in as a $dbRole instead.');
        }
      }

      currentUser = response.user;
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Incorrect email or password. Please check and try again.';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address before logging in.';
      } else {
        errorMessage = e.message;
      }
      return false;
    } catch (e) {
      errorMessage = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Register
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
      if (e.message.contains('User already registered')) {
        errorMessage = 'An account with this email already exists. Please log in instead.';
      } else if (e.message.contains('Password should be at least 6 characters')) {
        errorMessage = 'Your password is too weak. Please use at least 6 characters.';
      } else {
        errorMessage = e.message;
      }
      return false;
    } catch (e) {
      errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    currentUser  = null;
    errorMessage = '';
    notifyListeners();
  }

  // Helpers
  Future<String?> getUserRole()  => _authService.getUserRole();
  Future<bool>    hasProfile()   => _authService.hasProfile();
  bool get        isLoggedIn     => currentUser != null;
}
