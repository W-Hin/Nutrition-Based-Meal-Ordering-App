import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/payment_model.dart';

class PaymentController extends ChangeNotifier {
  // ── Toyyibpay sandbox credentials ──────────────────────────
  // Replace these with your actual sandbox values from dev.toyyibpay.com
  static const _secretKey    = 'w5zadc8m-hyes-7ung-evp8-pgvssvjewkqy';
  static const _categoryCode = 'crwmzegp';
  static const _baseUrl      = 'https://dev.toyyibpay.com';

  // ── State ───────────────────────────────────────────────────
  PaymentStatus status = PaymentStatus.idle;
  String? billPaymentUrl; // URL to open for payment
  String? errorMessage;

  // ── Form field controllers (owned here, disposed here) ─────
  final nameCtrl    = TextEditingController();
  final emailCtrl   = TextEditingController();
  final phoneCtrl   = TextEditingController();

  // ── Validation errors ───────────────────────────────────────
  String? nameError;
  String? emailError;
  String? phoneError;

  // ── Validate all fields, returns true if all pass ───────────
  bool validate() {
    bool valid = true;

    // Name — required, min 3 chars
    if (nameCtrl.text.trim().isEmpty) {
      nameError = 'Name is required';
      valid = false;
    } else if (nameCtrl.text.trim().length < 3) {
      nameError = 'Name must be at least 3 characters';
      valid = false;
    } else {
      nameError = null;
    }

    // Email — required, basic format check
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

    // Phone — required, Malaysian format (01X-XXXXXXX)
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

  // ── Create bill on Toyyibpay and get payment URL ────────────
  Future<void> createBill(PaymentModel payment) async {
    if (!validate()) return;

    status = PaymentStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      // Amount in cents (Toyyibpay expects integer, e.g. RM13.50 = 1350)
      final amountInCents = (payment.amount * 100).toInt();

      final response = await http.post(
        Uri.parse('$_baseUrl/index.php/api/createBill'),
        body: {
          'userSecretKey':          _secretKey,
          'categoryCode':           _categoryCode,
          'billName':               payment.billName,
          'billDescription':        payment.billDescription,
          'billPriceSetting':       '1',         // fixed price
          'billPayorInfo':          '1',         // collect payer info
          'billAmount':             '$amountInCents',
          'billReturnUrl':          'myapp://payment-return', // deep link
          'billCallbackUrl':        '',          // optional webhook
          'billExternalReferenceNo': DateTime.now().millisecondsSinceEpoch.toString(),
          'billTo':                 payment.userName,
          'billEmail':              payment.userEmail,
          'billPhone':              payment.userPhone,
          'billSplitPayment':       '0',
          'billSplitPaymentArgs':   '',
          'billPaymentChannel':     '0',         // 0 = all channels (FPX + card)
          'billContentEmail':       'Thank you for your order!',
          'billChargeToCustomer':   '1',         // customer absorbs charges
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Toyyibpay returns a list with one object containing BillCode
        if (data is List && data.isNotEmpty && data[0]['BillCode'] != null) {
          final billCode = data[0]['BillCode'];
          billPaymentUrl = '$_baseUrl/$billCode';
          status = PaymentStatus.success;
        } else {
          throw Exception('Invalid response: ${response.body}');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      status = PaymentStatus.failed;
      errorMessage = 'Payment setup failed. Please try again.\n$e';
    }

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