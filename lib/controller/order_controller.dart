import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../model/cart_item.dart';

class OrderController extends ChangeNotifier {
  OrderModel? currentOrder;
  bool isCancelling = false;
  bool isCancelled  = false;

  void placeOrder({
    required List<CartItem> cartItems,
    required double subtotal,
    required double serviceFee,
    required String toName,
    required String toPhone,
    required String toAddress,
    required OrderType orderType, // ← now required
  }) {
    currentOrder = OrderModel(
      orderId:       _generateOrderId(),
      orderDate:     DateTime.now(),
      paymentMethod: 'Credit / Debit Card',
      fromName:      'NuBurn - Tanjung Burma',
      fromAddress:   '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21, ....',
      toName:        toName,
      toPhone:       toPhone,
      toAddress:     toAddress,
      items: cartItems
          .map((c) => OrderItemModel(
        name:   c.name,
        addOns: c.addOns,
        price:  c.price,
      ))
          .toList(),
      subtotal:    subtotal,
      serviceFee:  serviceFee,
      orderType:   orderType,
      status:      OrderStatus.submitted,
    );
    isCancelled = false;
    notifyListeners();
  }

  // Called by admin panel later to push status forward
  void updateStatus(OrderStatus newStatus) {
    if (currentOrder == null) return;
    currentOrder!.status = newStatus;
    notifyListeners();
  }

  Future<void> cancelOrder() async {
    if (currentOrder == null || !currentOrder!.isCancellable) return;
    isCancelling = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // simulate API

    isCancelled  = true;
    isCancelling = false;
    notifyListeners();
  }

  String _generateOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch.toString();
    return rand.split('').map((e) => chars[int.parse(e) % chars.length]).join();
  }
}