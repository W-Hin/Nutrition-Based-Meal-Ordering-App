import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../model/payment_model.dart';

enum PaymentStatus { idle, loading, success, failed }

class PaymentController extends ChangeNotifier {
  // ── Stripe keys ───────────────────────────────────────────────
  // Publishable key — safe to expose in app (starts with pk_test_)
  // Get from: https://dashboard.stripe.com → Developers → API Keys
  static const _publishableKey = 'pk_test_YOUR_KEY_HERE';

  // !! IMPORTANT: Secret key must NEVER go in Flutter code in production !!
  // For your assignment demo only, paste it here temporarily.
  // In a real app this lives on a backend server only.
  static const _secretKey      = 'sk_test_YOUR_KEY_HERE';

  // ── State ─────────────────────────────────────────────────────
  PaymentStatus status       = PaymentStatus.idle;
  String?       errorMessage;

  // ── Form controllers ──────────────────────────────────────────
  final nameCtrl  = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  // ── Validation errors ─────────────────────────────────────────
  String? nameError;
  String? emailError;
  String? phoneError;

  // ── Validate ──────────────────────────────────────────────────
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
    final rawPhone   = phoneCtrl.text.replaceAll(RegExp(r'[\s\-]'), '');
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

  // ── Main payment flow ─────────────────────────────────────────
  Future<bool> processPayment(PaymentModel payment) async {
    if (!validate()) return false;

    status       = PaymentStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Create PaymentIntent via Stripe API
      // In production this call goes to YOUR backend, not directly to Stripe
      final clientSecret = await _createPaymentIntent(
        amountInCents: (payment.amount * 100).toInt(),
        currency:      'myr',
        customerEmail: payment.userEmail,
      );

      // Step 2: Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName:       'NuBurn',
          billingDetails: BillingDetails(
            name:  payment.userName,
            email: payment.userEmail,
            phone: payment.userPhone,
          ),
          // Pre-fills billing info so user doesn't retype it
          billingDetailsCollectionConfiguration:
          const BillingDetailsCollectionConfiguration(
            name:  CollectionMode.always,
            email: CollectionMode.always,
            phone: CollectionMode.always,
          ),
          style: ThemeMode.light,
        ),
      );

      // Step 3: Show Stripe's built-in payment sheet UI
      // This handles card input, validation, 3D secure etc automatically
      await Stripe.instance.presentPaymentSheet();

      // If we reach here without exception, payment succeeded
      status = PaymentStatus.success;
      notifyListeners();
      return true;

    } on StripeException catch (e) {
      // User cancelled or card declined
      if (e.error.code == FailureCode.Canceled) {
        // User tapped X to close — not an error, just go back
        status       = PaymentStatus.idle;
        errorMessage = null;
      } else {
        status       = PaymentStatus.failed;
        errorMessage = e.error.localizedMessage ?? 'Payment failed. Please try again.';
      }
      notifyListeners();
      return false;

    } catch (e) {
      status       = PaymentStatus.failed;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── Create PaymentIntent directly with Stripe API ─────────────
  // !! Assignment only — in production, call your own backend here !!
  Future<String> _createPaymentIntent({
    required int    amountInCents,
    required String currency,
    required String customerEmail,
  }) async {
    final dio      = Dio();
    final response = await dio.post(
      'https://api.stripe.com/v1/payment_intents',
      data: {
        'amount':               amountInCents,
        'currency':             currency,
        'receipt_email':        customerEmail,
        'automatic_payment_methods[enabled]': true,
      },
      options: Options(
        headers: {
          // Basic auth with secret key
          'Authorization': 'Bearer $_secretKey',
          'Content-Type':  'application/x-www-form-urlencoded',
        },
      ),
    );

    return response.data['client_secret'] as String;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }
}