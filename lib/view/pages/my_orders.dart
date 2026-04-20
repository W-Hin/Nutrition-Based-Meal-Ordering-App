import 'package:flutter/material.dart';
import '../../service/supabase_conn.dart';
import 'order_details.dart';

// ── Status helpers ─────────────────────────────────────────────────────────────

const _activeStatuses  = {'submitted', 'preparing', 'out_for_delivery', 'ready_for_collection'};
const _historyStatuses = {'completed', 'delivered', 'retrieved', 'cancelled'};

Color _statusColor(String status) {
  switch (status) {
    case 'submitted':            return const Color(0xFF1E4620);
    case 'preparing':            return const Color(0xFFD95F2B);
    case 'out_for_delivery':
    case 'ready_for_collection': return const Color(0xFFB5CC30);
    case 'completed':
    case 'delivered':
    case 'retrieved':            return const Color(0xFF8A8A8A);
    case 'cancelled':            return Colors.red;
    default:                     return const Color(0xFF8A8A8A);
  }
}

String _statusLabel(String status, String orderType) {
  switch (status) {
    case 'submitted':            return 'Order Submitted';
    case 'preparing':            return 'Preparing';
    case 'out_for_delivery':     return 'Out for Delivery';
    case 'ready_for_collection': return 'Ready for Collection';
    case 'completed':
    case 'delivered':
    case 'retrieved':
      return orderType == 'delivery' ? 'Delivered' : 'Completed';
    case 'cancelled':            return 'Cancelled';
    default:                     return status;
  }
}

String _formatDate(String? raw) {
  if (raw == null) return '';
  try {
    final d = DateTime.parse(raw).toLocal();
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  } catch (_) {
    return raw;
  }
}

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

  static const _green = Color(0xFF1E4620);
  static const _bg    = Color(0xFFF5F5F0);

  String _searchQuery = '';

  List<Map<String, dynamic>> _allOrders = [];
  // FIX 3: Cache of store_id → store row fetched from Supabase
  Map<String, Map<String, dynamic>> _storeCache = {};
  bool    _loading = true;
  String? _error;

  final Set<dynamic> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // FIX 3: Fetch orders then batch-fetch all unique store IDs
  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uid = supabase.auth.currentUser?.id
          ?? 'fc33ae36-657a-4055-b81e-f6fe3de23278';

      final rows = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final orders = List<Map<String, dynamic>>.from(rows);

      // Collect unique non-null store IDs
      final storeIds = orders
          .map((o) => o['store_id'])
          .where((id) => id != null)
          .map((id) => id.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      // Batch fetch stores
      Map<String, Map<String, dynamic>> storeCache = {};
      if (storeIds.isNotEmpty) {
        try {
          final storeRows = await supabase
              .from('stores')
              .select('id, name, address')
              .inFilter('id', storeIds.toList());

          for (final row in List<Map<String, dynamic>>.from(storeRows)) {
            final id = (row['id'] as String?)?.trim() ?? '';
            if (id.isNotEmpty) storeCache[id] = row;
          }
        } catch (e) {
          debugPrint('[MyOrders] store batch fetch error: $e');
        }
      }

      setState(() {
        _allOrders  = orders;
        _storeCache = storeCache;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<Map<String, dynamic>> _filter(Set<String> statusSet) {
    return _allOrders.where((o) {
      final status    = (o['status']     as String? ?? '').toLowerCase();
      final orderType = (o['order_type'] as String? ?? '');
      final label     = _statusLabel(status, orderType).toLowerCase();
      final storeName = _storeName(o).toLowerCase();
      return statusSet.contains(status) &&
          (_searchQuery.isEmpty ||
              label.contains(_searchQuery.toLowerCase()) ||
              storeName.contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  // FIX 3: Resolve store name from cache instead of hardcoded fallback
  String _storeName(Map<String, dynamic> o) {
    final rawId = o['store_id'];
    if (rawId != null) {
      final id = rawId.toString().trim();
      if (id.isNotEmpty && _storeCache.containsKey(id)) {
        return (_storeCache[id]!['name'] as String?)?.trim() ?? 'NuBurn';
      }
    }
    return 'NuBurn';
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders  = _filter(_activeStatuses);
    final historyOrders = _filter(_historyStatuses);

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
              fontSize:   18),
        ),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh, color: _green),
            tooltip:   'Refresh',
            onPressed: _fetchOrders,
          ),
        ],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  (v) => setState(() => _searchQuery = v.trim()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:   'Search by status or restaurant',
                hintStyle:  const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF8A8A8A)),
                filled:     true,
                fillColor:  const Color(0xFFEEEBDE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E4620)))
                : _error != null
                ? _ErrorState(message: _error!, onRetry: _fetchOrders)
                : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(
                  orders:    activeOrders,
                  emptyMsg:  _searchQuery.isEmpty
                      ? 'No active orders right now.'
                      : 'No active orders match your search.',
                  emptyIcon: Icons.receipt_long_outlined,
                  showRate:  false,
                ),
                _buildList(
                  orders:    historyOrders,
                  emptyMsg:  _searchQuery.isEmpty
                      ? 'No past orders yet.'
                      : 'No past orders match your search.',
                  emptyIcon: Icons.history,
                  showRate:  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<Map<String, dynamic>> orders,
    required String   emptyMsg,
    required IconData emptyIcon,
    required bool     showRate,
  }) {
    if (orders.isEmpty) {
      return _EmptyState(icon: emptyIcon, message: emptyMsg);
    }

    return RefreshIndicator(
      color:     const Color(0xFF1E4620),
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding:     const EdgeInsets.all(16),
        itemCount:   orders.length,
        itemBuilder: (context, i) {
          final order  = orders[i];
          final id     = order['order_id'];
          final status = (order['status'] as String? ?? '').toLowerCase();

          return _OrderCard(
            order:      order,
            storeName:  _storeName(order),   // FIX 3: pass resolved name
            isExpanded: _expandedIds.contains(id),
            showRate:   showRate &&
                (status == 'completed' ||
                    status == 'delivered' ||
                    status == 'retrieved'),
            onExpand: () => setState(() {
              _expandedIds.contains(id)
                  ? _expandedIds.remove(id)
                  : _expandedIds.add(id);
            }),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsPage(
                    historyOrderId: id.toString(),
                  ),
                ),
              ).then((_) => _fetchOrders());
            },
          );
        },
      ),
    );
  }
}

