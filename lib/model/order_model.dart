enum OrderType { delivery, selfCollect }

enum OrderStatus {
  submitted,
  preparing,
  readyOrOutForDelivery, // "Out for Delivery" OR "Ready for Collection"
  completed,
  cancelled,
}

class OrderModel {
  final String orderId;
  final DateTime orderDate;
  final String paymentMethod;
  final String? storeId;
  final String fromName;
  final String fromAddress;
  final String toName;
  final String toPhone;
  final String toAddress;
  final List<OrderItemModel> items;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double totalCal;
  final double totalPro;
  final double totalCarb;
  final double totalFat;
  final OrderType orderType;
  final String remark;
  final String? collectionCode; // ← 3-digit random code for self-collect orders
  OrderStatus status;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    required this.paymentMethod,
    this.storeId,
    required this.fromName,
    required this.fromAddress,
    required this.toName,
    required this.toPhone,
    required this.toAddress,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    this.totalCal = 0,
    this.totalPro = 0,
    this.totalCarb = 0,
    this.totalFat = 0,
    required this.orderType,
    this.remark = '',
    this.collectionCode,
    this.status = OrderStatus.submitted,
  });

  double get total => subtotal + serviceFee + deliveryFee;

  bool get isCancellable => status == OrderStatus.submitted;

  // Status label depending on order type
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
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Banner description depending on type + status
  String get statusDescription {
    if (orderType == OrderType.delivery) {
      switch (status) {
        case OrderStatus.submitted:
          return 'We will prepare your order shortly. You may cancel your order before it is being prepared.';
        case OrderStatus.preparing:
          return "Your order is being prepared. You'll receive a notification when your order is out for delivery.";
        case OrderStatus.readyOrOutForDelivery:
          return 'Your order is on the way! Please be ready to retrieve your meal.';
        case OrderStatus.completed:
          return 'This order has been delivered. Please order from us again!';
        case OrderStatus.cancelled:
          return 'This order has been cancelled.';
      }
    } else {
      switch (status) {
        case OrderStatus.submitted:
          return 'We will prepare your order shortly. You may cancel your order before it is being prepared.';
        case OrderStatus.preparing:
          return "Your order is being prepared. You'll receive a notification when your order is ready for collection.";
        case OrderStatus.readyOrOutForDelivery:
          return 'Your order is ready! Please collect your order within 2 hours of ordering.';
        case OrderStatus.completed:
          return 'This order has been picked up. Please Order from Us Again!';
        case OrderStatus.cancelled:
          return 'This order has been cancelled.';
      }
    }
  }

  // Image asset path per status
  String get statusImagePath {
    switch (status) {
      case OrderStatus.submitted:
        return 'assets/images/order_submitted_tick_icon.png';
      case OrderStatus.preparing:
        return 'assets/images/cooking_icon.png';
      case OrderStatus.readyOrOutForDelivery:
        if (orderType == OrderType.delivery) {
          return 'assets/images/delivery_boy.png';
        }
        return 'assets/images/carry_food_icon.jpg';
      case OrderStatus.completed:
        if (orderType == OrderType.delivery) {
          return 'assets/images/collect_food_success_icon.png';
        }
        return 'assets/images/carry_food_icon.jpg';
      case OrderStatus.cancelled:
        // Use a default error or cancel icon if available, fallback to tick
        return 'assets/images/order_submitted_tick_icon.png';
    }
  }
}

class OrderItemModel {
  final String name;
  final List<String> addOns;
  final double price;
  final int quantity;
  final String? foodId;
  final String? imageUrl;

  OrderItemModel({
    required this.name,
    required this.addOns,
    required this.price,
    this.quantity = 1,      // default to 1 for backward compat
    this.foodId,
    this.imageUrl,
  });
}
