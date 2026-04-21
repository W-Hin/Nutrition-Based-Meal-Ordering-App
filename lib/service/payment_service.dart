import 'supabase_conn.dart';

class PaymentService {
  String get _uid => supabase.auth.currentUser?.id ?? '';

  /// Records a successful payment in the payments table.
  ///
  /// Call this AFTER Stripe confirms success, passing the
  /// orderId returned from [OrderService.placeOrder].
  Future<void> recordPayment({
    required String orderId, // bigint stored as String
    required double amount,
    required String payerName,
    required String payerEmail,
    required String payerPhone,
    String? stripePaymentIntentId, // optional — add later if needed
    String paymentMethod = 'stripe_card',
  }) async {
    await supabase.from('payments').insert({
      'order_id': int.parse(orderId),
      'user_id': _uid,
      'amount': amount,
      'currency': 'MYR',
      'payment_method': paymentMethod,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'payer_name': payerName.isEmpty ? null : payerName,
      'payer_email': payerEmail.isEmpty ? null : payerEmail,
      'payer_phone': payerPhone.isEmpty ? null : payerPhone,
      'status': 'succeeded',
    });
  }
}
