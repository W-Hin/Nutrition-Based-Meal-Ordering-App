import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/order_controller.dart';
import '../../model/order_model.dart';
import '../../service/supabase_conn.dart';

/// Pass [historyOrderId] when navigating from MyOrdersPage.
/// When set, the page loads the order directly from Supabase
/// instead of reading from OrderController.currentOrder.
class OrderDetailsPage extends StatefulWidget {
  /// DB bigint order_id — supplied when navigating from MyOrdersPage.
  final String? historyOrderId;

  const OrderDetailsPage({super.key, this.historyOrderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  static const _green = Color(0xFF1E4620);
  static const _bg    = Color(0xFFF5F5F0);

  // ── State for history-mode (loaded from Supabase directly) ────────────────
  Map<String, dynamic>? _historyRow;
  bool  _historyLoading  = false;
  bool  _historyCancelling = false;
  bool  _historyCancelled  = false;
  String? _historyError;

  bool get _isHistoryMode => widget.historyOrderId != null;

  @override
  void initState() {
    super.initState();
    if (_isHistoryMode) {
      _loadHistoryOrder();
    } else {
      // Live order — subscribe to real-time status updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctrl = context.read<OrderController>();
        if (ctrl.dbOrderId != null) _listenToOrderStatus(ctrl);
      });
    }
  }

  // ── Load a past order row from Supabase (history mode) ───────────────────
  Future<void> _loadHistoryOrder() async {
    setState(() { _historyLoading = true; _historyError = null; });
    try {
      final row = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('order_id', int.parse(widget.historyOrderId!))
          .single();
      setState(() { _historyRow = Map<String, dynamic>.from(row); });
    } catch (e) {
      setState(() { _historyError = e.toString(); });
    } finally {
      setState(() { _historyLoading = false; });
    }
  }

