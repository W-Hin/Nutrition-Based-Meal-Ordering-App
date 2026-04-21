import 'dart:math';
import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../model/cart_item.dart';
import '../service/order_service.dart';
import '../service/payment_service.dart';
import '../service/supabase_conn.dart';

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
        quantity: c.quantity,
        foodId:   c.foodId,
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

    // 1. Compute macro totals for order snapshot
    final macros = await _calculateOrderMacros(cartItems);

    currentOrder = OrderModel(
      orderId:        currentOrder!.orderId,
      orderDate:      currentOrder!.orderDate,
      paymentMethod:  currentOrder!.paymentMethod,
      storeId:        currentOrder!.storeId,
      fromName:       currentOrder!.fromName,
      fromAddress:    currentOrder!.fromAddress,
      toName:         currentOrder!.toName,
      toPhone:        currentOrder!.toPhone,
      toAddress:      currentOrder!.toAddress,
      items:          currentOrder!.items,
      subtotal:       currentOrder!.subtotal,
      serviceFee:     currentOrder!.serviceFee,
      deliveryFee:    currentOrder!.deliveryFee,
      totalCal:       macros['cal'] ?? 0,
      totalPro:       macros['pro'] ?? 0,
      totalCarb:      macros['carb'] ?? 0,
      totalFat:       macros['fat'] ?? 0,
      orderType:      currentOrder!.orderType,
      remark:         currentOrder!.remark,
      collectionCode: currentOrder!.collectionCode,
      status:         currentOrder!.status,
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

    // 3. (REMOVED) Calories are no longer logged immediately.
    // They will only be tracked upon the order being marked 'completed' by Admin.

    isCancelled = false;
    notifyListeners();
  }

  // ── Calculate and return macros for all cart items ────────────────────────
  Future<Map<String, double>> _calculateOrderMacros(List<CartItem> cartItems) async {
    try {
      // Collect unique food_ids (preset menu items only)
      final foodIds = cartItems
          .where((c) => c.foodId != null && c.foodId!.isNotEmpty)
          .map((c) => c.foodId!)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> nutritionMap = {};

      if (foodIds.isNotEmpty) {
        // Fetch nutrition data for those food IDs
        final rows = await supabase
            .from('menu_items')
            .select('food_id, calories, protein, carbs, fats')
            .inFilter('food_id', foodIds);

        // Build a lookup map: food_id → nutrition
        nutritionMap = {
          for (final r in List<Map<String, dynamic>>.from(rows))
            r['food_id'] as String: r
        };
      }

      // Sum up totals across all cart items (respecting quantity)
      double totalCalories = 0;
      double totalProtein  = 0;
      double totalCarbs    = 0;
      double totalFat      = 0;

      for (final item in cartItems) {
        final qty = item.quantity.toDouble();

        // 1. Check if it's a Custom Bowl with embedded nutrition
        if (item.customDetails != null && item.customDetails!.containsKey('calories')) {
          totalCalories += ((item.customDetails!['calories'] as num?)?.toDouble() ?? 0) * qty;
          totalProtein  += ((item.customDetails!['protein'] as num?)?.toDouble() ?? 0) * qty;
          totalCarbs    += ((item.customDetails!['carbs'] as num?)?.toDouble() ?? 0) * qty;
          totalFat      += ((item.customDetails!['fats'] as num?)?.toDouble() ?? 0) * qty;
          continue;
        }

        // 2. Otherwise fall back to the preset menu_items network fetch map
        final n = nutritionMap[item.foodId ?? ''];
        if (n == null) continue;

        totalCalories += ((n['calories'] as num?)?.toDouble() ?? 0) * qty;
        totalProtein  += ((n['protein']  as num?)?.toDouble() ?? 0) * qty;
        totalCarbs    += ((n['carbs']    as num?)?.toDouble() ?? 0) * qty;
        totalFat      += ((n['fats']     as num?)?.toDouble() ?? 0) * qty;
      }

      return {
        'cal': totalCalories,
        'pro': totalProtein,
        'carb': totalCarbs,
        'fat': totalFat,
      };
    } catch (_) {
      return {'cal': 0, 'pro': 0, 'carb': 0, 'fat': 0};
    }
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

    currentOrder!.status = OrderStatus.cancelled;
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