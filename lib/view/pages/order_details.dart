import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/order_controller.dart';
import '../../model/order_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderDetailsPage accepts optional "passed" fields.
//
// TWO ways to open this page:
//
//  1. After fresh payment → no passed fields, reads from OrderController
//     Navigator.push(..., OrderDetailsPage())
//
//  2. From My Orders list → pass fields directly (like PHP passing row data)
//     Navigator.push(..., OrderDetailsPage(passedId: '001', passedStatus: 'preparing', ...))
//
// TODO: When Supabase is wired up, you can simplify case 2 to just pass
//       passedId and fetch the full row inside this page:
//       final row = await supabase.from('orders').select('*, order_items(*)')
//           .eq('id', passedId).single();
// ─────────────────────────────────────────────────────────────────────────────

class OrderDetailsPage extends StatelessWidget {
  // ── Fields passed from My Orders (optional) ──
  final String?              passedId;
  final String?              passedFromName;
  final String?              passedFromAddress;
  final String?              passedToName;
  final String?              passedToPhone;
  final String?              passedToAddress;
  final DateTime?            passedDate;
  final double?              passedSubtotal;
  final double?              passedServiceFee;
  final bool                 passedIsCancelled;
  final String?              passedOrderType;   // 'delivery' or 'selfCollect'
  final String?              passedStatus;      // e.g. 'preparing', 'completed'
  final String?              passedRemarks;
  final List<Map<String, dynamic>>? passedItems; // [{name, price, addOns}]

  const OrderDetailsPage({
    super.key,
    this.passedId,
    this.passedFromName,
    this.passedFromAddress,
    this.passedToName,
    this.passedToPhone,
    this.passedToAddress,
    this.passedDate,
    this.passedSubtotal,
    this.passedServiceFee,
    this.passedIsCancelled = false,
    this.passedOrderType,
    this.passedStatus,
    this.passedRemarks,
    this.passedItems,
  });

  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  // ── Determine if we're in read-only mode (came from My Orders) ──
  bool get _isReadOnly => passedId != null;

  // ── Resolve display values ──
  // Uses passed fields if available, otherwise falls back to OrderController
  String _resolveFromName(OrderModel? m)    => passedFromName    ?? m?.fromName    ?? '';
  String _resolveFromAddress(OrderModel? m) => passedFromAddress ?? m?.fromAddress ?? '';
  String _resolveToName(OrderModel? m)      => passedToName      ?? m?.toName      ?? '';
  String _resolveToPhone(OrderModel? m)     => passedToPhone     ?? m?.toPhone     ?? '';
  String _resolveToAddress(OrderModel? m)   => passedToAddress   ?? m?.toAddress   ?? '';
  double _resolveSubtotal(OrderModel? m)    => passedSubtotal    ?? m?.subtotal    ?? 0;
  double _resolveServiceFee(OrderModel? m)  => passedServiceFee  ?? m?.serviceFee  ?? 0;
  DateTime _resolveDate(OrderModel? m)      => passedDate        ?? m?.orderDate   ?? DateTime.now();

  OrderType _resolveOrderType(OrderModel? m) {
    if (passedOrderType == 'delivery') return OrderType.delivery;
    if (passedOrderType == 'selfCollect') return OrderType.selfCollect;
    return m?.orderType ?? OrderType.delivery;
  }

  OrderStatus _resolveStatus(OrderModel? m) {
    switch (passedStatus) {
      case 'submitted':  return OrderStatus.submitted;
      case 'preparing':  return OrderStatus.preparing;
      case 'readyOrOut': return OrderStatus.readyOrOutForDelivery;
      case 'completed':  return OrderStatus.completed;
      default:           return m?.status ?? OrderStatus.submitted;
    }
  }

  bool _resolveIsCancelled(bool ctrlCancelled) =>
      _isReadOnly ? passedIsCancelled : ctrlCancelled;

