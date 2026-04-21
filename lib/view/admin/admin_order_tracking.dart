import 'package:flutter/material.dart';
import '../../service/supabase_conn.dart';
import '../../service/profile_service.dart';

// Status helpers

const _activeStatuses = {
  'submitted',
  'preparing',
  'out_for_delivery',
  'ready_for_collection',
};

const _historyStatuses = {'completed'};

Color _statusColor(String status) {
  switch (status) {
    case 'submitted':
      return const Color(0xFF1E4620);
    case 'preparing':
      return const Color(0xFFD95F2B);
    case 'out_for_delivery':
    case 'ready_for_collection':
      return const Color(0xFFB5CC30);
    case 'completed':
      return const Color(0xFF8A8A8A);
    case 'cancelled':
      return Colors.red;
    default:
      return const Color(0xFF8A8A8A);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'submitted':
      return 'Order Submitted';
    case 'preparing':
      return 'Preparing';
    case 'out_for_delivery':
      return 'Out for Delivery';
    case 'ready_for_collection':
      return 'Ready for Collection';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

String _orderTypeLabel(String orderType) {
  switch (orderType.toLowerCase()) {
    case 'selfcollect':
    case 'self_collect':
      return 'Self Collect';
    case 'delivery':
      return 'Delivery';
    default:
      return orderType;
  }
}

String _statusImage(String status) {
  switch (status) {
    case 'submitted':
      return 'assets/images/order_submitted_tick_icon.png';
    case 'preparing':
      return 'assets/images/cooking_icon.png';
    case 'ready_for_collection':
      return 'assets/images/collect_food_icon.png';
    case 'out_for_delivery':
      return 'assets/images/delivery_boy_icon.png';
    case 'completed':
      return 'assets/images/collect_food_success_icon.png';
    default:
      return '';
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

// Page

class AdminOrderTrackingPage extends StatefulWidget {
  const AdminOrderTrackingPage({super.key});

  @override
  State<AdminOrderTrackingPage> createState() => _AdminOrderTrackingPageState();
}

class _AdminOrderTrackingPageState extends State<AdminOrderTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  static const _green = Color(0xFF1E4620);

  String _searchQuery  = '';

  String? _filterStoreId;
  List<Map<String, dynamic>> _allStores = [];

  List<Map<String, dynamic>> _allOrders = [];
  Map<String, Map<String, dynamic>> _storeCache = {};
  Map<String, Map<String, dynamic>> _userCache  = {};
  bool    _loading = true;
  String? _error;

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

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .not('status', 'eq', 'cancelled')
          .order('created_at', ascending: false);

      final orders = List<Map<String, dynamic>>.from(rows);

      // Batch fetch stores
      final storeIds = orders
          .map((o) => o['store_id'])
          .where((id) => id != null)
          .map((id) => id.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet();

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
          debugPrint('[AdminOrders] store fetch error: $e');
        }
      }

      List<Map<String, dynamic>> allStores = [];
      try {
        final storeListRows = await supabase
            .from('stores')
            .select('id, name')
            .order('name', ascending: true);
        allStores = List<Map<String, dynamic>>.from(storeListRows);
      } catch (e) {
        debugPrint('[AdminOrders] all stores fetch error: $e');
      }

      // Batch fetch user names
      final userIds = orders
          .map((o) => o['user_id'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toSet();

      Map<String, Map<String, dynamic>> userCache = {};
      if (userIds.isNotEmpty) {
        try {
          final userRows = await supabase
              .from('user')
              .select('user_id, first_name, last_name, email, phone')
              .inFilter('user_id', userIds.toList());
          for (final row in List<Map<String, dynamic>>.from(userRows)) {
            final id = row['user_id']?.toString() ?? '';
            if (id.isNotEmpty) userCache[id] = row;
          }
        } catch (e) {
          debugPrint('[AdminOrders] user fetch error: $e');
        }
      }

      setState(() {
        _allOrders  = orders;
        _storeCache = storeCache;
        _userCache  = userCache;
        _allStores  = allStores;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<Map<String, dynamic>> _filter(Set<String> statusSet) {
    return _allOrders.where((o) {
      final status = (o['status'] as String? ?? '').toLowerCase().trim();
      if (!statusSet.contains(status)) return false;

      // Store filter
      if (_filterStoreId != null) {
        final rawId = o['store_id'];
        if (rawId == null || rawId.toString().trim() != _filterStoreId) {
          return false;
        }
      }

      if (_searchQuery.isEmpty) return true;

      final code       = (o['collection_code'] as String? ?? '').toLowerCase();
      final label      = _statusLabel(status).toLowerCase();
      final storeName  = _storeName(o).toLowerCase();
      final customerName = _customerName(o).toLowerCase();
      final orderType  = _orderTypeLabel(o['order_type'] as String? ?? '').toLowerCase();

      return code.contains(_searchQuery.toLowerCase()) ||
          label.contains(_searchQuery.toLowerCase()) ||
          storeName.contains(_searchQuery.toLowerCase()) ||
          customerName.contains(_searchQuery.toLowerCase()) ||
          orderType.contains(_searchQuery.toLowerCase());
    }).toList();
  }

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

  String _customerName(Map<String, dynamic> o) {
    final userId = o['user_id']?.toString() ?? '';
    if (userId.isNotEmpty && _userCache.containsKey(userId)) {
      final u     = _userCache[userId]!;
      final first = (u['first_name'] as String?)?.trim() ?? '';
      final last  = (u['last_name']  as String?)?.trim() ?? '';
      final full  = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (u['email'] as String?)?.trim() ?? 'Customer';
    }
    return (o['to_name'] as String?)?.trim() ?? 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders  = _filter(_activeStatuses);
    final historyOrders = _filter(_historyStatuses);

    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
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

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Filter
              const Text(
                'Filter by Store Branch',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF2C2C2C)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:        const Color(0xFFEEEBDE),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: const Color(0xFFDDDACA)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value:      _filterStoreId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF2C2C2C), size: 18),
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w500),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Stores'),
                      ),
                      ..._allStores.map((s) => DropdownMenuItem<String?>(
                        value: s['id'] as String?,
                        child: Text(
                          s['name'] as String? ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: (v) => setState(() => _filterStoreId = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Search
              const Text(
                'Search by Order Code, Status or Customer',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF2C2C2C)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g., 037, Preparing or John',
                  hintStyle:
                  const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                  suffixIcon:
                  const Icon(Icons.search, color: Color(0xFF8A8A8A)),
                  filled:    true,
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

        // Tab content
        Expanded(
          child: _loading
              ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E4620)))
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _fetchOrders)
              : TabBarView(
            controller: _tabCtrl,
            children: [
              _OrderList(
                orders:       activeOrders,
                isHistory:    false,
                storeName:    _storeName,
                customerName: _customerName,
                onTap:        _open,
              ),
              _OrderList(
                orders:       historyOrders,
                isHistory:    true,
                storeName:    _storeName,
                customerName: _customerName,
                onTap:        _open,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Map<String, dynamic> order) {
    final status   = (order['status'] as String? ?? '').toLowerCase();
    final isActive = _activeStatuses.contains(status);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isActive
            ? AdminActiveOrderDetailPage(
          orderId: order['order_id'].toString(),
          userId:  order['user_id'].toString(),
        )
            : AdminHistoryOrderDetailPage(
          orderId: order['order_id'].toString(),
          userId:  order['user_id'].toString(),
        ),
      ),
    ).then((_) => _fetchOrders());
  }
}

// Order List

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool isHistory;
  final String Function(Map<String, dynamic>) storeName;
  final String Function(Map<String, dynamic>) customerName;
  final Function(BuildContext, Map<String, dynamic>) onTap;

  const _OrderList({
    required this.orders,
    required this.isHistory,
    required this.storeName,
    required this.customerName,
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
              isHistory ? 'No completed orders yet.' : 'No active orders found.',
              style: const TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:     const Color(0xFF1E4620),
      onRefresh: () async {},
      child: ListView.separated(
        padding:          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount:        orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order     = orders[index];
          final status    = (order['status'] as String? ?? '').toLowerCase();
          final orderType = order['order_type'] as String? ?? '';
          final code      = order['collection_code'] as String? ?? '---';

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
                  _StatusImage(status: status, size: 36),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$code',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF2C2C2C)),
                        ),
                        Text(
                          _orderTypeLabel(orderType),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A8A8A)),
                        ),
                        Text(
                          customerName(order),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          storeName(order),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E4620),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: _statusColor(status)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order['order_date'] as String? ??
                            order['created_at'] as String?),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF8A8A8A), size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Status Image widget

class _StatusImage extends StatelessWidget {
  final String status;
  final double size;

  const _StatusImage({required this.status, required this.size});

  @override
  Widget build(BuildContext context) {
    final path = _statusImage(status);

    if (path.isEmpty || status == 'cancelled') {
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

// ACTIVE ORDER DETAIL PAGE

class AdminActiveOrderDetailPage extends StatefulWidget {
  final String orderId;
  final String userId;

  const AdminActiveOrderDetailPage({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  State<AdminActiveOrderDetailPage> createState() =>
      _AdminActiveOrderDetailPageState();
}

class _AdminActiveOrderDetailPageState
    extends State<AdminActiveOrderDetailPage> {
  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  Map<String, dynamic>? _order;
  Map<String, dynamic>? _storeRow;
  Map<String, dynamic>? _userRow;
  bool    _loading  = true;
  String? _error;
  String? _selectedStatus;
  bool    _updating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() { _loading = true; _error = null; });
    try {
      final row = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('order_id', int.parse(widget.orderId))
          .single();

      final orderMap = Map<String, dynamic>.from(row);

      final rawStoreId = orderMap['store_id'];
      Map<String, dynamic>? storeMap;
      if (rawStoreId != null && rawStoreId.toString().trim().isNotEmpty) {
        try {
          final s = await supabase
              .from('stores')
              .select('id, name, address')
              .eq('id', rawStoreId.toString().trim())
              .maybeSingle();
          if (s != null) storeMap = Map<String, dynamic>.from(s);
        } catch (e) {
          debugPrint('[AdminActiveDetail] store fetch error: $e');
        }
      }

      Map<String, dynamic>? userMap;
      try {
        final u = await supabase
            .from('user')
            .select('user_id, first_name, last_name, email, phone')
            .eq('user_id', widget.userId)
            .maybeSingle();
        if (u != null) userMap = Map<String, dynamic>.from(u);
      } catch (e) {
        debugPrint('[AdminActiveDetail] user fetch error: $e');
      }

      setState(() {
        _order    = orderMap;
        _storeRow = storeMap;
        _userRow  = userMap;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<String> get _statusOptions {
    final current = (_order?['status'] as String? ?? '').toLowerCase();
    switch (current) {
      case 'submitted':
        return ['preparing'];
      case 'preparing':
        final orderType = (_order?['order_type'] as String? ?? '').toLowerCase();
        return (orderType == 'selfcollect' || orderType == 'self_collect')
            ? ['ready_for_collection']
            : ['out_for_delivery'];
      case 'out_for_delivery':
      case 'ready_for_collection':
        return ['completed'];
      default:
        return [];
    }
  }

  String _statusOptionLabel(String s) {
    switch (s) {
      case 'preparing':            return 'Preparing';
      case 'out_for_delivery':     return 'Out for Delivery';
      case 'ready_for_collection': return 'Ready for Collection';
      case 'completed':            return 'Completed';
      default:                     return s;
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;
    setState(() => _updating = true);
    try {
      await supabase.from('orders').update({
        'status':        _selectedStatus,
        'is_cancellable': false, // Once admin moves status, no more user cancellation
      }).eq('order_id', int.parse(widget.orderId));

      if (_selectedStatus == 'completed' && _order != null) {
        final cal  = (_order!['total_cal']  as num?)?.toDouble() ?? 0;
        final pro  = (_order!['total_pro']  as num?)?.toDouble() ?? 0;
        final carb = (_order!['total_carb'] as num?)?.toDouble() ?? 0;
        final fat  = (_order!['total_fat']  as num?)?.toDouble() ?? 0;

        if (cal > 0) {
          await ProfileService.upsertCalorieLogForUser(
            userId:   widget.userId,
            calories: cal,
            proteinG: pro,
            carbsG:   carb,
            fatG:     fat,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Status updated to "${_statusOptionLabel(_selectedStatus!)}"'),
          backgroundColor: _green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _customerDisplayName() {
    if (_userRow != null) {
      final first = (_userRow!['first_name'] as String?)?.trim() ?? '';
      final last  = (_userRow!['last_name']  as String?)?.trim() ?? '';
      final full  = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (_userRow!['email'] as String?)?.trim() ?? 'Customer';
    }
    return (_order?['to_name'] as String?)?.trim() ?? 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(context, 'Order Details'),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF1E4620))),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(context, 'Order Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCC9B8)),
              const SizedBox(height: 12),
              const Text('Failed to load order details.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadOrder,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order       = _order!;
    final status      = (order['status']     as String? ?? '').toLowerCase();
    final orderType   = (order['order_type'] as String? ?? '').toLowerCase();
    final items       = List<Map<String, dynamic>>.from(order['order_items'] as List? ?? []);
    final code        = order['collection_code'] as String? ?? '---';
    final subtotal    = (order['subtotal']    as num?)?.toDouble() ?? 0.0;
    final serviceFee  = (order['service_fee'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final total       = (order['total']       as num?)?.toDouble() ?? 0.0;
    final toName      = order['to_name']      as String? ?? '';
    final toPhone     = order['to_phone']     as String? ?? '';
    final toAddress   = order['to_address']   as String? ?? '';
    final remark      = order['remark']       as String? ?? '';
    final storeName   = (_storeRow?['name']   as String?)?.trim() ?? 'NuBurn';
    final storeAddress = (_storeRow?['address'] as String?)?.trim() ?? '';
    final isSelfCollect = orderType == 'selfcollect' || orderType == 'self_collect';

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(context, 'Order Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DetailCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_orderTypeLabel(orderType).toUpperCase()} CODE #$code',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(_customerDisplayName(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
                        const SizedBox(height: 8),
                        const Text('Current Status:',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
                        const SizedBox(height: 4),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: _statusColor(status)),
                        ),
                      ],
                    ),
                  ),
                  _StatusImage(status: status, size: 64),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_statusOptions.isNotEmpty)
              _DetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Update Order Status',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _statusOptions.map((s) {
                        final isSelected = _selectedStatus == s;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStatus = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:        isSelected ? _terracotta : Colors.white,
                              border:       Border.all(color: _terracotta, width: 1.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusOptionLabel(s),
                              style: TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      isSelected ? Colors.white : _terracotta,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 46,
                      child: ElevatedButton(
                        onPressed: (_selectedStatus == null || _updating) ? null : _updateStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:         _green,
                          foregroundColor:         Colors.white,
                          disabledBackgroundColor: _green.withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _updating
                            ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('UPDATE STATUS',
                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),
            if (_statusOptions.isNotEmpty) const SizedBox(height: 16),

            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSelfCollect ? 'Collect At' : 'Delivery Info',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (isSelfCollect) ...[
                    _InfoRow(label: 'Store', value: storeName),
                    if (storeAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoRow(label: 'Address', value: storeAddress),
                    ],
                  ] else ...[
                    _InfoRow(label: 'To', value: toName),
                    if (toPhone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoRow(label: 'Phone', value: toPhone),
                    ],
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Address', value: toAddress),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _ItemDetailsCard(
              items:        items,
              subtotal:     subtotal,
              serviceFee:   serviceFee,
              deliveryFee:  deliveryFee,
              total:        total,
              remark:       remark,
              isSelfCollect: isSelfCollect,
            ),
            const SizedBox(height: 16),

            _OrderInfoCard(
              orderId:        widget.orderId,
              orderDate:      order['order_date'] as String? ?? order['created_at'] as String?,
              orderType:      _orderTypeLabel(orderType),
              paymentMethod:  order['payment_method'] as String? ?? 'Credit / Debit Card',
              collectionCode: code,
            ),
          ],
        ),
      ),
    );
  }
}

// HISTORY ORDER DETAIL PAGE

class AdminHistoryOrderDetailPage extends StatefulWidget {
  final String orderId;
  final String userId;

  const AdminHistoryOrderDetailPage({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  State<AdminHistoryOrderDetailPage> createState() =>
      _AdminHistoryOrderDetailPageState();
}

class _AdminHistoryOrderDetailPageState
    extends State<AdminHistoryOrderDetailPage> {
  static const _green = Color(0xFF1E4620);
  static const _bg    = Color(0xFFF5F5F0);

  Map<String, dynamic>? _order;
  Map<String, dynamic>? _storeRow;
  Map<String, dynamic>? _userRow;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() { _loading = true; _error = null; });
    try {
      final row = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('order_id', int.parse(widget.orderId))
          .single();

      final orderMap = Map<String, dynamic>.from(row);

      final rawStoreId = orderMap['store_id'];
      Map<String, dynamic>? storeMap;
      if (rawStoreId != null && rawStoreId.toString().trim().isNotEmpty) {
        try {
          final s = await supabase
              .from('stores')
              .select('id, name, address')
              .eq('id', rawStoreId.toString().trim())
              .maybeSingle();
          if (s != null) storeMap = Map<String, dynamic>.from(s);
        } catch (e) {
          debugPrint('[AdminHistoryDetail] store fetch error: $e');
        }
      }

      Map<String, dynamic>? userMap;
      try {
        final u = await supabase
            .from('user')
            .select('user_id, first_name, last_name, email, phone')
            .eq('user_id', widget.userId)
            .maybeSingle();
        if (u != null) userMap = Map<String, dynamic>.from(u);
      } catch (e) {
        debugPrint('[AdminHistoryDetail] user fetch error: $e');
      }

      setState(() {
        _order    = orderMap;
        _storeRow = storeMap;
        _userRow  = userMap;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  String _customerDisplayName() {
    if (_userRow != null) {
      final first = (_userRow!['first_name'] as String?)?.trim() ?? '';
      final last  = (_userRow!['last_name']  as String?)?.trim() ?? '';
      final full  = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      return (_userRow!['email'] as String?)?.trim() ?? 'Customer';
    }
    return (_order?['to_name'] as String?)?.trim() ?? 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(context, 'Order History Detail'),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF1E4620))),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(context, 'Order History Detail'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCC9B8)),
              const SizedBox(height: 12),
              const Text('Failed to load order details.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadOrder,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order       = _order!;
    final status      = (order['status']     as String? ?? '').toLowerCase();
    final orderType   = (order['order_type'] as String? ?? '').toLowerCase();
    final items       = List<Map<String, dynamic>>.from(order['order_items'] as List? ?? []);
    final code        = order['collection_code'] as String? ?? '---';
    final subtotal    = (order['subtotal']    as num?)?.toDouble() ?? 0.0;
    final serviceFee  = (order['service_fee'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final total       = (order['total']       as num?)?.toDouble() ?? 0.0;
    final toName      = order['to_name']      as String? ?? '';
    final toPhone     = order['to_phone']     as String? ?? '';
    final toAddress   = order['to_address']   as String? ?? '';
    final remark      = order['remark']       as String? ?? '';
    final payMethod   = order['payment_method'] as String? ?? 'Credit / Debit Card';
    final storeName   = (_storeRow?['name']   as String?)?.trim() ?? 'NuBurn';
    final storeAddress = (_storeRow?['address'] as String?)?.trim() ?? '';
    final isSelfCollect = orderType == 'selfcollect' || orderType == 'self_collect';

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(context, 'Order History Detail'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DetailCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ${_statusLabel(status)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_customerDisplayName(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
                        const SizedBox(height: 8),
                        const Text(
                          'This order has been completed successfully.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusImage(status: status, size: 64),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSelfCollect ? 'Collected At' : 'Delivered To',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (isSelfCollect) ...[
                    _InfoRow(label: 'Store', value: storeName),
                    if (storeAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoRow(label: 'Address', value: storeAddress),
                    ],
                  ] else ...[
                    _InfoRow(label: 'To', value: toName),
                    if (toPhone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoRow(label: 'Phone', value: toPhone),
                    ],
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Address', value: toAddress),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _ItemDetailsCard(
              items:        items,
              subtotal:     subtotal,
              serviceFee:   serviceFee,
              deliveryFee:  deliveryFee,
              total:        total,
              remark:       remark,
              isSelfCollect: isSelfCollect,
            ),
            const SizedBox(height: 16),

            _OrderInfoCard(
              orderId:        widget.orderId,
              orderDate:      order['order_date'] as String? ?? order['created_at'] as String?,
              orderType:      _orderTypeLabel(orderType),
              paymentMethod:  payMethod,
              collectionCode: code,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Shared AppBar

AppBar _appBar(BuildContext context, String title) => AppBar(
  backgroundColor: const Color(0xFFF5F5F0),
  elevation:       0,
  centerTitle:     true,
  leading: IconButton(
    icon:      const Icon(Icons.arrow_back, color: Color(0xFF1E4620)),
    onPressed: () => Navigator.pop(context),
  ),
  title: Text(title,
      style: const TextStyle(
          color: Color(0xFF1E4620), fontWeight: FontWeight.w800, fontSize: 18)),
);

// Shared detail card

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

// Item Details Card

class _ItemDetailsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double total;
  final String remark;
  final bool   isSelfCollect;

  const _ItemDetailsCard({
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.total,
    required this.remark,
    required this.isSelfCollect,
  });

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Item Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final name     = item['name']      as String? ?? '';
            final price    = (item['price']    as num?)?.toDouble() ?? 0.0;
            final qty      = (item['quantity'] as num?)?.toInt() ?? 1;
            final addOns   = List<String>.from(item['add_ons'] as List? ?? []);
            final imageUrl = item['image_url'] as String?;
            final lineTotal = price * qty;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminFoodThumb(imageUrl: imageUrl),
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
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E4620).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'x$qty',
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
                          const Text('+ No Add Ons',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)))
                        else
                          ...addOns.map((a) => Text('+ $a',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)))),
                      ],
                    ),
                  ),
                  Text(
                    'RM ${_fmt(lineTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),
          // Fee breakdown
          _FeeRow(label: 'Subtotal',          value: 'RM ${_fmt(subtotal)}'),
          const SizedBox(height: 4),
          _FeeRow(label: 'Service Fee (5%)',   value: 'RM ${_fmt(serviceFee)}'),
          if (!isSelfCollect && deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _FeeRow(label: 'Delivery Fee', value: 'RM ${_fmt(deliveryFee)}'),
          ],
          // Delivery type
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
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                'RM ${_fmt(total)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Remark: $remark',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B))),
      Text(value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF2C2C2C))),
    ],
  );
}

// Order Info Card

class _OrderInfoCard extends StatelessWidget {
  final String  orderId;
  final String? orderDate;
  final String  orderType;
  final String  paymentMethod;
  final String  collectionCode;

  const _OrderInfoCard({
    required this.orderId,
    required this.orderDate,
    required this.orderType,
    required this.paymentMethod,
    required this.collectionCode,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Info',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          _InfoRow(label: 'Order ID',         value: '#$orderId'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Collection Code',  value: '#$collectionCode'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Order Date',        value: _formatDate(orderDate)),
          const SizedBox(height: 6),
          _InfoRow(label: 'Order Type',        value: orderType),
          const SizedBox(height: 6),
          _InfoRow(label: 'Payment',           value: paymentMethod),
        ],
      ),
    );
  }
}

// Info Row

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
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2C)),
        ),
      ),
    ],
  );
}

// Admin Food Thumbnail

class _AdminFoodThumb extends StatelessWidget {
  final String? imageUrl;
  const _AdminFoodThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback = Container(
      width:  60,
      height: 60,
      decoration: BoxDecoration(
        color:        const Color(0xFFD9D5C5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood_outlined, color: Color(0xFF9E9880), size: 26),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width:  60,
        height: 60,
        fit:    BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 60, height: 60, color: const Color(0xFFEEEBDE),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E4620)),
            ),
          );
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

// Error State

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
            const Icon(Icons.wifi_off_outlined, size: 48, color: Color(0xFFCCC9B8)),
            const SizedBox(height: 12),
            const Text('Failed to load orders.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C))),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4620),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
