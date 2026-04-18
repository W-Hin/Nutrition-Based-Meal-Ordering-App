import 'package:flutter/material.dart';

// ── Status helpers ─────────────────────────────────────────────────────────────

// Active statuses shown in Track Order tab
const _activeStatuses = ['Order Submitted', 'Preparing', 'Ready for Collection'];
// History statuses shown in Order History tab
const _historyStatuses = ['Completed', 'Cancelled'];

// Maps status → asset image path (same images as user order_details)
String _statusImage(String status) {
  switch (status) {
    case 'Order Submitted':      return 'assets/images/order_submitted_tick_icon.png';
    case 'Preparing':            return 'assets/images/cooking_icon.png';
    case 'Ready for Collection': return 'assets/images/collect_food_icon.png';
    case 'Completed':            return 'assets/images/collect_food_success_icon.png';
    case 'Delivered':            return 'assets/images/delivery_boy_icon.png';
    default:                     return '';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Order Submitted':      return const Color(0xFF1E4620);
    case 'Preparing':            return const Color(0xFFD95F2B);
    case 'Ready for Collection': return const Color(0xFFB5CC30);
    case 'Completed':            return const Color(0xFF8A8A8A);
    case 'Cancelled':            return Colors.red;
    default:                     return const Color(0xFF8A8A8A);
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _AdminOrder {
  final String code;
  final String status;
  final String orderType; // 'Delivery' or 'Self Collect'
  final List<_AdminOrderItem> items;
  final double subtotal;
  final double serviceFee;
  final String orderId;
  final DateTime orderDate;

  const _AdminOrder({
    required this.code,
    required this.status,
    required this.orderType,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.orderId,
    required this.orderDate,
  });

  double get total => subtotal + serviceFee;
  Color  get statusColor => _statusColor(status);
  bool   get isActive    => _activeStatuses.contains(status);
}

class _AdminOrderItem {
  final String name;
  final List<String> addOns;
  final double price;
  const _AdminOrderItem({required this.name, required this.addOns, required this.price});
}

// ── Placeholder data ───────────────────────────────────────────────────────────

final List<_AdminOrder> _mockOrders = [
  _AdminOrder(
    code: '037', status: 'Order Submitted', orderType: 'Self Collect',
    subtotal: 32.80, serviceFee: 1.64,
    orderId: 'ABCD1234EFGH5678', orderDate: DateTime(2026, 3, 2),
    items: [
      _AdminOrderItem(name: 'Caesar Salad with Chicken Bites', addOns: ['No Add Ons'], price: 32.80),
    ],
  ),
  _AdminOrder(
    code: '036', status: 'Order Submitted', orderType: 'Delivery',
    subtotal: 32.80, serviceFee: 1.64,
    orderId: 'IJKL9012MNOP3456', orderDate: DateTime(2026, 3, 2),
    items: [
      _AdminOrderItem(name: 'Custom Meal Bowl', addOns: ['Brown Rice', 'Cherry Tomatoes', 'Chicken Breast (150g)'], price: 32.80),
    ],
  ),
  _AdminOrder(
    code: '035', status: 'Ready for Collection', orderType: 'Self Collect',
    subtotal: 65.60, serviceFee: 3.28,
    orderId: 'QRST7890UVWX1234', orderDate: DateTime(2026, 3, 1),
    items: [
      _AdminOrderItem(name: 'Caesar Salad with Chicken Bites', addOns: ['No Add Ons'], price: 32.80),
      _AdminOrderItem(name: 'Custom Meal Bowl', addOns: ['Brown Rice', 'Onions'], price: 32.80),
    ],
  ),
  _AdminOrder(
    code: '034', status: 'Preparing', orderType: 'Delivery',
    subtotal: 32.80, serviceFee: 1.64,
    orderId: 'YZAB5678CDEF9012', orderDate: DateTime(2026, 3, 1),
    items: [
      _AdminOrderItem(name: 'Grilled Salmon Bowl', addOns: ['No Add Ons'], price: 32.80),
    ],
  ),
  _AdminOrder(
    code: '031', status: 'Completed', orderType: 'Self Collect',
    subtotal: 32.80, serviceFee: 1.64,
    orderId: 'GHIJ3456KLMN7890', orderDate: DateTime(2026, 1, 31),
    items: [
      _AdminOrderItem(name: 'Custom Meal Bowl', addOns: ['Brown Rice'], price: 32.80),
    ],
  ),
  _AdminOrder(
    code: '030', status: 'Completed', orderType: 'Delivery',
    subtotal: 65.60, serviceFee: 3.28,
    orderId: 'OPQR1234STUV5678', orderDate: DateTime(2025, 12, 21),
    items: [
      _AdminOrderItem(name: 'Caesar Salad with Chicken Bites', addOns: ['No Add Ons'], price: 32.80),
      _AdminOrderItem(name: 'Custom Meal Bowl', addOns: ['Brown Rice', 'Cherry Tomatoes'], price: 32.80),
    ],
  ),
  _AdminOrder(
    code: '029', status: 'Cancelled', orderType: 'Self Collect',
    subtotal: 32.80, serviceFee: 1.64,
    orderId: 'WXYZ9012ABCD3456', orderDate: DateTime(2025, 12, 15),
    items: [
      _AdminOrderItem(name: 'Avocado Veggie Wrap', addOns: ['No Add Ons'], price: 32.80),
    ],
  ),
];

// ── Page ───────────────────────────────────────────────────────────────────────

class AdminOrderTrackingPage extends StatefulWidget {
  const AdminOrderTrackingPage({super.key});

  @override
  State<AdminOrderTrackingPage> createState() => _AdminOrderTrackingPageState();
}

class _AdminOrderTrackingPageState extends State<AdminOrderTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _green = Color(0xFF1E4620);

  List<_AdminOrder> get _active => _mockOrders.where((o) {
    final matchStatus = _activeStatuses.contains(o.status);
    final matchSearch = _searchQuery.isEmpty ||
        o.code.contains(_searchQuery) ||
        o.status.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchStatus && matchSearch;
  }).toList();

  List<_AdminOrder> get _history => _mockOrders.where((o) {
    final matchStatus = _historyStatuses.contains(o.status);
    final matchSearch = _searchQuery.isEmpty ||
        o.code.contains(_searchQuery) ||
        o.status.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchStatus && matchSearch;
  }).toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller:           _tabCtrl,
            labelColor:           _green,
            unselectedLabelColor: const Color(0xFF8A8A8A),
            labelStyle:           const TextStyle(fontWeight: FontWeight.w700),
            indicatorColor:       _green,
            indicatorWeight:      2.5,
            tabs: const [
              Tab(text: 'Track Order'),
              Tab(text: 'Order History'),
            ],
          ),
        ),

        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search by Order Code or Status',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                    color:      Color(0xFF2C2C2C)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                onChanged:  (v) => setState(() => _searchQuery = v.trim()),
                style:      const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText:  'e.g., 037 or Preparing',
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                  suffixIcon: const Icon(Icons.search, color: Color(0xFF8A8A8A)),
                  filled:    true,
                  fillColor: const Color(0xFFEEEBDE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _OrderList(orders: _active,  isHistory: false, onTap: _open),
              _OrderList(orders: _history, isHistory: true,  onTap: _open),
            ],
          ),
        ),
      ],
    );

    // TODO: Replace _mockOrders with Supabase queries
    // ── Active orders (submitted, preparing, readyOrOut) ──
    // final data = await supabase
    //     .from('orders')
    //     .select('*, order_items(*)')
    //     .inFilter('status', ['submitted', 'preparing', 'readyOrOut'])
    //     .order('created_at', ascending: false);
    //
    // ── History orders (completed, cancelled) ──
    // final data = await supabase
    //     .from('orders')
    //     .select('*, order_items(*)')
    //     .inFilter('status', ['completed', 'cancelled'])
    //     .order('created_at', ascending: false);
  }

  void _open(BuildContext context, _AdminOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => order.isActive
            ? _AdminActiveOrderDetail(order: order)
            : _AdminHistoryOrderDetail(order: order),
      ),
    );
  }
}

