import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/order_controller.dart';
import '../../model/order_model.dart';
import '../../service/supabase_conn.dart';

/// Pass [historyOrderId] when navigating from MyOrdersPage.
/// When set, the page loads the order directly from Supabase
/// instead of reading from OrderController.currentOrder.
class OrderDetailsPage extends StatefulWidget {
  final String? historyOrderId;

  const OrderDetailsPage({super.key, this.historyOrderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  static const _green = Color(0xFF1E4620);
  static const _bg    = Color(0xFFF5F5F0);

  // ── History-mode state ────────────────────────────────────────────────────
  Map<String, dynamic>? _historyRow;
  Map<String, dynamic>? _storeRow;
  bool    _historyLoading    = false;
  bool    _historyCancelling = false;
  bool    _historyCancelled  = false;
  String? _historyError;

  // ── Live-mode store state ──────────────────────────────────────────────────
  Map<String, dynamic>? _liveStoreRow;

  bool get _isHistoryMode => widget.historyOrderId != null;

  @override
  void initState() {
    super.initState();
    if (_isHistoryMode) {
      _loadHistoryOrder();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctrl = context.read<OrderController>();
        if (ctrl.dbOrderId != null) _listenToOrderStatus(ctrl);
        final storeId = ctrl.currentOrder?.storeId;
        if (storeId != null && storeId.isNotEmpty) {
          _fetchLiveStore(storeId);
        }
      });
    }
  }

  Future<void> _fetchLiveStore(String storeId) async {
    try {
      final row = await supabase
          .from('stores')
          .select('id, name, address')
          .eq('id', storeId.trim())
          .maybeSingle();
      if (row != null && mounted) {
        setState(() => _liveStoreRow = Map<String, dynamic>.from(row));
      }
    } catch (e) {
      debugPrint('[OrderDetails] live store fetch error: $e');
    }
  }

  Future<void> _loadHistoryOrder() async {
    setState(() { _historyLoading = true; _historyError = null; });
    try {
      final row = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('order_id', int.parse(widget.historyOrderId!))
          .single();

      final orderMap = Map<String, dynamic>.from(row);

      final rawStoreId = orderMap['store_id'];
      final storeId = rawStoreId != null ? rawStoreId.toString().trim() : null;
      Map<String, dynamic>? storeMap;
      if (storeId != null && storeId.isNotEmpty) {
        try {
          final storeRow = await supabase
              .from('stores')
              .select('id, name, address')
              .eq('id', storeId)
              .maybeSingle();
          if (storeRow != null) {
            storeMap = Map<String, dynamic>.from(storeRow);
          }
        } catch (e) {
          debugPrint('[OrderDetails] store fetch error: $e');
        }
      }

      setState(() {
        _historyRow = orderMap;
        _storeRow   = storeMap;
      });
    } catch (e) {
      setState(() { _historyError = e.toString(); });
    } finally {
      setState(() { _historyLoading = false; });
    }
  }

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
          _historyRow!['status']         = 'cancelled';
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

