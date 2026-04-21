import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';  // uncomment after: flutter pub add flutter_stripe
// import 'package:dio/dio.dart';                         // uncomment after: flutter pub add dio
import '../model/payment_model.dart';

class PaymentController extends ChangeNotifier {
  // Stripe keys (used when Stripe is enabled)
  // static const _secretKey =
  //     'sk_test_51TMrO1AwDwRCAOhEI0czbU40xYK9Xj6yDvZeQnTaWxmHGSA1TvQ21D2oxxlWZIlhydOkpvaO8xkSKCLDTtimOL4w00qr04ZbXo';

  // State
  PaymentStatus status = PaymentStatus.idle;
  String? errorMessage;

  // Form controllers
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  // Validation errors
  String? nameError;
  String? emailError;
  String? phoneError;

  // Validate
  bool validate() {
    bool valid = true;

    if (nameCtrl.text.trim().isEmpty) {
      nameError = 'Name is required';
      valid = false;
    } else if (nameCtrl.text.trim().length < 3) {
      nameError = 'Name must be at least 3 characters';
      valid = false;
    } else {
      nameError = null;
    }

    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (emailCtrl.text.trim().isEmpty) {
      emailError = 'Email is required';
      valid = false;
    } else if (!emailRegex.hasMatch(emailCtrl.text.trim())) {
      emailError = 'Enter a valid email address';
      valid = false;
    } else {
      emailError = null;
    }

    final phoneRegex = RegExp(r'^01[0-9]{8,9}$');
    final rawPhone = phoneCtrl.text.replaceAll(RegExp(r'[\s\-]'), '');
    if (rawPhone.isEmpty) {
      phoneError = 'Phone number is required';
      valid = false;
    } else if (!phoneRegex.hasMatch(rawPhone)) {
      phoneError = 'Enter a valid Malaysian number (e.g. 0123456789)';
      valid = false;
    } else {
      phoneError = null;
    }

    notifyListeners();
    return valid;
  }

  // Main payment flow
  Future<bool> processPayment(PaymentModel payment) async {
    if (!validate()) return false;

    status = PaymentStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      // MOCK DELAY TO SIMULATE PAYMENT PROCESSING
      // Since Stripe features are disabled for desktop testing
      await Future.delayed(const Duration(seconds: 2));

      status = PaymentStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      status = PaymentStatus.failed;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Reset state
  void reset() {
    status       = PaymentStatus.idle;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }
}
