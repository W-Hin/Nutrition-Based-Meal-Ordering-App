import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/supabase_conn.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // ── Stats ──
  int _totalOrders   = 0;
  double _totalEarning = 0;
  int _menuItems     = 0;
  int _inProgress    = 0;

  // ── Recent orders ──
  List<Map<String, dynamic>> _recentOrders = [];

  bool _isLoading = true;

  // Real-time subscription
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  // ── Fetch all dashboard data ──────────────────────────────────────────────
  Future<void> _fetchDashboardData() async {
    try {
      await Future.wait([
        _fetchStats(),
        _fetchRecentOrders(),
      ]);
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStats() async {
    // 1. Total orders count (exclude cancelled)
    final ordersResp = await supabase
        .from('orders')
        .select('order_id, status, total')
        .neq('status', 'cancelled');

    final orders = List<Map<String, dynamic>>.from(ordersResp);
    _totalOrders = orders.length;

    // 2. Total earnings — sum of total from ALL orders except cancelled
    _totalEarning = orders.fold(
      0.0,
          (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble(),
    );

    // 3. In progress: preparing + readyOrOutForDelivery (neither cancelled nor completed)
    _inProgress = orders
        .where((o) =>
    o['status'] != 'cancelled' &&
        o['status'] != 'completed')
        .length;

    // 4. Menu items count
    final menuResp = await supabase
        .from('menu_items')
        .select('food_id')
        .eq('is_available', true);
    _menuItems = List.from(menuResp).length;
  }

  Future<void> _fetchRecentOrders() async {
    final resp = await supabase
        .from('orders')
        .select('order_id, status, order_type, created_at, order_items(name)')
        .neq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(5);

    _recentOrders = List<Map<String, dynamic>>.from(resp);
  }

  // ── Real-time subscription ────────────────────────────────────────────────
  void _subscribeToOrders() {
    _ordersChannel = supabase
        .channel('admin_dashboard_orders')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) async {
        // Refresh all stats + recent orders on any order change
        await Future.wait([
          _fetchStats(),
          _fetchRecentOrders(),
        ]);
        if (mounted) setState(() {});
      },
    )
        .subscribe();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  String _orderItemNames(Map<String, dynamic> order) {
    final items = order['order_items'] as List?;
    if (items == null || items.isEmpty) return 'No items';
    return items.map((i) => i['name'] as String? ?? '').join(', ');
  }

  String _statusLabel(String status, String orderType) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out For Delivery';
      case 'ready_for_collection':
        return 'Ready For Collection';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        // Handle snake_case to Title Case as fallback
        return status.split('_').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':             return const Color(0xFF1E4620);
      case 'preparing':             return const Color(0xFFD95F2B);
      case 'out_for_delivery':
      case 'ready_for_collection':  return const Color(0xFFB5CC30);
      case 'completed':             return const Color(0xFF8A8A8A);
      case 'cancelled':             return const Color(0xFFCC2B2B);
      default:                      return const Color(0xFF8A8A8A);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
            const Text(
              'Good morning, Admin 👋',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formattedDate(),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 20),

            // ── Stat cards ──
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon:  Icons.receipt_long_outlined,
                  label: 'Total Orders',
                  value: '$_totalOrders',
                  color: const Color(0xFF1E4620),
                ),
                _StatCard(
                  icon:  Icons.payments_outlined,
                  label: 'Total Earning',
                  value: 'RM ${_totalEarning.toStringAsFixed(2)}',
                  color: const Color(0xFFB5CC30),
                  smallValue: _totalEarning >= 1000,
                ),
                _StatCard(
                  icon:  Icons.restaurant_menu,
                  label: 'Menu Items',
                  value: '$_menuItems',
                  color: const Color(0xFF5C4A1E),
                ),
                _StatCard(
                  icon:  Icons.pending_outlined,
                  label: 'Order In Progress',
                  value: '$_inProgress',
                  color: const Color(0xFFD95F2B),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Recent orders ──
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),

            if (_recentOrders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No orders yet.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF8A8A8A)),
                  ),
                ),
              )
            else
              ..._recentOrders.map((order) {
                final orderId =
                    order['order_id']?.toString() ?? '—';
                final status =
                    order['status'] as String? ?? 'submitted';
                final orderType =
                    order['order_type'] as String? ?? 'delivery';
                final itemNames = _orderItemNames(order);
                return _RecentOrderTile(
                  orderId:     orderId,
                  itemNames:   itemNames,
                  statusLabel: _statusLabel(status, orderType),
                  statusColor: _statusColor(status),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool smallValue;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEBDE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: smallValue ? 16 : 22,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8A8A8A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent Order Tile ──────────────────────────────────────────────────────────

class _RecentOrderTile extends StatelessWidget {
  final String orderId;
  final String itemNames;
  final String statusLabel;
  final Color statusColor;

  const _RecentOrderTile({
    required this.orderId,
    required this.itemNames,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEBDE)),
      ),
      child: Row(
        children: [
          Text(
            '#$orderId',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              itemNames,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}