  void _showCancelDialog({required VoidCallback onConfirm}) {
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

  @override
  Widget build(BuildContext context) {
    return _isHistoryMode ? _buildHistoryView() : _buildLiveView();
  }

  // ── LIVE ORDER VIEW ───────────────────────────────────────────────────────
  Widget _buildLiveView() {
    final ctrl  = context.watch<OrderController>();
    final order = ctrl.currentOrder;

    if (order == null) {
      return const Scaffold(body: Center(child: Text('No order found.')));
    }

    final isCancelled   = ctrl.isCancelled;
    final isSelfCollect = order.orderType == OrderType.selfCollect;

    final liveFromName    = (_liveStoreRow?['name']    as String?)?.trim() ?? order.fromName;
    final liveFromAddress = (_liveStoreRow?['address'] as String?)?.trim() ?? order.fromAddress;

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
              _StatusTracker(status: order.status, orderType: order.orderType),
            const SizedBox(height: 16),

            if (isSelfCollect) ...[
              _SelfCollectCodeCard(
                collectionCode: order.collectionCode,
                status:         order.status,
              ),
              const SizedBox(height: 12),
              _CollectAtCard(
                storeName:    liveFromName,
                storeAddress: liveFromAddress,
              ),
            ] else ...[
              _InfoSection(title: 'From',
                  lines: [liveFromName, liveFromAddress]),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Deliver To',
                lines: ['${order.toName}  |  ${order.toPhone}', order.toAddress],
              ),
            ],
            const SizedBox(height: 16),

            _LiveItemDetailsSection(
              ctrl:        ctrl,
              order:       order,
              onCancelTap: () => _showCancelDialog(onConfirm: ctrl.cancelOrder),
            ),
            const SizedBox(height: 16),
            _LiveOrderInfoSection(order: order),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── HISTORY ORDER VIEW ────────────────────────────────────────────────────
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
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCC9B8)),
              const SizedBox(height: 12),
              const Text('Failed to load order details.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadHistoryOrder,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final row            = _historyRow!;
    final status         = (row['status']        as String? ?? '').toLowerCase();
    final orderType      = (row['order_type']    as String? ?? '').toLowerCase();
    final isSelfCollect  = orderType == 'selfcollect' || orderType == 'self_collect';
    final items          = List<Map<String, dynamic>>.from(
        row['order_items'] as List? ?? []);
    final subtotal       = (row['subtotal']      as num?)?.toDouble() ?? 0.0;
    final serviceFee     = (row['service_fee']   as num?)?.toDouble() ?? 0.0;
    final deliveryFee    = (row['delivery_fee']  as num?)?.toDouble() ?? 0.0;
    final total          = (row['total']         as num?)?.toDouble() ?? 0.0;
    final toName         = row['to_name']        as String? ?? '';
    final toPhone        = row['to_phone']       as String? ?? '';
    final toAddress      = row['to_address']     as String? ?? '';
    final payMethod      = row['payment_method'] as String? ?? 'Credit / Debit Card';
    final orderId        = row['order_id'].toString();
    final collectionCode = row['collection_code'] as String?;
    final remark         = row['remark']         as String? ?? '';

    final fromName    = (_storeRow?['name']    as String?)?.trim() ?? '';
    final fromAddress = (_storeRow?['address'] as String?)?.trim() ?? '';

    final rawDate   = row['order_date']  as String?
        ?? row['created_at'] as String? ?? '';
    final orderDate = rawDate.isNotEmpty
        ? DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final isCancelled   = _historyCancelled || status == 'cancelled';
    final isCancellable = !isCancelled && (row['is_cancellable'] as bool? ?? false);

    final statusLabel = _historyStatusLabel(status, orderType, isCancelled);
    final statusDesc  = _historyStatusDesc(status, orderType, isCancelled);

    final trackerStatus = _mapStatus(status);
    final trackerType   = isSelfCollect
        ? OrderType.selfCollect
        : OrderType.delivery;

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
              _StatusTracker(status: trackerStatus, orderType: trackerType),
            const SizedBox(height: 16),

            if (isSelfCollect) ...[
              _SelfCollectCodeCard(
                collectionCode: collectionCode,
                status:         trackerStatus,
              ),
              const SizedBox(height: 12),
              if (fromName.isNotEmpty)
                _CollectAtCard(
                  storeName:    fromName,
                  storeAddress: fromAddress.isNotEmpty ? fromAddress : null,
                ),
            ] else ...[
              if (fromName.isNotEmpty)
                _InfoSection(
                  title: 'From',
                  lines: [
                    fromName,
                    if (fromAddress.isNotEmpty) fromAddress,
                  ],
                ),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Deliver To',
                lines: [
                  toPhone.isNotEmpty ? '$toName  |  $toPhone' : toName,
                  toAddress,
                ],
              ),
            ],
            const SizedBox(height: 16),

            _HistoryItemDetailsSection(
              items:         items,
              subtotal:      subtotal,
              serviceFee:    serviceFee,
              deliveryFee:   deliveryFee,
              total:         total,
              remark:        remark,
              isSelfCollect: isSelfCollect,
              isCancellable: isCancellable,
              isCancelling:  _historyCancelling,
              onCancelTap:   () => _showCancelDialog(onConfirm: _cancelHistoryOrder),
            ),
            const SizedBox(height: 16),

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

  String _historyStatusLabel(String status, String orderType, bool isCancelled) {
    if (isCancelled) return 'Order Cancelled';
    switch (status) {
      case 'preparing':            return 'Preparing';
      case 'out_for_delivery':     return 'Out For Delivery';
      case 'ready_for_collection': return 'Ready For Collection';
      case 'completed':
      case 'delivered':
      case 'retrieved':
        final isSC = orderType == 'selfcollect' || orderType == 'self_collect';
        return isSC ? 'Completed' : 'Delivered';
      default:                     return 'Order Submitted';
    }
  }

  String _historyStatusDesc(String status, String orderType, bool isCancelled) {
    if (isCancelled) {
      return 'Your order has been cancelled. Refund will be processed within 3–5 business days.';
    }
    final isSC = orderType == 'selfcollect' || orderType == 'self_collect';
    switch (status) {
      case 'submitted':
        return 'We will prepare your order shortly. You may cancel your order before it is being prepared.';
      case 'preparing':
        return isSC
            ? "Your order is being prepared. You'll receive a notification when your order is ready for collection."
            : "Your order is being prepared. You'll receive a notification when your order is out for delivery.";
      case 'out_for_delivery':
        return 'Your order is on the way! Please be ready to retrieve your meal.';
      case 'ready_for_collection':
        return 'Your order is ready! Please collect your order within 2 hours of ordering.';
      case 'completed':
      case 'delivered':
      case 'retrieved':
        return isSC
            ? 'This order has been picked up. Please order from us again!'
            : 'This order has been delivered. Please order from us again!';
      default:
        return '';
    }
  }

  String _historyImagePath(String status, String orderType) {
    final isSC = orderType == 'selfcollect' || orderType == 'self_collect';
    switch (status) {
      case 'preparing':
        return 'assets/images/cooking_icon.png';
      case 'out_for_delivery':
        return 'assets/images/delivery_boy.png';
      case 'ready_for_collection':
        return isSC
            ? 'assets/images/collect_food_icon.png'
            : 'assets/images/collect_food_icon.png';
      case 'completed':
      case 'delivered':
      case 'retrieved':
        return isSC
            ? 'assets/images/collect_food_success_icon.png'
            : 'assets/images/collect_food_success_icon.png';
      default:
        return 'assets/images/order_submitted_tick_icon.png';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Self-Collect specific widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SelfCollectCodeCard extends StatelessWidget {
  final String? collectionCode;
  final OrderStatus status;

  static const _green = Color(0xFF1E4620);

  const _SelfCollectCodeCard({
    required this.collectionCode,
    required this.status,
  });

  String get _statusLabel {
    switch (status) {
      case OrderStatus.submitted:
        return 'Order Received! We will start preparing your Order soon.';
      case OrderStatus.preparing:
        return 'We are Preparing! Your Order will be ready soon.';
      case OrderStatus.readyOrOutForDelivery:
        return 'Order Ready! Waiting to be Collected.';
      case OrderStatus.completed:
        return 'Order Collected!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = collectionCode ?? '---';
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        children: [
          Container(
            width:  48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _green, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipOval(
              child: Image.asset(
                'assets/images/carry_food_icon.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shopping_bag_outlined,
                  color: _green,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Self Collection Code #$code',
                  style: const TextStyle(
                    color:      _green,
                    fontWeight: FontWeight.w800,
                    fontSize:   15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel,
                  style: const TextStyle(
                    color:    Color(0xFF6B6B6B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectAtCard extends StatelessWidget {
  final String  storeName;
  final String? storeAddress;

  const _CollectAtCard({
    required this.storeName,
    this.storeAddress,
  });

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
          const Text(
            'Collect At',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize:   14,
                color:      Color(0xFF2C2C2C)),
          ),
          const SizedBox(height: 6),
          Text(storeName,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF2C2C2C), fontWeight: FontWeight.w600)),
          if (storeAddress != null && storeAddress!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(storeAddress!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B6B6B), height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

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
                        fontSize: 12, color: Color(0xFF6B6B6B), height: 1.5)),
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
              : _StatusImage(path: statusImagePath),
        ],
      ),
    );
  }
}

class _StatusImage extends StatelessWidget {
  final String path;
  const _StatusImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width:  72,
      height: 72,
      fit:    BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width:  72,
        height: 72,
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          border: Border.all(color: const Color(0xFFD95F2B), width: 2),
        ),
        child: const Icon(Icons.shopping_basket_outlined,
            color: Color(0xFFD95F2B), size: 32),
      ),
    );
  }
}