// ── Order List ─────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<_AdminOrder> orders;
  final bool isHistory;
  final Function(BuildContext, _AdminOrder) onTap;

  const _OrderList({
    required this.orders,
    required this.isHistory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistory ? Icons.history : Icons.receipt_long_outlined,
              size:  48,
              color: const Color(0xFFCCC9B8),
            ),
            const SizedBox(height: 12),
            Text(
              isHistory ? 'No order history found.' : 'No active orders found.',
              style: const TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding:          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount:        orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return GestureDetector(
          onTap: () => onTap(context, order),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: const Color(0xFFEEEBDE)),
            ),
            child: Row(
              children: [
                // Status image thumbnail
                _StatusImage(status: order.status, size: 36),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${order.code}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize:   14,
                              color:      Color(0xFF2C2C2C))),
                      Text(order.orderType,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A8A8A))),
                    ],
                  ),
                ),

                Text(
                  order.status,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   12,
                      color:      order.statusColor),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF8A8A8A), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Status Image widget (uses real assets, falls back to icon) ─────────────────

class _StatusImage extends StatelessWidget {
  final String status;
  final double size;

  const _StatusImage({required this.status, required this.size});

  @override
  Widget build(BuildContext context) {
    final path = _statusImage(status);

    if (path.isEmpty || status == 'Cancelled') {
      return Icon(Icons.cancel_outlined, color: Colors.red, size: size);
    }

    return Image.asset(
      path,
      width:  size,
      height: size,
      fit:    BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.receipt_outlined,
        color: _statusColor(status),
        size:  size,
      ),
    );
  }
}

