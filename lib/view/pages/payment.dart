import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/checkout_controller.dart';
import '../../controller/order_controller.dart';
import '../../controller/payment_controller.dart';
import '../../controller/cart_controller.dart';
import '../../controller/store_controller.dart';
import '../../model/order_model.dart';
import '../../model/payment_model.dart';
import '../../service/supabase_conn.dart';
import '../../view/pages/payment_failed.dart';
import 'order_details.dart';

class PaymentPage extends StatelessWidget {
  final CheckoutController checkoutCtrl;
  final double deliveryFee;

  const PaymentPage({
    super.key,
    required this.checkoutCtrl,
    required this.deliveryFee,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentController(),
      child: _PaymentView(
        checkoutCtrl: checkoutCtrl,
        deliveryFee:  deliveryFee,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentView extends StatefulWidget {
  final CheckoutController checkoutCtrl;
  final double deliveryFee;

  const _PaymentView({
    required this.checkoutCtrl,
    required this.deliveryFee,
  });

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> {
  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  static const _devUserId = 'fc33ae36-657a-4055-b81e-f6fe3de23278';

  bool _prefillLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillUserInfo());
  }

  /// Reads the current user's info from Supabase and fills the form fields.
  /// Strategy: email from auth session, then try `profiles` table, then `users` table.
  Future<void> _prefillUserInfo() async {
    if (_prefillLoaded) return;
    _prefillLoaded = true;

    final ctrl = context.read<PaymentController>();

    try {
      final uid   = supabase.auth.currentUser?.id ?? _devUserId;
      final email = supabase.auth.currentUser?.email ?? '';

      // 1. Always fill email from auth session — most reliable source
      if (email.isNotEmpty && ctrl.emailCtrl.text.isEmpty) {
        ctrl.emailCtrl.text = email;
      }

      // 2. Try `profiles` table first (has full_name, phone set during onboarding)
      final profileRow = await supabase
          .from('profiles')
          .select('full_name, phone')
          .eq('user_id', uid)
          .maybeSingle();

      if (profileRow != null) {
        final name  = (profileRow['full_name'] as String?)?.trim() ?? '';
        final phone = (profileRow['phone']     as String?)?.trim() ?? '';

        if (name.isNotEmpty  && ctrl.nameCtrl.text.isEmpty)  ctrl.nameCtrl.text  = name;
        if (phone.isNotEmpty && ctrl.phoneCtrl.text.isEmpty) ctrl.phoneCtrl.text = phone;
      }

      // 3. If still empty, fall back to `users` table
      if ((ctrl.nameCtrl.text.isEmpty || ctrl.phoneCtrl.text.isEmpty) && mounted) {
        final userRow = await supabase
            .from('users')
            .select('full_name, phone')
            .eq('id', uid)
            .maybeSingle();

        if (userRow != null) {
          final name  = (userRow['full_name'] as String?)?.trim() ?? '';
          final phone = (userRow['phone']     as String?)?.trim() ?? '';

          if (name.isNotEmpty  && ctrl.nameCtrl.text.isEmpty)  ctrl.nameCtrl.text  = name;
          if (phone.isNotEmpty && ctrl.phoneCtrl.text.isEmpty) ctrl.phoneCtrl.text = phone;
        }
      }

      // 4. Trigger a rebuild so fields show the pre-filled values
      if (mounted) setState(() {});
    } catch (_) {
      // Silently ignore — user can fill manually
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl       = context.watch<PaymentController>();
    final cart       = context.watch<CartController>();
    final grandTotal = cart.total + widget.deliveryFee;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PAYMENT',
          style: TextStyle(
            color:         Color(0xFF2C2C2C),
            fontWeight:    FontWeight.w800,
            letterSpacing: 1.4,
            fontSize:      18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderSummaryCard(
              subtotal:    cart.total,
              deliveryFee: widget.deliveryFee,
              grandTotal:  grandTotal,
              itemCount:   cart.totalItemCount,
            ),
            const SizedBox(height: 20),

            const Text(
              'Your Details',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize:   16,
                  color:      Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Used for payment receipt and order updates.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 16),

            _FormField(
              label:       'Full Name',
              hint:        'John Doe',
              controller:  ctrl.nameCtrl,
              errorText:   ctrl.nameError,
              icon:        Icons.person_outline,
              onChanged:   (_) => ctrl.nameError = null,
            ),
            const SizedBox(height: 14),

            _FormField(
              label:        'Email Address',
              hint:         'john@example.com',
              controller:   ctrl.emailCtrl,
              errorText:    ctrl.emailError,
              icon:         Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged:    (_) => ctrl.emailError = null,
            ),
            const SizedBox(height: 14),

            _FormField(
              label:        'Phone Number',
              hint:         '0123456789',
              controller:   ctrl.phoneCtrl,
              errorText:    ctrl.phoneError,
              icon:         Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              onChanged:    (_) => ctrl.phoneError = null,
            ),
            const SizedBox(height: 8),

            // ── Pre-filled notice ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: _green.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Details are pre-filled from your profile. You may edit them before paying.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF4A6B4A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _PaymentChannelsCard(),
            const SizedBox(height: 24),

            if (ctrl.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:  const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFAAAA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ctrl.errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: ctrl.status == PaymentStatus.loading
                    ? null
                    : () => _handlePay(context, ctrl, cart, grandTotal),
                style: ElevatedButton.styleFrom(
                  backgroundColor:         _terracotta,
                  foregroundColor:         Colors.white,
                  disabledBackgroundColor: _terracotta.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: ctrl.status == PaymentStatus.loading
                    ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
                    : Text(
                  'PAY RM ${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight:    FontWeight.w800,
                      fontSize:      16,
                      letterSpacing: 1.0),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_outline, size: 13, color: Color(0xFF8A8A8A)),
                SizedBox(width: 4),
                Text(
                  'Payment is processed securely by Stripe.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment handler ────────────────────────────────────────────────────────

  Future<void> _handlePay(
      BuildContext context,
      PaymentController ctrl,
      CartController cart,
      double grandTotal,
      ) async {
    final payment = PaymentModel(
      billName:        'Food Order',
      billDescription: 'Order from NuBurn',
      amount:          grandTotal,
      userName:        ctrl.nameCtrl.text.trim(),
      userEmail:       ctrl.emailCtrl.text.trim(),
      userPhone:       ctrl.phoneCtrl.text.trim(),
    );

    final success = await ctrl.processPayment(payment);
    if (!context.mounted) return;

    if (success) {
      final checkoutCtrl = widget.checkoutCtrl;
      final isDelivery   = checkoutCtrl.activeTab == CheckoutTab.delivery;
      final storeId      = context.read<StoreController>().selectedStore?.id;

      final toName    = isDelivery
          ? checkoutCtrl.deliveryAddress.name
          : 'NuBurn - Tanjung Burma';
      final toPhone   = isDelivery ? checkoutCtrl.deliveryAddress.phone : '';
      final toAddress = isDelivery
          ? checkoutCtrl.deliveryAddress.address
          : '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21';

      await context.read<OrderController>().placeOrder(
        cartItems:   cart.items.toList(),
        subtotal:    cart.subtotal,
        serviceFee:  cart.serviceFee,
        deliveryFee: widget.deliveryFee,
        orderType:   isDelivery ? OrderType.delivery : OrderType.selfCollect,
        toName:      toName,
        toPhone:     toPhone,
        toAddress:   toAddress,
        storeId:     storeId,
        remark:      checkoutCtrl.remarks,
        totalPaid:   grandTotal,
        payerName:   ctrl.nameCtrl.text.trim(),
        payerEmail:  ctrl.emailCtrl.text.trim(),
        payerPhone:  ctrl.phoneCtrl.text.trim(),
      );

      cart.clearCart();
      await _showPaymentSuccessDialog(context);
    } else if (ctrl.status == PaymentStatus.failed) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentFailedPage()),
      );
    }
  }

  // ── Success dialog ─────────────────────────────────────────────────────────

  Future<void> _showPaymentSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF1E4620), size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Order Accepted!',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   20,
                      color:      Color(0xFF2C2C2C))),
              const SizedBox(height: 8),
              const Text('NuBurn - Tanjung Burma',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   13,
                      color:      Color(0xFF2C2C2C))),
              const Text('012-345 6789',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF6B6B6B))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle,
                      color: Color(0xFF1E4620), size: 18),
                  SizedBox(width: 6),
                  Text('Your payment was successful',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF1E4620))),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Your order will be prepared shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF6B6B6B))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrderDetailsPage()),
                          (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4620),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Track My Order',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double grandTotal;
  final int itemCount;

  const _OrderSummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.grandTotal,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E4620).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: Color(0xFF1E4620), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '$itemCount item${itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8A8A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Subtotal', value: subtotal),
          if (deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(label: 'Delivery Fee', value: deliveryFee),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   15,
                      color:      Color(0xFF2C2C2C))),
              Text('RM ${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   18,
                      color:      Color(0xFF1E4620))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF8A8A8A))),
      Text('RM ${value.toStringAsFixed(2)}',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF8A8A8A))),
    ],
  );
}

class _PaymentChannelsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Accepted Payment Channels',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: const [
              _ChannelChip(label: 'Credit / Debit Card'),
              SizedBox(width: 8),
              _ChannelChip(label: 'Apple / Google Pay'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Payment is processed securely by Stripe.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final String label;
  const _ChannelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        const Color(0xFFEEEBDE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final IconData icon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   13,
                color:      Color(0xFF2C2C2C))),
        const SizedBox(height: 6),
        TextField(
          controller:  controller,
          keyboardType: keyboardType,
          onChanged:   onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(
                color: Color(0xFFAAAAAA), fontSize: 13),
            prefixIcon: Icon(icon,
                size: 18, color: const Color(0xFF8A8A8A)),
            filled:    true,
            fillColor: errorText != null
                ? const Color(0xFFFFEEEE)
                : const Color(0xFFEEEBDE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:   BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.red, width: 1.2)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : const Color(0xFF1E4620),
                width: 1.5,
              ),
            ),
            errorText:    errorText,
            errorStyle:   const TextStyle(fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}