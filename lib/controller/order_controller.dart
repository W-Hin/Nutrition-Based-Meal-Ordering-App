import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../model/cart_item.dart';
import '../service/order_service.dart';

class OrderController extends ChangeNotifier {
  final _orderService = OrderService();

  OrderModel? currentOrder;
  bool isCancelling = false;
  bool isCancelled  = false;

  Future<void> placeOrder({
    required List<CartItem> cartItems,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,  // ← ADD
    required String toName,
    required String toPhone,
    required String toAddress,
    required OrderType orderType,
  }) async {
    currentOrder = OrderModel(
      orderId:       _generateOrderId(),
      orderDate:     DateTime.now(),
      paymentMethod: 'Credit / Debit Card',
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
      deliveryFee: deliveryFee,  // ← ADD
      orderType:   orderType,
      status:      OrderStatus.submitted,
    );

    await _orderService.placeOrder(currentOrder!);
    isCancelled = false;
    notifyListeners();
  }

  void updateStatus(OrderStatus newStatus) {
    if (currentOrder == null) return;
    currentOrder!.status = newStatus;
    notifyListeners();
  }

  Future<void> cancelOrder() async {
    if (currentOrder == null || !currentOrder!.isCancellable) return;
    isCancelling = true;
    notifyListeners();

    await _orderService.cancelOrder(currentOrder!.orderId);

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