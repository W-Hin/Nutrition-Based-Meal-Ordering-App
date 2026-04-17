import 'package:flutter/material.dart';
import 'order_details.dart';

// ── Local data models (static placeholders — replace with Supabase later) ──────

enum _OrderType   { delivery, selfCollect }
enum _OrderStatus { submitted, preparing, readyOrOut, completed, cancelled }

class _Order {
  final String           id;
  final String           fromName;
  final String           fromAddress;
  final String           toName;
  final String           toPhone;
  final String           toAddress;
  final DateTime         date;
  final List<_OrderLine> items;
  final double           subtotal;
  final double           serviceFee;
  final _OrderType       type;
  final _OrderStatus     status;
  final String?          remarks;
  bool                   expanded;

  _Order({
    required this.id,
    required this.fromName,
    required this.fromAddress,
    required this.toName,
    required this.toPhone,
    required this.toAddress,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.type,
    required this.status,
    this.remarks,
    this.expanded = false,
  });

  double get total => subtotal + serviceFee;

  String get statusLabel {
    switch (status) {
      case _OrderStatus.submitted:  return 'Order Submitted';
      case _OrderStatus.preparing:  return 'Preparing';
      case _OrderStatus.readyOrOut:
        return type == _OrderType.delivery
            ? 'Out for Delivery'
            : 'Ready for Collection';
      case _OrderStatus.completed:
        return type == _OrderType.delivery ? 'Delivered' : 'Completed';
      case _OrderStatus.cancelled:  return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case _OrderStatus.submitted:  return const Color(0xFF1E4620);
      case _OrderStatus.preparing:  return const Color(0xFFD95F2B);
      case _OrderStatus.readyOrOut: return const Color(0xFFB5CC30);
      case _OrderStatus.completed:  return const Color(0xFF8A8A8A);
      case _OrderStatus.cancelled:  return Colors.red;
    }
  }

  bool get isActive =>
      status == _OrderStatus.submitted ||
          status == _OrderStatus.preparing ||
          status == _OrderStatus.readyOrOut;
}

class _OrderLine {
  final String       name;
  final List<String> addOns;
  final double       price;
  _OrderLine({required this.name, required this.addOns, required this.price});
}

// ── Placeholder data ───────────────────────────────────────────────────────────

final List<_Order> _mockOrders = [
  _Order(
    id:          '001',
    fromName:    'NuBurn - Tanjung Burma',
    fromAddress: '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    toName:      'Ali',
    toPhone:     '012-345 6789',
    toAddress:   'A-B-C, Jalan Roti Bakar 6, Taman 7, 11200 Bayan Fah...',
    date:        DateTime(2026, 3, 2),
    type:        _OrderType.delivery,
    status:      _OrderStatus.preparing,
    subtotal:    32.80,
    serviceFee:  1.64,
    items: [
      _OrderLine(name: 'Custom Meal Bowl', addOns: [
        'Brown Rice', 'Cherry Tomatoes',
        'Chicken Breast (150g)', 'Onions', 'Minced Beef (100g)',
      ], price: 32.80),
    ],
  ),
  _Order(
    id:          '002',
    fromName:    'NuBurn - Tanjung Burma',
    fromAddress: '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    toName:      'NuBurn - Tanjung Burma',
    toPhone:     '',
    toAddress:   '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    date:        DateTime(2026, 3, 2),
    type:        _OrderType.selfCollect,
    status:      _OrderStatus.readyOrOut,
    subtotal:    65.60,
    serviceFee:  3.28,
    items: [
      _OrderLine(name: 'Caesar Salad with Chicken Bites',
          addOns: ['No Add Ons'], price: 32.80),
      _OrderLine(name: 'Custom Meal Bowl', addOns: [
        'Brown Rice', 'Cherry Tomatoes',
        'Chicken Breast (150g)', 'Onions', 'Minced Beef (100g)',
      ], price: 32.80),
    ],
  ),
  _Order(
    id:          '003',
    fromName:    'NuBurn - Tanjung Burma',
    fromAddress: '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    toName:      'NuBurn - Tanjung Burma',
    toPhone:     '',
    toAddress:   '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    date:        DateTime(2026, 1, 31),
    type:        _OrderType.selfCollect,
    status:      _OrderStatus.completed,
    subtotal:    32.80,
    serviceFee:  1.64,
    remarks:     'Bit less sauce please',
    items: [
      _OrderLine(name: 'Custom Meal Bowl',
          addOns: ['Brown Rice', 'Onions'], price: 32.80),
    ],
  ),
  _Order(
    id:          '004',
    fromName:    'NuBurn - Tanjung Burma',
    fromAddress: '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    toName:      'NuBurn - Tanjung Burma',
    toPhone:     '',
    toAddress:   '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21',
    date:        DateTime(2025, 12, 21),
    type:        _OrderType.selfCollect,
    status:      _OrderStatus.cancelled,
    subtotal:    65.60,
    serviceFee:  3.28,
    items: [
      _OrderLine(name: 'Caesar Salad with Chicken Bites',
          addOns: ['No Add Ons'], price: 32.80),
      _OrderLine(name: 'Custom Meal Bowl', addOns: [
        'Brown Rice', 'Cherry Tomatoes',
        'Chicken Breast (150g)', 'Onions', 'Minced Beef (100g)',
      ], price: 32.80),
    ],
  ),
];

