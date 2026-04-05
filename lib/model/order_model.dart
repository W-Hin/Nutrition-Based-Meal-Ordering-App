enum OrderType { delivery, selfCollect }

enum OrderStatus {
  submitted,
  preparing,
  readyOrOutForDelivery, // "Out for Delivery" OR "Ready for Collection"
  completed,
}

class OrderModel {
  final String orderId;
  final DateTime orderDate;
  final String paymentMethod;
  final String fromName;
  final String fromAddress;
  final String toName;
  final String toPhone;
  final String toAddress;
  final List<OrderItemModel> items;
  final double subtotal;
  final double serviceFee;
  final OrderType orderType;
  OrderStatus status;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    required this.paymentMethod,
    required this.fromName,
    required this.fromAddress,
    required this.toName,
    required this.toPhone,
    required this.toAddress,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.orderType,
    this.status = OrderStatus.submitted,
  });

  double get total => subtotal + serviceFee;

  bool get isCancellable => status == OrderStatus.submitted;

  // ── Status label depending on order type ──
  String get statusLabel {
    switch (status) {
      case OrderStatus.submitted:
        return 'Order Submitted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyOrOutForDelivery:
        return orderType == OrderType.delivery
            ? 'Out For Delivery'
            : 'Ready For Collection';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  // ── Banner description depending on type + status ──
  String get statusDescription {
    if (orderType == OrderType.delivery) {
      switch (status) {
        case OrderStatus.submitted:
          return 'We will prepare your order shortly. You may cancel order before your order is being prepared your order is wrong.';
        case OrderStatus.preparing:
          return 'Your order is being prepared. You\'ll receive a notification when your order is out for delivery.';
        case OrderStatus.readyOrOutForDelivery:
          return 'Your order is on the way! Please be ready to retrieve your meal.';
        case OrderStatus.completed:
          return 'This order has been delivered. Please order from us again!';
      }
    } else {
      switch (status) {
        case OrderStatus.submitted:
          return 'We will prepare your order shortly. You may cancel order before your order is being prepared.';
        case OrderStatus.preparing:
          return 'Your order is being prepared. You\'ll receive a notification when your order is ready for collection.';
        case OrderStatus.readyOrOutForDelivery:
          return 'Your order is ready! Please collect your order within 2 hours of ordering.';
        case OrderStatus.completed:
          return 'This order has been picked up. Please order from us again!';
      }
    }
  }

  // ── Image asset path per status ──
  String get statusImagePath {
    switch (status) {
      case OrderStatus.submitted:
        return 'assets/images/order_submitted_tick_icon.png';
      case OrderStatus.preparing:
        return 'assets/images/cooking_icon.png';
      case OrderStatus.readyOrOutForDelivery:
        return orderType == OrderType.delivery
            ? 'assets/images/delivery_boy.png'
            : 'assets/images/collect_food_icon.png';
      case OrderStatus.completed:
        return 'assets/images/collect_food_success_icon.png';
    }
  }
}

class OrderItemModel {
  final String name;
  final List<String> addOns;
  final double price;

  OrderItemModel({
    required this.name,
    required this.addOns,
    required this.price,
  });
}