// ── Active Order Detail (admin can update status) ──────────────────────────────

class _AdminActiveOrderDetail extends StatefulWidget {
  final _AdminOrder order;
  const _AdminActiveOrderDetail({required this.order});

  @override
  State<_AdminActiveOrderDetail> createState() => _AdminActiveOrderDetailState();
}

class _AdminActiveOrderDetailState extends State<_AdminActiveOrderDetail> {
  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  String? _selectedStatus;

  // Next possible statuses based on current
  List<String> get _statusOptions {
    switch (widget.order.status) {
      case 'Order Submitted': return ['Preparing'];
      case 'Preparing':       return ['Ready for Collection', 'Delivered'];
      default:                return ['Completed'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation:       0,
        centerTitle:     true,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Details',
            style: TextStyle(
                color:      _green,
                fontWeight: FontWeight.w800,
                fontSize:   18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Code + current status ──
            _DetailCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.orderType.toUpperCase()} CODE #${order.code}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text('Current Status:',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF8A8A8A))),
                        const SizedBox(height: 4),
                        Text(order.status,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize:   14,
                                color:      order.statusColor)),
                      ],
                    ),
                  ),
                  _StatusImage(status: order.status, size: 64),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Update status ──
            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Order Status',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing:    8,
                    runSpacing: 8,
                    children: _statusOptions.map((status) {
                      final isSelected = _selectedStatus == status;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStatus = status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:        isSelected ? _terracotta : Colors.white,
                            border:       Border.all(color: _terracotta, width: 1.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _terracotta,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width:  double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _selectedStatus == null
                          ? null
                          : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Status updated to "$_selectedStatus"'),
                            backgroundColor: _green,
                          ),
                        );
                        Navigator.pop(context);
                        // TODO: await supabase.from('orders')
                        //     .update({'status': _selectedStatus})
                        //     .eq('id', order.orderId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:        _green,
                        foregroundColor:        Colors.white,
                        disabledBackgroundColor: _green.withValues(alpha: 0.4),
                        elevation:              0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('UPDATE STATUS',
                          style: TextStyle(
                              fontWeight:   FontWeight.w800,
                              letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _ItemDetailsCard(order: order),
            const SizedBox(height: 16),
            _OrderInfoCard(order: order),
          ],
        ),
      ),
    );
  }
}

// ── History Order Detail (read-only, no status update) ────────────────────────

class _AdminHistoryOrderDetail extends StatelessWidget {
  final _AdminOrder order;

  static const _green = Color(0xFF1E4620);
  static const _bg    = Color(0xFFF5F5F0);

  const _AdminHistoryOrderDetail({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation:       0,
        centerTitle:     true,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order History Detail',
            style: TextStyle(
                color:      _green,
                fontWeight: FontWeight.w800,
                fontSize:   18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status banner ──
            _DetailCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.status == 'Cancelled'
                              ? 'Order Cancelled'
                              : 'Order ${order.status}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.status == 'Cancelled'
                              ? 'This order was cancelled by the customer.'
                              : 'This order has been completed successfully.',
                          style: const TextStyle(
                              fontSize: 12,
                              color:    Color(0xFF6B6B6B),
                              height:   1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusImage(status: order.status, size: 64),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── No status update section for history ──
            _ItemDetailsCard(order: order),
            const SizedBox(height: 16),
            _OrderInfoCard(order: order),
          ],
        ),
      ),
    );

    // TODO: Fetch from Supabase
    // final data = await supabase
    //     .from('orders')
    //     .select('*, order_items(*)')
    //     .eq('id', orderId)
    //     .single();
  }
}

// ── Shared detail card widgets ─────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: const Color(0xFFEEEBDE)),
    ),
    child: child,
  );
}

class _ItemDetailsCard extends StatelessWidget {
  final _AdminOrder order;
  const _ItemDetailsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Item Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width:  60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:        const Color(0xFFD9D5C5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fastfood_outlined,
                      color: Color(0xFF9E9880), size: 26),
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
                      ...item.addOns.map((a) => Text('+ $a',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A8A8A)))),
                    ],
                  ),
                ),
                Text('RM ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          )),
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Service Fee (5%) included *',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 4),
                Text(
                  'Total ${order.items.length} item(s): RM ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final _AdminOrder order;
  const _OrderInfoCard({required this.order});

  String _fmt(DateTime d) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Info',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          _InfoRow(label: 'Order ID',   value: order.orderId),
          const SizedBox(height: 6),
          _InfoRow(label: 'Order Date', value: _fmt(order.orderDate)),
          const SizedBox(height: 6),
          _InfoRow(label: 'Order Type', value: order.orderType),
          const SizedBox(height: 6),
          _InfoRow(label: 'Payment',    value: 'Toyyibpay'),
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
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      Color(0xFF2C2C2C))),
      ),
    ],
  );
}