// ── Order Card ─────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String       storeName;   // FIX 3: accept resolved store name
  final bool         isExpanded;
  final bool         showRate;
  final VoidCallback onExpand;
  final VoidCallback onTap;

  static const _terracotta = Color(0xFFD95F2B);

  const _OrderCard({
    required this.order,
    required this.storeName,
    required this.isExpanded,
    required this.showRate,
    required this.onExpand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status    = (order['status']     as String? ?? '').toLowerCase();
    final orderType = (order['order_type'] as String? ?? '').toLowerCase();
    final items     = List<Map<String, dynamic>>.from(
        order['order_items'] as List? ?? []);
    final total     = (order['total'] as num?)?.toDouble() ?? 0.0;
    final dateStr   = _formatDate(
        order['order_date'] as String? ?? order['created_at'] as String?);

    final first      = items.isNotEmpty ? items.first : null;
    final extraCount = items.length - 1;
    final hasMore    = extraCount > 0;

    return GestureDetector(
      onTap: onTap,
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
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            storeName,  // FIX 3: use resolved name
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize:   13,
                              color:      Color(0xFF2C2C2C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: Color(0xFF8A8A8A)),
                      ],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                ],
              ),
            ),
            const Divider(height: 16, indent: 14, endIndent: 14),

            if (first != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _ItemRow(item: first),
              ),

            if (isExpanded && hasMore) ...[
              const Divider(height: 12, indent: 14, endIndent: 14),
              ...items.skip(1).map(
                    (item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _ItemRow(item: item),
                ),
              ),
            ],

            if (hasMore)
              GestureDetector(
                onTap:     onExpand,
                behavior:  HitTestBehavior.opaque,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0xFFEEEBDE), width: 1)),
                    borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isExpanded
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
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size:  16,
                        color: const Color(0xFF1E4620),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Service Fee (5%) included *',
                      style: TextStyle(fontSize: 10, color: Color(0xFF8A8A8A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total ${items.length} item(s): RM ${_fmt(total)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  if ((order['remark'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Remark: ${order['remark']}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8A8A8A)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEBDE))),
              ),
              child: Row(
                children: [
                  Text(
                    orderType == 'delivery' ? 'Delivery' : 'Self Collect',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                  const Text(' · ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
                  Text(
                    _statusLabel(status, orderType),
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      color:      _statusColor(status),
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
                        child: const Text(
                          'RATE',
                          style: TextStyle(
                            color:      _terracotta,
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── Item Row ───────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name     = item['name']      as String? ?? '';
    final price    = (item['price']    as num?)?.toDouble() ?? 0.0;
    final addOns   = List<String>.from(item['add_ons'] as List? ?? []);
    final imageUrl = item['image_url'] as String?;

    final half = (addOns.length / 2).ceil();
    final col1 = addOns.isNotEmpty ? addOns.sublist(0, half) : <String>[];
    final col2 = addOns.length > 1  ? addOns.sublist(half)   : <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodImage(imageUrl: imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                // FIX 1: Show "- No Add Ons" when list is empty
                if (addOns.isEmpty)
                  const Text(
                    '+ No Add Ons',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8A8A8A)),
                  )
                else
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
          Text(
            'RM ${price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }

  Widget _addOnCol(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map((a) => Text('+ $a',
        style: const TextStyle(fontSize: 10, color: Color(0xFF8A8A8A))))
        .toList(),
  );
}

// ── Food Image widget ──────────────────────────────────────────────────────────

class _FoodImage extends StatelessWidget {
  final String? imageUrl;
  const _FoodImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback = Container(
      width:  60,
      height: 60,
      decoration: BoxDecoration(
        color:        const Color(0xFFD9D5C5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood_outlined,
          color: Color(0xFF9E9880), size: 26),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width:  60,
        height: 60,
        fit:    BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width:  60,
            height: 60,
            decoration: BoxDecoration(
              color:        const Color(0xFFEEEBDE),
              borderRadius: BorderRadius.circular(8),
            ),
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
              style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 48, color: Color(0xFFCCC9B8)),
            const SizedBox(height: 12),
            const Text('Failed to load orders.',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C))),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8A8A8A))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4620),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}