// ── Page ───────────────────────────────────────────────────────────────────────

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  // ── TODO: Replace with Supabase fetch ──
  // Future<void> _loadOrders() async {
  //   final data = await supabase
  //       .from('orders')
  //       .select('*, order_items(*)')
  //       .eq('user_id', supabase.auth.currentUser!.id)
  //       .order('created_at', ascending: false);
  //   setState(() => _orders = data.map((r) => _Order.fromSupabase(r)).toList());
  // }

  List<_Order> get _activeOrders => _mockOrders.where((o) {
    final matchesActive = o.isActive;
    final matchesSearch = _searchQuery.isEmpty ||
        o.statusLabel.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchesActive && matchesSearch;
  }).toList();

  List<_Order> get _historyOrders => _mockOrders.where((o) {
    final matchesHistory = !o.isActive;
    final matchesSearch  = _searchQuery.isEmpty ||
        o.statusLabel.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchesHistory && matchesSearch;
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

  // ── Convert local _Order to the map that OrderDetailsPage expects ──
  // Simple — just pass the fields. Like PHP passing $_SESSION row to next page.
  void _openOrderDetails(BuildContext context, _Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          // Pass everything the details page needs directly
          passedId:          order.id,
          passedFromName:    order.fromName,
          passedFromAddress: order.fromAddress,
          passedToName:      order.toName,
          passedToPhone:     order.toPhone,
          passedToAddress:   order.toAddress,
          passedDate:        order.date,
          passedSubtotal:    order.subtotal,
          passedServiceFee:  order.serviceFee,
          passedIsCancelled: order.status == _OrderStatus.cancelled,
          passedOrderType:   order.type == _OrderType.delivery
              ? 'delivery'
              : 'selfCollect',
          passedStatus:      order.status.name, // e.g. 'preparing'
          passedRemarks:     order.remarks,
          passedItems:       order.items
              .map((i) => {
            'name':   i.name,
            'price':  i.price,
            'addOns': i.addOns,
          })
              .toList(),
        ),
      ),
    );

    // ── TODO: When Supabase is ready ──
    // Just pass the orderId and let OrderDetailsPage fetch the full row:
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => OrderDetailsPage(passedId: order.id),
    // ));
    // Then inside OrderDetailsPage.build():
    // final row = await supabase
    //     .from('orders')
    //     .select('*, order_items(*)')
    //     .eq('id', passedId)
    //     .single();
  }

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
        title: const Text(
          'My Orders',
          style: TextStyle(
            color:      _green,
            fontWeight: FontWeight.w800,
            fontSize:   18,
          ),
        ),
        bottom: TabBar(
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
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  (v) => setState(() => _searchQuery = v.trim()),
              style:      const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:   'Search by status (e.g. Preparing, Cancelled...)',
                hintStyle:  const TextStyle(
                    color: Color(0xFFAAAAAA), fontSize: 12),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFF8A8A8A)),
                filled:    true,
                fillColor: const Color(0xFFEEEBDE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // ── Tab views ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Track Order tab
                _activeOrders.isEmpty
                    ? const _EmptyState(
                  icon:    Icons.receipt_long_outlined,
                  message: 'No active orders right now.',
                )
                    : ListView.builder(
                  padding:   const EdgeInsets.all(16),
                  itemCount: _activeOrders.length,
                  itemBuilder: (context, i) => _OrderCard(
                    order:    _activeOrders[i],
                    showRate: false,
                    onExpand: () => setState(() =>
                    _activeOrders[i].expanded =
                    !_activeOrders[i].expanded),
                    onTap: () =>
                        _openOrderDetails(context, _activeOrders[i]),
                  ),
                ),

                // Order History tab
                _historyOrders.isEmpty
                    ? const _EmptyState(
                  icon:    Icons.history,
                  message: 'No past orders yet.',
                )
                    : ListView.builder(
                  padding:   const EdgeInsets.all(16),
                  itemCount: _historyOrders.length,
                  itemBuilder: (context, i) => _OrderCard(
                    order:    _historyOrders[i],
                    showRate: _historyOrders[i].status ==
                        _OrderStatus.completed,
                    onExpand: () => setState(() =>
                    _historyOrders[i].expanded =
                    !_historyOrders[i].expanded),
                    onTap: () =>
                        _openOrderDetails(context, _historyOrders[i]),
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

// ── Order Card ─────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final _Order       order;
  final bool         showRate;
  final VoidCallback onExpand;
  final VoidCallback onTap;      // ← tap whole card = go to details

  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);

  const _OrderCard({
    required this.order,
    required this.showRate,
    required this.onExpand,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final first      = order.items.first;
    final hasMore    = order.items.length > 1;
    final extraCount = order.items.length - 1;

    return GestureDetector(
      onTap: onTap,    // ← tapping the card goes to order details
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: const Color(0xFFEEEBDE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: restaurant + date ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Row(
                    children: [
                      Text(order.fromName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize:   13,
                            color:      Color(0xFF2C2C2C),
                          )),
                      const Icon(Icons.chevron_right,
                          size: 16, color: Color(0xFF8A8A8A)),
                    ],
                  ),
                  const Spacer(),
                  Text(_formatDate(order.date),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                ],
              ),
            ),
            const Divider(height: 16, indent: 14, endIndent: 14),

            // ── First item always shown ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _ItemRow(item: first),
            ),

            // ── Expanded: remaining items ──
            if (order.expanded && hasMore)
              ...order.items.skip(1).map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _ItemRow(item: item),
              )),

            // ── Show more / show less bar ──
            if (hasMore)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEEBDE), width: 1),
                  ),
                ),
                child: GestureDetector(
                  onTap: onExpand,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          order.expanded
                              ? 'Show less'
                              : '+$extraCount more item${extraCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      Color(0xFF1E4620),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          order.expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size:  16,
                          color: const Color(0xFF1E4620),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            // ── Totals ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Service Fee (5%) included *',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF8A8A8A))),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total ${order.items.length} item(s): RM ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  if (order.remarks != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Remark: ${order.remarks}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A8A8A))),
                    ),
                  ],
                ],
              ),
            ),

            // ── Footer: type · status + rate button ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFFEEEBDE))),
              ),
              child: Row(
                children: [
                  Text(
                    order.type == _OrderType.delivery
                        ? 'Delivery'
                        : 'Self Collect',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                  const Text(' · ',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                  Text(
                    order.statusLabel,
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      color:      order.statusColor,
                    ),
                  ),
                  const Spacer(),
                  if (showRate)
                    GestureDetector(
                      onTap: () {
                        // TODO: open rating dialog
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: _terracotta, width: 1.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('RATE',
                            style: TextStyle(
                              color:      _terracotta,
                              fontSize:   11,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Row ───────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final _OrderLine item;
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
          Text('RM ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B6B6B))),
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

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCCC9B8)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: Color(0xFF8A8A8A), fontSize: 14)),
        ],
      ),
    );
  }
}