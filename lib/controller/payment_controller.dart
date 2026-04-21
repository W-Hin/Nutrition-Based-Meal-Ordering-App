import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../model/payment_model.dart';

class PaymentController extends ChangeNotifier {
  // ── Stripe keys ───────────────────────────────────────────────
  static const _secretKey =
      'sk_test_51TMrO1AwDwRCAOhEI0czbU40xYK9Xj6yDvZeQnTaWxmHGSA1TvQ21D2oxxlWZIlhydOkpvaO8xkSKCLDTtimOL4w00qr04ZbXo';

  // ── State ─────────────────────────────────────────────────────
  PaymentStatus status = PaymentStatus.idle;
  String? errorMessage;

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

  // ── Step 1: Create PaymentIntent via Stripe API ───────────────
  Future<String?> _createPaymentIntent({
    required int    amountCents,   // amount in smallest currency unit (sen)
    required String currency,      // e.g. 'myr'
    required String customerEmail,
  }) async {
    try {
      final dio  = Dio();
      final data = {
        'amount':   amountCents.toString(),
        'currency': currency,
        'receipt_email': customerEmail,
        'payment_method_types[]': 'card',
      };

      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['client_secret'] as String?;
      }
    } on DioException catch (e) {
      debugPrint('[PaymentController] DioException: ${e.response?.data}');
      errorMessage = 'Payment setup failed: ${e.response?.data?['error']?['message'] ?? e.message}';
    } catch (e) {
      debugPrint('[PaymentController] createPaymentIntent error: $e');
      errorMessage = 'An unexpected error occurred. Please try again.';
    }
    return null;
  }

  // ── Main payment flow ─────────────────────────────────────────
  Future<bool> processPayment(PaymentModel payment) async {
    if (!validate()) return false;

    status = PaymentStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      // ── Step 1: Create PaymentIntent on Stripe ─────────────────
      final amountCents = (payment.amount * 100).round(); // RM → sen
      final clientSecret = await _createPaymentIntent(
        amountCents:   amountCents,
        currency:      'myr',
        customerEmail: emailCtrl.text.trim(),
      );

      if (clientSecret == null) {
        status = PaymentStatus.failed;
        errorMessage ??= 'Could not initialise payment. Please try again.';
        notifyListeners();
        return false;
      }

      // ── Step 2: Show Stripe Payment Sheet ─────────────────────
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName:       'NuBurn',
          billingDetails: BillingDetails(
            name:  nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
          ),
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // ── Step 3: Payment confirmed ──────────────────────────────
      status = PaymentStatus.success;
      notifyListeners();
      return true;

    } on StripeException catch (e) {
      // User cancelled or card declined
      if (e.error.code == FailureCode.Canceled) {
        status = PaymentStatus.idle;
        errorMessage = null;
      } else {
        status = PaymentStatus.failed;
        errorMessage = e.error.localizedMessage ?? 'Payment failed. Please try again.';
      }
      notifyListeners();
      return false;

    } catch (e) {
      status = PaymentStatus.failed;
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('[PaymentController] processPayment error: $e');
      notifyListeners();
      return false;
    }
  }

  // ── Reset state ───────────────────────────────────────────────
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
