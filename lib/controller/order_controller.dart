import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../model/cart_item.dart';
import '../service/order_service.dart';
import '../service/payment_service.dart';

class OrderController extends ChangeNotifier {
  final _orderService   = OrderService();
  final _paymentService = PaymentService();

  OrderModel? currentOrder;
  String?     dbOrderId;    // real bigint id from Supabase (FK for payments)

  bool isCancelling = false;
  bool isCancelled  = false;

  // ── Place order + record payment ─────────────────────────────────────────
  Future<void> placeOrder({
    required List<CartItem> cartItems,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required String toName,
    required String toPhone,
    required String toAddress,
    required OrderType orderType,
    String? storeId,
    String  remark     = '',
    double  totalPaid  = 0,
    String  payerName  = '',
    String  payerEmail = '',
    String  payerPhone = '',
  }) async {
    // Default status is always 'submitted' on creation
    currentOrder = OrderModel(
      orderId:       _generateLocalId(),
      orderDate:     DateTime.now(),
      paymentMethod: 'Credit / Debit Card',
      storeId:       storeId,
      fromName:      'NuBurn - Tanjung Burma',
      fromAddress:   '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21, ....',
      toName:        toName,
      toPhone:       toPhone,
      toAddress:     toAddress,
      items: cartItems.map((c) => OrderItemModel(
        name:   c.name,
        addOns: c.addOns,
        price:  c.price,
      )).toList(),
      subtotal:    subtotal,
      serviceFee:  serviceFee,
      deliveryFee: deliveryFee,
      orderType:   orderType,
      remark:      remark,
      status:      OrderStatus.submitted, // ← always starts as submitted
    );

    // 1. Insert order + order_items rows; get back real DB order_id
    dbOrderId = await _orderService.placeOrder(currentOrder!);

    // 2. Insert payment row linked to that order_id
    await _paymentService.recordPayment(
      orderId:    dbOrderId!,
      amount:     totalPaid > 0 ? totalPaid : currentOrder!.total,
      payerName:  payerName,
      payerEmail: payerEmail,
      payerPhone: payerPhone,
    );

    isCancelled = false;
    notifyListeners();
  }

  // ── Update local status (called from real-time stream) ───────────────────
  void updateStatus(OrderStatus newStatus) {
    if (currentOrder == null) return;
    currentOrder!.status = newStatus;
    notifyListeners();
  }

  // ── Real-time status stream (delegates to OrderService) ──────────────────
  Stream<Map<String, dynamic>> watchOrderStatus(String orderId) =>
      _orderService.watchOrderStatus(orderId);

  // ── Cancel order ─────────────────────────────────────────────────────────
  Future<void> cancelOrder() async {
    if (currentOrder == null || !currentOrder!.isCancellable) return;
    isCancelling = true;
    notifyListeners();

    final idToCancel = dbOrderId ?? currentOrder!.orderId;
    await _orderService.cancelOrder(idToCancel);

    isCancelled  = true;
    isCancelling = false;

    // Update local status so UI reflects cancellation immediately
    currentOrder!.status = OrderStatus.submitted; // keep last known; banner overrides
    notifyListeners();
  }

  // ── Generate a short local order ID (used before DB returns real ID) ─────
  String _generateLocalId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand  = DateTime.now().millisecondsSinceEpoch.toString();
    return rand.split('').map((e) => chars[int.parse(e) % chars.length]).join();
  }
}