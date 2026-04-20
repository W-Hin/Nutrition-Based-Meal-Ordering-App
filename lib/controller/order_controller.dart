import 'dart:math';
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
    // Generate a 3-digit order code for ALL orders (delivery + self-collect)
    // for easy admin tracking. Uniqueness is guaranteed in OrderService.
    final collectionCode = _generateCollectionCode();

    currentOrder = OrderModel(
      orderId:        _generateLocalId(),
      orderDate:      DateTime.now(),
      paymentMethod:  'Credit / Debit Card',
      storeId:        storeId,
      fromName:       'NuBurn - Tanjung Burma',
      fromAddress:    '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21, ....',
      toName:         toName,
      toPhone:        toPhone,
      toAddress:      toAddress,
      items: cartItems.map((c) => OrderItemModel(
        name:     c.name,
        addOns:   c.addOns,
        price:    c.price,
        imageUrl: c.imageUrl,
      )).toList(),
      subtotal:       subtotal,
      serviceFee:     serviceFee,
      deliveryFee:    deliveryFee,
      orderType:      orderType,
      remark:         remark,
      collectionCode: collectionCode,
      status:         OrderStatus.submitted,
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

    currentOrder!.status = OrderStatus.submitted;
    notifyListeners();
  }

  // ── Generate a random 3-digit collection code (100–999) ──────────────────
  String _generateCollectionCode() {
    final rng = Random();
    final code = 100 + rng.nextInt(900); // 100..999
    return code.toString().padLeft(3, '0');
  }

  // ── Generate a short local order ID (used before DB returns real ID) ─────
  String _generateLocalId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand  = DateTime.now().millisecondsSinceEpoch.toString();
    return rand.split('').map((e) => chars[int.parse(e) % chars.length]).join();
  }
}