// ── Status Tracker (FIX 3: Two-row layout — icon row + label row) ──────────────

class _StatusTracker extends StatelessWidget {
  final OrderStatus status;
  final OrderType   orderType;

  static const _green = Color(0xFF1E4620);

  const _StatusTracker({required this.status, required this.orderType});

  @override
  Widget build(BuildContext context) {
    final isSC = orderType == OrderType.selfCollect;

    final steps = [
      _Step(icon: Icons.receipt_outlined,     label: 'Order\nSubmitted'),
      _Step(icon: Icons.soup_kitchen_outlined, label: 'Preparing'),
      _Step(
        icon:  isSC ? Icons.storefront_outlined : Icons.directions_bike_outlined,
        label: isSC ? 'Ready For\nCollection' : 'Out For\nDelivery',
      ),
      _Step(
        icon:  isSC ? Icons.shopping_bag_outlined : Icons.home_outlined,
        label: 'Collected',
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
      child: Column(
        children: [
          // ── Row 1: Icons connected by lines ──────────────────────────
          Row(
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
              final stepIndex   = i ~/ 2;
              final isCompleted = stepIndex <= activeIndex;
              final step        = steps[stepIndex];

              return Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? _green : const Color(0xFFEEEBDE),
                ),
                child: Icon(step.icon,
                    size:  18,
                    color: isCompleted ? Colors.white : const Color(0xFFAAAAAA)),
              );
            }),
          ),
          const SizedBox(height: 8),
          // ── Row 2: Labels aligned under each icon ─────────────────────
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Spacer to match the connector lines
                return const Expanded(child: SizedBox());
              }
              final stepIndex   = i ~/ 2;
              final isCompleted = stepIndex <= activeIndex;
              final step        = steps[stepIndex];

