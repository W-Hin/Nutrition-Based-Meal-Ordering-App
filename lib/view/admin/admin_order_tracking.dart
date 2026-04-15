import 'package:flutter/material.dart';

class AdminOrderTrackingPage extends StatefulWidget {
  const AdminOrderTrackingPage({super.key});

  @override
  State<AdminOrderTrackingPage> createState() =>
      _AdminOrderTrackingPageState();
}

class _AdminOrderTrackingPageState extends State<AdminOrderTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _terracotta = Color(0xFFD95F2B);

  // Placeholder orders
  final List<_AdminOrder> _activeOrders = [
    _AdminOrder(code: '037', status: 'Order Submitted', statusColor: Color(0xFF1E4620)),
    _AdminOrder(code: '036', status: 'Order Submitted', statusColor: Color(0xFF1E4620)),
    _AdminOrder(code: '035', status: 'Ready for Collection', statusColor: Color(0xFFB5CC30)),
    _AdminOrder(code: '034', status: 'Preparing', statusColor: Color(0xFFD95F2B)),
    _AdminOrder(code: '033', status: 'Preparing', statusColor: Color(0xFFD95F2B)),
    _AdminOrder(code: '032', status: 'Ready for Collection', statusColor: Color(0xFFB5CC30)),
  ];

  final List<_AdminOrder> _historyOrders = [
    _AdminOrder(code: '031', status: 'Completed', statusColor: Color(0xFF8A8A8A)),
    _AdminOrder(code: '030', status: 'Completed', statusColor: Color(0xFF8A8A8A)),
    _AdminOrder(code: '029', status: 'Cancelled', statusColor: Colors.red),
    _AdminOrder(code: '028', status: 'Completed', statusColor: Color(0xFF8A8A8A)),
  ];

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

  List<_AdminOrder> get _filteredActive => _activeOrders
      .where((o) => o.code.contains(_searchQuery))
      .toList();

  List<_AdminOrder> get _filteredHistory => _historyOrders
      .where((o) => o.code.contains(_searchQuery))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: _green,
            unselectedLabelColor: const Color(0xFF8A8A8A),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            indicatorColor: _green,
            indicatorWeight: 2.5,
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
                'Search by Self Collection Code',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF2C2C2C)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g., 123',
                  hintStyle: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 13),
                  suffixIcon: const Icon(Icons.search,
                      color: Color(0xFF8A8A8A)),
                  filled: true,
                  fillColor: const Color(0xFFEEEBDE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
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
              _OrderList(
                orders:  _filteredActive,
                onTap:   (order) => _openOrderDetail(context, order),
              ),
              _OrderList(
                orders:  _filteredHistory,
                onTap:   (order) => _openOrderDetail(context, order),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openOrderDetail(BuildContext context, _AdminOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminOrderDetailPage(order: order),
      ),
    );
  }
}

// ── Order List ─────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<_AdminOrder> orders;
  final ValueChanged<_AdminOrder> onTap;

  const _OrderList({required this.orders, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders found.',
            style: TextStyle(color: Color(0xFF8A8A8A))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return GestureDetector(
          onTap: () => onTap(order),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEBDE)),
            ),
            child: Row(
              children: [
                Text('#${order.code}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF2C2C2C))),
                const Spacer(),
                Text(
                  order.status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: order.statusColor,
                  ),
                ),
                const SizedBox(width: 8),
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

// ── Admin Order Detail Page ────────────────────────────────────────────────────

class _AdminOrderDetailPage extends StatefulWidget {
  final _AdminOrder order;

  const _AdminOrderDetailPage({required this.order});

  @override
  State<_AdminOrderDetailPage> createState() =>
      _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<_AdminOrderDetailPage> {
  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _terracotta = Color(0xFFD95F2B);

  // Which status button is selected
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'Preparing',
    'Ready for Collection',
    'Collected',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
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
          children: [
            // ── Self collection code ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEBDE)),
              ),
              child: Column(
                children: [
                  Text(
                    'SELF COLLECTION CODE #${widget.order.code}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Status:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A8A8A))),
                            SizedBox(height: 4),
                            Text('Order Submitted',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF2C2C2C))),
                          ],
                        ),
                      ),
                      // Status icon placeholder
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _terracotta, width: 2),
                        ),
                        child: const Icon(
                            Icons.shopping_basket_outlined,
                            color: _terracotta,
                            size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Update status ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEBDE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Order Status',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),

                  // ── Status chips ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusOptions.map((status) {
                      final isSelected = _selectedStatus == status;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStatus = status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _terracotta
                                : Colors.white,
                            border: Border.all(
                                color: _terracotta, width: 1.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : _terracotta,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Update button ──
                  SizedBox(
                    width: double.infinity,
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        _green.withOpacity(0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('UPDATE STATUS',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Item details ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEBDE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Details',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  _AdminItemRow(
                    name:   'Caesar Salad with Chicken Bites',
                    addOns: ['+ No Add Ons'],
                    price:  32.80,
                  ),
                  const SizedBox(height: 10),
                  _AdminItemRow(
                    name:   'Custom Meal Bowl',
                    addOns: [
                      '+ Brown Rice', '+ Cherry Tomatoes',
                      '+ Chicken Breast (150g)', '+ Onions',
                      '+ Minced Beef (100g)',
                    ],
                    price: 32.80,
                  ),
                  const Divider(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text('Service Fee (5%) included *',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8A8A8A))),
                        SizedBox(height: 4),
                        Text('Total 2 item(s): RM 68.90',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Order info ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEBDE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Info',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Order ID',
                      value: 'XXXXXXXXXXXXXXX'),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Order Date', value: '2 Mar 2026'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'Payment Method',
                      value: 'Credit / Debit Card'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminItemRow extends StatelessWidget {
  final String name;
  final List<String> addOns;
  final double price;

  const _AdminItemRow({
    required this.name,
    required this.addOns,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D5C5),
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
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              ...addOns.map((a) => Text(a,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8A8A)))),
            ],
          ),
        ),
        Text('RM ${price.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ],
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
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C))),
      ],
    );
  }
}

class _AdminOrder {
  final String code;
  final String status;
  final Color statusColor;

  const _AdminOrder({
    required this.code,
    required this.status,
    required this.statusColor,
  });
}