  @override
  Widget build(BuildContext context) {
    final ctrl  = context.watch<OrderController>();
    final model = ctrl.currentOrder; // null if opened from My Orders

    // If neither passed fields nor a fresh order exist, show error
    if (!_isReadOnly && model == null) {
      return const Scaffold(
        body: Center(child: Text('No order found.')),
      );
    }

    // ── Resolved values used throughout the page ──
    final fromName     = _resolveFromName(model);
    final fromAddress  = _resolveFromAddress(model);
    final toName       = _resolveToName(model);
    final toPhone      = _resolveToPhone(model);
    final toAddress    = _resolveToAddress(model);
    final subtotal     = _resolveSubtotal(model);
    final serviceFee   = _resolveServiceFee(model);
    final orderDate    = _resolveDate(model);
    final orderType    = _resolveOrderType(model);
    final status       = _resolveStatus(model);
    final isCancelled  = _resolveIsCancelled(ctrl.isCancelled);
    final orderId      = passedId ?? model?.orderId ?? '';
    final payMethod    = model?.paymentMethod ?? 'Stripe';
    final remarks      = passedRemarks ?? '';
    final total        = subtotal + serviceFee;

    // Build item list — from passed data or from OrderController
    final List<_DisplayItem> items = _isReadOnly
        ? (passedItems ?? []).map((i) => _DisplayItem(
      name:   i['name'] as String,
      price:  (i['price'] as num).toDouble(),
      addOns: List<String>.from(i['addOns'] ?? []),
    )).toList()
        : (model?.items ?? []).map((i) => _DisplayItem(
      name:   i.name,
      price:  i.price,
      addOns: i.addOns,
    )).toList();

    // Only show cancel button on fresh payment flow when status = submitted
    final bool canCancel = !_isReadOnly &&
        !isCancelled &&
        status == OrderStatus.submitted;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation:       0,
        centerTitle:     true,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: _green),
          // Read-only (from My Orders) → just pop back
          // Fresh payment → pop all the way to home
          onPressed: () => _isReadOnly
              ? Navigator.pop(context)
              : Navigator.popUntil(context, (r) => r.isFirst),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color:      _green,
            fontWeight: FontWeight.w800,
            fontSize:   18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ──
            _Banner(
              status:      status,
              orderType:   orderType,
              isCancelled: isCancelled,
            ),
            const SizedBox(height: 16),

            // ── Progress tracker ──
            if (!isCancelled) ...[
              _StatusTracker(status: status, orderType: orderType),
              const SizedBox(height: 16),
            ],

            // ── From ──
            _InfoSection(
              title: 'From',
              lines: [fromName, fromAddress],
            ),
            const SizedBox(height: 12),

            // ── Deliver To / Self Collect At ──
            _InfoSection(
              title: orderType == OrderType.delivery
                  ? 'Deliver To'
                  : 'Self Collect At',
              lines: [
                if (toPhone.isNotEmpty) '$toName  |  $toPhone' else toName,
                toAddress,
              ],
            ),
            const SizedBox(height: 16),

            // ── Item Details ──
            _ItemDetailsSection(
              items:       items,
              subtotal:    subtotal,
              total:       total,
              remarks:     remarks,
              canCancel:   canCancel,
              isCancelling: ctrl.isCancelling,
              onCancelTap: () => _confirmCancel(context, ctrl),
            ),
            const SizedBox(height: 16),

            // ── Order Info ──
            _OrderInfoSection(
              orderId:     orderId,
              orderDate:   orderDate,
              payMethod:   payMethod,
              orderType:   orderType,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, OrderController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to cancel? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It',
                style: TextStyle(color: Color(0xFF1E4620))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.cancelOrder();
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Color(0xFFD95F2B))),
          ),
        ],
      ),
    );
  }
}

// ── Simple display item (decoupled from OrderItemModel) ───────────────────────

class _DisplayItem {
  final String       name;
  final double       price;
  final List<String> addOns;
  _DisplayItem({required this.name, required this.price, required this.addOns});
}

