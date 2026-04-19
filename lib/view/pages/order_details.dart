import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/order_controller.dart';
import '../../model/order_model.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  @override
  Widget build(BuildContext context) {
    final ctrl  = context.watch<OrderController>();
    final order = ctrl.currentOrder;

    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('No order found.')),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: _green,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Order submitted banner ──
            _SubmittedBanner(order: order, isCancelled: ctrl.isCancelled),
            const SizedBox(height: 16),

            // ── Progress tracker ──
            if (!ctrl.isCancelled)
              _StatusTracker(status: order.status, orderType: order.orderType),
            const SizedBox(height: 16),

            // ── From ──
            _InfoSection(
              title: 'From',
              lines: [order.fromName, order.fromAddress],
            ),
            const SizedBox(height: 12),

            // ── Deliver To ──
            _InfoSection(
              title: 'Deliver To',
              lines: [
                '${order.toName}  |  ${order.toPhone}',
                order.toAddress,
              ],
            ),
            const SizedBox(height: 16),

            // ── Item Details ──
            _ItemDetailsSection(ctrl: ctrl, order: order),
            const SizedBox(height: 16),

            // ── Order Info ──
            _OrderInfoSection(order: order),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Submitted Banner ───────────────────────────────────────────────────────────

class _SubmittedBanner extends StatelessWidget {
  final OrderModel order;
  final bool isCancelled;

  const _SubmittedBanner({
    required this.order,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCancelled ? 'Order Cancelled' : order.statusLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCancelled
                      ? 'Your order has been cancelled. Refund will be processed within 3-5 business days.'
                      : order.statusDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6B6B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status image — falls back to icon if asset not found
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isCancelled
                ? Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: Colors.red, size: 32),
            )
                : Image.asset(
              order.statusImagePath,
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              // Shows placeholder icon if image file not found yet
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFD95F2B), width: 2),
                ),
                child: const Icon(Icons.shopping_basket_outlined,
                    color: Color(0xFFD95F2B), size: 32),
              ),
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
  final OrderType orderType;

  static const _green = Color(0xFF1E4620);

  const _StatusTracker({required this.status, required this.orderType});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(icon: Icons.receipt_outlined,          label: 'Order\nSubmitted'),
      _Step(icon: Icons.soup_kitchen_outlined,      label: 'Preparing'),
      _Step(
        icon: orderType == OrderType.delivery
            ? Icons.directions_bike_outlined
            : Icons.storefront_outlined,
        label: orderType == OrderType.delivery
            ? 'Out For\nDelivery'
            : 'Ready For\nCollection',
      ),
      _Step(
        icon: orderType == OrderType.delivery
            ? Icons.home_outlined
            : Icons.check_circle_outline,
        label: 'Completed',
      ),
    ];

    final activeIndex = status.index;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final isCompleted = (i ~/ 2) < activeIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? _green : const Color(0xFFDDDDD0),
              ),
            );
          }
          final stepIndex  = i ~/ 2;
          final isCompleted = stepIndex <= activeIndex;
          final step        = steps[stepIndex];

          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? _green : const Color(0xFFEEEBDE),
                ),
                child: Icon(step.icon,
                    size: 18,
                    color: isCompleted ? Colors.white : const Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 6),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  isCompleted ? FontWeight.w700 : FontWeight.w400,
                  color: isCompleted ? _green : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String label;
  const _Step({required this.icon, required this.label});
}

// ── Info Section (From / Deliver To) ──────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF2C2C2C))),
          const SizedBox(height: 6),
          ...lines.map((l) => Text(l,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  height: 1.5))),
        ],
      ),
    );
  }
}

// ── Item Details Section ───────────────────────────────────────────────────────

class _ItemDetailsSection extends StatelessWidget {
  final OrderController ctrl;
  final OrderModel order;

  static const _terracotta = Color(0xFFD95F2B);

  const _ItemDetailsSection({required this.ctrl, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Item Details',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF2C2C2C)),
              ),
              // Cancel button — only visible if cancellable and not cancelled
              if (order.isCancellable && !ctrl.isCancelled)
                GestureDetector(
                  onTap: () => _confirmCancel(context, ctrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: _terracotta, width: 1.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ctrl.isCancelling
                        ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _terracotta),
                    )
                        : const Text(
                      'CANCEL ORDER',
                      style: TextStyle(
                        color: _terracotta,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Items list ──
          ...order.items.map((item) => _ItemRow(item: item)),
          const Divider(height: 20),

          // ── Totals ──
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${order.subtotal % 1 == 0 ? order.subtotal.toInt().toString() : order.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF2C2C2C)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service Fee (5%) included *',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8A8A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total ${order.items.length} item(s): RM ${order.total % 1 == 0 ? order.total.toInt().toString() : order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'Are you sure you want to cancel this order? This cannot be undone.'),
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

class _ItemRow extends StatelessWidget {
  final OrderItemModel item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final half = (item.addOns.length / 2).ceil();
    final col1 = item.addOns.isNotEmpty ? item.addOns.sublist(0, half) : [];
    final col2 =
    item.addOns.length > 1 ? item.addOns.sublist(half) : [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D5C5),
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

  Widget _addOnCol(List addOns) => Column(
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
  final OrderModel order;

  const _OrderInfoSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${order.orderDate.day} ${_month(order.orderDate.month)} ${order.orderDate.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Info',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF2C2C2C))),
          const SizedBox(height: 12),
          _InfoRow(label: 'Order ID', value: order.orderId),
          const SizedBox(height: 6),
          _InfoRow(label: 'Order Date', value: dateStr),
          const SizedBox(height: 6),
          _InfoRow(label: 'Payment Method', value: order.paymentMethod),
        ],
      ),
    );
  }

  String _month(int m) => [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B6B6B))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}