              return SizedBox(
                width: 36,
                child: Text(
                  step.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   8,
                    fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w400,
                    color:      isCompleted ? _green : const Color(0xFFAAAAAA),
                    height:     1.3,
                  ),
                ),
              );
            }),
          ),
        ],
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
                  fontSize: 12, color: Color(0xFF6B6B6B), height: 1.5))),
        ],
      ),
    );
  }
}

// ── Live Item Details (FIX 1: includes qty, delivery type & fee) ───────────────

class _LiveItemDetailsSection extends StatelessWidget {
  final OrderController ctrl;
  final OrderModel      order;
  final VoidCallback    onCancelTap;

  static const _terracotta = Color(0xFFD95F2B);
  static const _green      = Color(0xFF1E4620);

  const _LiveItemDetailsSection({
    required this.ctrl,
    required this.order,
    required this.onCancelTap,
  });

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final isSelfCollect = order.orderType == OrderType.selfCollect;

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
                      border:       Border.all(color: _terracotta, width: 1.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ctrl.isCancelling
                        ? const SizedBox(
                      width:  14,
                      height: 14,
                      child:  CircularProgressIndicator(
                          strokeWidth: 1.5, color: _terracotta),
                    )
                        : const Text('CANCEL ORDER',
                        style: TextStyle(
                          color:         _terracotta,
                          fontSize:      11,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.5,
                        )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Items — live order uses OrderItemModel (no qty stored, qty=1 per row)
          ...order.items.map((item) => _OrderItemRow(
            name:     item.name,
            addOns:   item.addOns,
            price:    item.price,
            quantity: 1,
            imageUrl: null,
          )),
          const Divider(height: 20),
          // Fee breakdown
          _FeeRow(label: 'Subtotal', value: 'RM ${_fmt(order.subtotal)}'),
          const SizedBox(height: 4),
          _FeeRow(
              label: 'Service Fee (5%)',
              value: 'RM ${_fmt(order.serviceFee)}'),
          if (!isSelfCollect && order.deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _FeeRow(
                label: 'Delivery Fee',
                value: 'RM ${_fmt(order.deliveryFee)}'),
          ],
          // Delivery type label
          if (!isSelfCollect) ...[
            const SizedBox(height: 4),
            _FeeRow(
              label: 'Delivery Type',
              value: order.orderType == OrderType.delivery ? 'Delivery' : 'Self Collect',
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${order.items.length} item${order.items.length > 1 ? 's' : ''})',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize:   14,
                    color:      Color(0xFF2C2C2C)),
              ),
              Text(
                'RM ${_fmt(order.total)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize:   14,
                    color:      Color(0xFF2C2C2C)),
              ),
            ],
          ),
          if (order.remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Remark: ${order.remark}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── History Item Details (FIX 1: includes qty, delivery type & fee) ───────────

class _HistoryItemDetailsSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double       subtotal;
  final double       serviceFee;
  final double       deliveryFee;
  final double       total;
  final String       remark;
  final bool         isSelfCollect;
  final bool         isCancellable;
  final bool         isCancelling;
  final VoidCallback onCancelTap;

  static const _terracotta = Color(0xFFD95F2B);

  const _HistoryItemDetailsSection({
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.total,
    required this.remark,
    required this.isSelfCollect,
    required this.isCancellable,
    required this.isCancelling,
    required this.onCancelTap,
  });

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

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
                      border:       Border.all(color: _terracotta, width: 1.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCancelling
                        ? const SizedBox(
                      width:  14,
                      height: 14,
                      child:  CircularProgressIndicator(
                          strokeWidth: 1.5, color: _terracotta),
                    )
                        : const Text('CANCEL ORDER',
                        style: TextStyle(
                          color:         _terracotta,
                          fontSize:      11,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.5,
                        )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            return _OrderItemRow(
              name:     item['name']      as String? ?? '',
              addOns:   List<String>.from(item['add_ons'] as List? ?? []),
              price:    (item['price']    as num?)?.toDouble() ?? 0.0,
              quantity: qty,
              imageUrl: item['image_url'] as String?,
            );
          }),
          const Divider(height: 20),
          // Fee breakdown
          _FeeRow(label: 'Subtotal', value: 'RM ${_fmt(subtotal)}'),
          const SizedBox(height: 4),
          _FeeRow(
              label: 'Service Fee (5%)',
              value: 'RM ${_fmt(serviceFee)}'),
          if (!isSelfCollect && deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _FeeRow(
                label: 'Delivery Fee',
                value: 'RM ${_fmt(deliveryFee)}'),
          ],
          // Delivery type label
          const SizedBox(height: 4),
          _FeeRow(
            label: 'Order Type',
            value: isSelfCollect ? 'Self Collect' : 'Delivery',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${items.length} item${items.length > 1 ? 's' : ''})',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize:   14,
                    color:      Color(0xFF2C2C2C)),
              ),
              Text(
                'RM ${_fmt(total)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize:   14,
                    color:      Color(0xFF2C2C2C)),
              ),
            ],
          ),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Remark: $remark',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  const _FeeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF6B6B6B))),
      Text(value,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF2C2C2C))),
    ],
  );
}