// ── Banner ─────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final OrderStatus status;
  final OrderType   orderType;
  final bool        isCancelled;

  const _Banner({
    required this.status,
    required this.orderType,
    required this.isCancelled,
  });

  String get _label {
    if (isCancelled) return 'Order Cancelled';
    switch (status) {
      case OrderStatus.submitted:             return 'Order Submitted';
      case OrderStatus.preparing:             return 'Preparing';
      case OrderStatus.readyOrOutForDelivery:
        return orderType == OrderType.delivery
            ? 'Out For Delivery'
            : 'Ready For Collection';
      case OrderStatus.completed:
        return orderType == OrderType.delivery ? 'Delivered' : 'Completed';
    }
  }

  String get _description {
    if (isCancelled) {
      return 'Your order has been cancelled. Refund will be processed within 3-5 business days.';
    }
    if (orderType == OrderType.delivery) {
      switch (status) {
        case OrderStatus.submitted:
          return 'We will prepare your order shortly. You may cancel before preparation begins.';
        case OrderStatus.preparing:
          return 'Your order is being prepared. You\'ll be notified when it\'s out for delivery.';
        case OrderStatus.readyOrOutForDelivery:
          return 'Your order is on the way! Please be ready to retrieve your meal.';
        case OrderStatus.completed:
          return 'This order has been delivered. Please order from us again!';
      }
    } else {
      switch (status) {
        case OrderStatus.submitted:
          return 'We will prepare your order shortly. You may cancel before preparation begins.';
        case OrderStatus.preparing:
          return 'Your order is being prepared. You\'ll be notified when it\'s ready for collection.';
        case OrderStatus.readyOrOutForDelivery:
          return 'Your order is ready! Please collect within 2 hours.';
        case OrderStatus.completed:
          return 'This order has been picked up. Please order from us again!';
      }
    }
  }

  String get _imagePath {
    if (isCancelled) return '';
    switch (status) {
      case OrderStatus.submitted:
        return 'assets/images/order_submitted_tick_icon.png';
      case OrderStatus.preparing:
        return 'assets/images/cooking_icon.png';
      case OrderStatus.readyOrOutForDelivery:
        return orderType == OrderType.delivery
            ? 'assets/images/delivery_boy_icon.png'
            : 'assets/images/collect_food_icon.png';
      case OrderStatus.completed:
        return orderType == OrderType.delivery
            ? 'assets/images/delivery_boy_icon.png'
            : 'assets/images/collect_food_success_icon.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize:   16,
                        color:      Color(0xFF2C2C2C))),
                const SizedBox(height: 8),
                Text(_description,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    Color(0xFF6B6B6B),
                        height:   1.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isCancelled
              ? Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: const Icon(Icons.cancel_outlined,
                color: Colors.red, size: 32),
          )
              : Image.asset(
            _imagePath,
            width:  72,
            height: 72,
            fit:    BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFD95F2B), width: 2),
              ),
              child: const Icon(Icons.shopping_basket_outlined,
                  color: Color(0xFFD95F2B), size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Tracker ─────────────────────────────────────────────────────────────

class _StatusTracker extends StatelessWidget {
  final OrderStatus status;
  final OrderType   orderType;
  static const _green = Color(0xFF1E4620);

  const _StatusTracker({required this.status, required this.orderType});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(icon: Icons.receipt_outlined,     label: 'Order\nSubmitted'),
      _Step(icon: Icons.soup_kitchen_outlined, label: 'Preparing'),
      _Step(
        icon:  orderType == OrderType.delivery
            ? Icons.directions_bike_outlined
            : Icons.storefront_outlined,
        label: orderType == OrderType.delivery
            ? 'Out For\nDelivery'
            : 'Ready For\nCollection',
      ),
      _Step(
        icon:  orderType == OrderType.delivery
            ? Icons.home_outlined
            : Icons.check_circle_outline,
        label: 'Completed',
      ),
    ];
    final activeIndex = status.index;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color:  (i ~/ 2) < activeIndex
                    ? _green
                    : const Color(0xFFDDDDD0),
              ),
            );
          }
          final idx         = i ~/ 2;
          final isCompleted = idx <= activeIndex;
          final step        = steps[idx];
          return Column(
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? _green : const Color(0xFFEEEBDE),
                ),
                child: Icon(step.icon,
                    size:  18,
                    color: isCompleted
                        ? Colors.white
                        : const Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 6),
              Text(step.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   9,
                    fontWeight: isCompleted
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isCompleted
                        ? _green
                        : const Color(0xFFAAAAAA),
                  )),
            ],
          );
        }),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String   label;
  const _Step({required this.icon, required this.label});
}