  // ── Cancel a history-mode order (updates DB then refreshes local state) ───
  Future<void> _cancelHistoryOrder() async {
    setState(() { _historyCancelling = true; });
    try {
      await supabase
          .from('orders')
          .update({'status': 'cancelled', 'is_cancellable': false})
          .eq('order_id', int.parse(widget.historyOrderId!));

      setState(() {
        _historyCancelled = true;
        if (_historyRow != null) {
          _historyRow!['status']        = 'cancelled';
          _historyRow!['is_cancellable'] = false;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _historyCancelling = false; });
    }
  }

  // ── Confirm cancel dialog ─────────────────────────────────────────────────
  void _showCancelDialog({
    required VoidCallback onConfirm,
  }) {
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
              onConfirm();
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Color(0xFFD95F2B))),
          ),
        ],
      ),
    );
  }

  // ── Real-time listener (live-order mode only) ─────────────────────────────
  void _listenToOrderStatus(OrderController ctrl) {
    ctrl.watchOrderStatus(ctrl.dbOrderId!).listen((row) {
      if (!mounted) return;
      final raw = (row['status'] as String? ?? '').toLowerCase();
      OrderStatus? s;
      switch (raw) {
        case 'submitted':            s = OrderStatus.submitted;             break;
        case 'preparing':            s = OrderStatus.preparing;             break;
        case 'out_for_delivery':
        case 'ready_for_collection': s = OrderStatus.readyOrOutForDelivery; break;
        case 'completed':            s = OrderStatus.completed;             break;
      }
      if (s != null) ctrl.updateStatus(s);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return _isHistoryMode ? _buildHistoryView() : _buildLiveView();
  }

  // ── LIVE ORDER VIEW (from OrderController.currentOrder) ───────────────────
  Widget _buildLiveView() {
    final ctrl  = context.watch<OrderController>();
    final order = ctrl.currentOrder;

    if (order == null) {
      return const Scaffold(body: Center(child: Text('No order found.')));
    }

    final isCancelled = ctrl.isCancelled;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubmittedBanner(
              statusLabel:       isCancelled ? 'Order Cancelled' : order.statusLabel,
              statusDescription: isCancelled
                  ? 'Your order has been cancelled. Refund will be processed within 3–5 business days.'
                  : order.statusDescription,
              statusImagePath:   order.statusImagePath,
              isCancelled:       isCancelled,
            ),
            const SizedBox(height: 16),
            if (!isCancelled)
              _StatusTracker(
                  status: order.status, orderType: order.orderType),
            const SizedBox(height: 16),
            _InfoSection(
                title: 'From',
                lines: [order.fromName, order.fromAddress]),
            const SizedBox(height: 12),
            _InfoSection(
              title: order.orderType == OrderType.delivery
                  ? 'Deliver To'
                  : 'Self Collection',
              lines: [
                order.orderType == OrderType.delivery
                    ? '${order.toName}  |  ${order.toPhone}'
                    : order.toName,
                order.toAddress,
              ],
            ),
            const SizedBox(height: 16),

            // ── Item Details with cancel ──
            _LiveItemDetailsSection(ctrl: ctrl, order: order,
                onCancelTap: () => _showCancelDialog(
                    onConfirm: ctrl.cancelOrder)),
            const SizedBox(height: 16),
            _LiveOrderInfoSection(order: order),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── HISTORY ORDER VIEW (loaded from Supabase) ─────────────────────────────
  Widget _buildHistoryView() {
    if (_historyLoading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(context),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E4620))),
      );
    }

    if (_historyError != null || _historyRow == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFCCC9B8)),
              const SizedBox(height: 12),
              const Text('Failed to load order details.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadHistoryOrder,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final row       = _historyRow!;
    final status    = (row['status']     as String? ?? '').toLowerCase();
    final orderType = (row['order_type'] as String? ?? '').toLowerCase();
    final items     = List<Map<String, dynamic>>.from(
        row['order_items'] as List? ?? []);
    final subtotal  = (row['subtotal']    as num?)?.toDouble() ?? 0.0;
    final svcFee    = (row['service_fee'] as num?)?.toDouble() ?? 0.0;
    final delFee    = (row['delivery_fee']as num?)?.toDouble() ?? 0.0;
    final total     = (row['total']       as num?)?.toDouble() ?? 0.0;
    final fromName  = 'NuBurn - Tanjung Burma';
    final fromAddr  = row['store_id'] as String? ?? '';
    final toName    = row['to_name']    as String? ?? '';
    final toPhone   = row['to_phone']   as String? ?? '';
    final toAddress = row['to_address'] as String? ?? '';
    final remark    = row['remark']     as String? ?? '';
    final payMethod = row['payment_method'] as String? ?? 'Credit / Debit Card';
    final orderId   = row['order_id'].toString();
    final rawDate   = row['order_date'] as String?
        ?? row['created_at'] as String? ?? '';
    final orderDate = rawDate.isNotEmpty
        ? DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final isCancelled = _historyCancelled || status == 'cancelled';
    final isCancellable =
        !isCancelled && (row['is_cancellable'] as bool? ?? false);

    final statusLabel = _historyStatusLabel(status, orderType, isCancelled);
    final statusDesc  = _historyStatusDesc(status, orderType, isCancelled);

    // Map DB status string → enum for the tracker
    final trackerStatus = _mapStatus(status);
    final trackerType   = orderType == 'delivery'
        ? OrderType.delivery
        : OrderType.selfCollect;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubmittedBanner(
              statusLabel:       statusLabel,
              statusDescription: statusDesc,
              statusImagePath:   _historyImagePath(status, orderType),
              isCancelled:       isCancelled,
            ),
            const SizedBox(height: 16),
            if (!isCancelled)
              _StatusTracker(
                  status: trackerStatus, orderType: trackerType),
            const SizedBox(height: 16),
            _InfoSection(
                title: 'From',
                lines: [fromName, fromAddr.isNotEmpty ? fromAddr : '—']),
            const SizedBox(height: 12),
            _InfoSection(
              title: orderType == 'delivery'
                  ? 'Deliver To'
                  : 'Self Collection',
              lines: [
                orderType == 'delivery' && toPhone.isNotEmpty
                    ? '$toName  |  $toPhone'
                    : toName,
                toAddress,
              ],
            ),
            const SizedBox(height: 16),

            // ── Item Details ──
            _HistoryItemDetailsSection(
              items:          items,
              subtotal:       subtotal,
              total:          total,
              isCancellable:  isCancellable,
              isCancelling:   _historyCancelling,
              onCancelTap:    () => _showCancelDialog(
                  onConfirm: _cancelHistoryOrder),
            ),
            const SizedBox(height: 16),

            // ── Order Info ──
            _HistoryOrderInfoSection(
              orderId:       orderId,
              orderDate:     orderDate,
              paymentMethod: payMethod,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
    backgroundColor: _bg,
    elevation:       0,
    centerTitle:     true,
    leading: IconButton(
      icon:      const Icon(Icons.arrow_back, color: _green),
      onPressed: () => _isHistoryMode
          ? Navigator.pop(context)
          : Navigator.popUntil(context, (r) => r.isFirst),
    ),
    title: const Text(
      'Order Details',
      style: TextStyle(
          color:      _green,
          fontWeight: FontWeight.w800,
          fontSize:   18),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  OrderStatus _mapStatus(String s) {
    switch (s) {
      case 'preparing':            return OrderStatus.preparing;
      case 'out_for_delivery':
      case 'ready_for_collection': return OrderStatus.readyOrOutForDelivery;
      case 'completed':
      case 'delivered':
      case 'retrieved':            return OrderStatus.completed;
      default:                     return OrderStatus.submitted;
    }
  }

  String _historyStatusLabel(
      String status, String orderType, bool isCancelled) {
    if (isCancelled) return 'Order Cancelled';
    switch (status) {
      case 'preparing':            return 'Preparing';
      case 'out_for_delivery':     return 'Out For Delivery';
      case 'ready_for_collection': return 'Ready For Collection';
      case 'completed':
      case 'delivered':
      case 'retrieved':
        return orderType == 'delivery' ? 'Delivered' : 'Completed';
      default:                     return 'Order Submitted';
    }
  }

  String _historyStatusDesc(
      String status, String orderType, bool isCancelled) {
    if (isCancelled) {
      return 'Your order has been cancelled. Refund will be processed within 3–5 business days.';
    }
    final isDelivery = orderType == 'delivery';
    switch (status) {
      case 'submitted':
        return 'We will prepare your order shortly. You may cancel your order before it is being prepared.';
      case 'preparing':
        return isDelivery
            ? "Your order is being prepared. You'll receive a notification when your order is out for delivery."
            : "Your order is being prepared. You'll receive a notification when your order is ready for collection.";
      case 'out_for_delivery':
        return 'Your order is on the way! Please be ready to retrieve your meal.';
      case 'ready_for_collection':
        return 'Your order is ready! Please collect your order within 2 hours of ordering.';
      case 'completed':
      case 'delivered':
      case 'retrieved':
        return isDelivery
            ? 'This order has been delivered. Please order from us again!'
            : 'This order has been picked up. Please order from us again!';
      default:
        return '';
    }
  }

  String _historyImagePath(String status, String orderType) {
    switch (status) {
      case 'preparing':
        return 'assets/images/cooking_icon.png';
      case 'out_for_delivery':
        return 'assets/images/delivery_boy.png';
      case 'ready_for_collection':
        return 'assets/images/collect_food_icon.png';
      case 'completed':
      case 'delivered':
      case 'retrieved':
        return 'assets/images/collect_food_success_icon.png';
      default:
        return 'assets/images/order_submitted_tick_icon.png';
    }
  }
}

// ── Submitted Banner ───────────────────────────────────────────────────────────

class _SubmittedBanner extends StatelessWidget {
  final String statusLabel;
  final String statusDescription;
  final String statusImagePath;
  final bool   isCancelled;

  const _SubmittedBanner({
    required this.statusLabel,
    required this.statusDescription,
    required this.statusImagePath,
    required this.isCancelled,
  });

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
                Text(statusLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize:   16,
                        color:      Color(0xFF2C2C2C))),
                const SizedBox(height: 8),
                Text(statusDescription,
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
            statusImagePath,
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
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final isCompleted = (i ~/ 2) < activeIndex;
            return Expanded(
              child: Container(
                height: 2,
                color:  isCompleted ? _green : const Color(0xFFDDDDD0),
              ),
            );
          }
          final stepIndex   = i ~/ 2;
          final isCompleted = stepIndex <= activeIndex;
          final step        = steps[stepIndex];

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
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   9,
                  fontWeight: isCompleted
                      ? FontWeight.w700
                      : FontWeight.w400,
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
  final String   label;
  const _Step({required this.icon, required this.label});
}

// ── Info Section ───────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String       title;
  final List<String> lines;

  const _InfoSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ── Live Item Details (uses OrderController for cancel) ───────────────────────

class _LiveItemDetailsSection extends StatelessWidget {
  final OrderController ctrl;
  final OrderModel      order;
  final VoidCallback    onCancelTap;

  static const _terracotta = Color(0xFFD95F2B);

  const _LiveItemDetailsSection({
    required this.ctrl,
    required this.order,
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
              if (order.isCancellable && !ctrl.isCancelled)
                GestureDetector(
                  onTap: onCancelTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border:       Border.all(
                          color: _terracotta, width: 1.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ctrl.isCancelling
                        ? const SizedBox(
                      width:  14,
                      height: 14,
                      child:  CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _terracotta),
                    )
                        : const Text(
                      'CANCEL ORDER',
                      style: TextStyle(
                        color:         _terracotta,
                        fontSize:      11,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => _OrderItemRow(
            name:   item.name,
            addOns: item.addOns,
          )),
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RM ${_fmt(order.subtotal)}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF2C2C2C))),
                const SizedBox(height: 4),
                const Text('Service Fee (5%) included *',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 4),
                Text(
                  'Total ${order.items.length} item(s): RM ${_fmt(order.total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize:   14,
                    color:      Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── History Item Details (uses Supabase row data for cancel) ──────────────────

class _HistoryItemDetailsSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double       subtotal;
  final double       total;
  final bool         isCancellable;
  final bool         isCancelling;
  final VoidCallback onCancelTap;

  static const _terracotta = Color(0xFFD95F2B);

  const _HistoryItemDetailsSection({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.isCancellable,
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
              if (isCancellable)
                GestureDetector(
                  onTap: onCancelTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border:       Border.all(
                          color: _terracotta, width: 1.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCancelling
                        ? const SizedBox(
                      width:  14,
                      height: 14,
                      child:  CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _terracotta),
                    )
                        : const Text(
                      'CANCEL ORDER',
                      style: TextStyle(
                        color:         _terracotta,
                        fontSize:      11,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _OrderItemRow(
            name:   item['name']  as String? ?? '',
            addOns: List<String>.from(
                item['add_ons'] as List? ?? []),
          )),
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RM ${_fmt(subtotal)}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF2C2C2C))),
                const SizedBox(height: 4),
                const Text('Service Fee (5%) included *',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 4),
                Text(
                  'Total ${items.length} item(s): RM ${_fmt(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize:   14,
                    color:      Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── Shared item row ────────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final String       name;
  final List<String> addOns;

  const _OrderItemRow({required this.name, required this.addOns});

  @override
  Widget build(BuildContext context) {
    final half = (addOns.length / 2).ceil();
    final col1 = addOns.isNotEmpty ? addOns.sublist(0, half) : <String>[];
    final col2 = addOns.length > 1  ? addOns.sublist(half)   : <String>[];

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
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                if (addOns.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _col(col1)),
                      if (col2.isNotEmpty) Expanded(child: _col(col2)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _col(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map((a) => Text('+ $a',
        style: const TextStyle(
            fontSize: 10, color: Color(0xFF8A8A8A))))
        .toList(),
  );
}

// ── Live Order Info ────────────────────────────────────────────────────────────

class _LiveOrderInfoSection extends StatelessWidget {
  final OrderModel order;
  const _LiveOrderInfoSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final d = order.orderDate;
    final dateStr = '${d.day} ${_month(d.month)} ${d.year}';
    return _OrderInfoBox(
      orderId:       order.orderId,
      dateStr:       dateStr,
      paymentMethod: order.paymentMethod,
    );
  }

  String _month(int m) => [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}

// ── History Order Info ─────────────────────────────────────────────────────────

class _HistoryOrderInfoSection extends StatelessWidget {
  final String   orderId;
  final DateTime orderDate;
  final String   paymentMethod;

  const _HistoryOrderInfoSection({
    required this.orderId,
    required this.orderDate,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final d = orderDate;
    final dateStr = '${d.day} ${_month(d.month)} ${d.year}';
    return _OrderInfoBox(
      orderId:       orderId,
      dateStr:       dateStr,
      paymentMethod: paymentMethod,
    );
  }

  String _month(int m) => [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}

class _OrderInfoBox extends StatelessWidget {
  final String orderId;
  final String dateStr;
  final String paymentMethod;

  const _OrderInfoBox({
    required this.orderId,
    required this.dateStr,
    required this.paymentMethod,
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
          const Text('Order Info',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize:   14,
                  color:      Color(0xFF2C2C2C))),
          const SizedBox(height: 12),
          _InfoRow(label: 'Order ID',       value: orderId),
          const SizedBox(height: 6),
          _InfoRow(label: 'Order Date',     value: dateStr),
          const SizedBox(height: 6),
          _InfoRow(label: 'Payment Method', value: paymentMethod),
        ],
      ),
    );
  }
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
                fontSize:   12,
                color:      Color(0xFF2C2C2C),
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}