// ── Shared item row (FIX 1: shows quantity) ────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final String       name;
  final List<String> addOns;
  final double       price;
  final int          quantity;
  final String?      imageUrl;

  const _OrderItemRow({
    required this.name,
    required this.addOns,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final half = (addOns.length / 2).ceil();
    final col1 = addOns.isNotEmpty ? addOns.sublist(0, half)            : <String>[];
    final col2 = addOns.length > 1  ? addOns.sublist(half)              : <String>[];
    final lineTotal = price * quantity;
    final priceStr = lineTotal % 1 == 0
        ? lineTotal.toInt().toString()
        : lineTotal.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodThumb(imageUrl: imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + qty badge
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    if (quantity > 1)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E4620).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'x$quantity',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E4620)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (addOns.isEmpty)
                  const Text(
                    '+ No Add Ons',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  )
                else
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
          const SizedBox(width: 8),
          Text(
            'RM $priceStr',
            style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF2C2C2C)),
          ),
        ],
      ),
    );
  }

  Widget _col(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map((a) => Text('+ $a',
        style: const TextStyle(fontSize: 10, color: Color(0xFF8A8A8A))))
        .toList(),
  );
}

class _FoodThumb extends StatelessWidget {
  final String? imageUrl;
  const _FoodThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback = Container(
      width:  64,
      height: 64,
      decoration: BoxDecoration(
        color:        const Color(0xFFD9D5C5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood_outlined,
          color: Color(0xFF9E9880), size: 28),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width:  64,
        height: 64,
        fit:    BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width:  64,
            height: 64,
            color:  const Color(0xFFEEEBDE),
            child: const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF1E4620)),
            ),
          );
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

// ── Order Info sections ────────────────────────────────────────────────────────

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
          _InfoRow(label: 'Order ID',       value: '#$orderId'),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
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