// ── Info Section ───────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String       title;
  final List<String> lines;
  const _InfoSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: const Color(0xFFDDDDD0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize:   14,
                color:      Color(0xFF2C2C2C))),
        const SizedBox(height: 6),
        ...lines.map((l) => Text(l,
            style: const TextStyle(
                fontSize: 12,
                color:    Color(0xFF6B6B6B),
                height:   1.5))),
      ],
    ),
  );
}

// ── Item Details Section ───────────────────────────────────────────────────────

class _ItemDetailsSection extends StatelessWidget {
  final List<_DisplayItem> items;
  final double             subtotal;
  final double             total;
  final String             remarks;
  final bool               canCancel;
  final bool               isCancelling;
  final VoidCallback       onCancelTap;

  static const _terracotta = Color(0xFFD95F2B);

  const _ItemDetailsSection({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.remarks,
    required this.canCancel,
    required this.isCancelling,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Item Details',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   14,
                      color:      Color(0xFF2C2C2C))),
              if (canCancel) _CancelButton(
                  isCancelling: isCancelling, onTap: onCancelTap),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _ItemRow(item: item)),
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RM ${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF2C2C2C))),
                const SizedBox(height: 4),
                const Text('Service Fee (5%) included *',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 4),
                Text(
                  'Total ${items.length} item(s): RM ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   14,
                      color:      Color(0xFF2C2C2C)),
                ),
                if (remarks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Remark: $remarks',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancel Button ──────────────────────────────────────────────────────────────

class _CancelButton extends StatefulWidget {
  final bool         isCancelling;
  final VoidCallback onTap;
  const _CancelButton({required this.isCancelling, required this.onTap});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _pressed = false;
  static const _terracotta = Color(0xFFD95F2B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:       widget.onTap,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:        _pressed ? _terracotta : Colors.white,
          border:       Border.all(color: _terracotta, width: 1.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: widget.isCancelling
            ? const SizedBox(
          width:  14,
          height: 14,
          child:  CircularProgressIndicator(
              strokeWidth: 1.5, color: _terracotta),
        )
            : Text('CANCEL ORDER',
            style: TextStyle(
              color:        _pressed ? Colors.white : _terracotta,
              fontSize:     11,
              fontWeight:   FontWeight.w700,
              letterSpacing: 0.5,
            )),
      ),
    );
  }
}

// ── Item Row ───────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final _DisplayItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final half = (item.addOns.length / 2).ceil();
    final col1 = item.addOns.isNotEmpty
        ? item.addOns.sublist(0, half)
        : <String>[];
    final col2 = item.addOns.length > 1
        ? item.addOns.sublist(half)
        : <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  64,
            height: 64,
            decoration: BoxDecoration(
              color:        const Color(0xFFD9D5C5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood_outlined,
                color: Color(0xFF9E9880), size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                if (item.addOns.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _addOnCol(col1)),
                      if (col2.isNotEmpty) Expanded(child: _addOnCol(col2)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addOnCol(List<String> addOns) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: addOns
        .map((a) => Text('+ $a',
        style: const TextStyle(
            fontSize: 10, color: Color(0xFF8A8A8A))))
        .toList(),
  );
}

// ── Order Info Section ─────────────────────────────────────────────────────────

class _OrderInfoSection extends StatelessWidget {
  final String    orderId;
  final DateTime  orderDate;
  final String    payMethod;
  final OrderType orderType;

  const _OrderInfoSection({
    required this.orderId,
    required this.orderDate,
    required this.payMethod,
    required this.orderType,
  });

  String _fmt(DateTime d) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: const Color(0xFFDDDDD0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Info',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize:   14,
                color:      Color(0xFF2C2C2C))),
        const SizedBox(height: 12),
        _InfoRow(label: 'Order ID',       value: orderId),
        const SizedBox(height: 6),
        _InfoRow(label: 'Order Date',     value: _fmt(orderDate)),
        const SizedBox(height: 6),
        _InfoRow(label: 'Payment Method', value: payMethod),
        const SizedBox(height: 6),
        _InfoRow(
          label: 'Order Type',
          value: orderType == OrderType.delivery
              ? 'Delivery'
              : 'Self Collect',
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF6B6B6B))),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize:   12,
                color:      Color(0xFF2C2C2C),
                fontWeight: FontWeight.w500)),
      ),
    ],
  );
}