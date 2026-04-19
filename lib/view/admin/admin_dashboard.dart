import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
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
            children: const [
              _StatCard(
                icon:    Icons.receipt_long_outlined,
                label:   'Total Orders',
                value:   '128',
                color:   Color(0xFF1E4620),
              ),
              _StatCard(
                icon:    Icons.pending_outlined,
                label:   'In Progress',
                value:   '12',
                color:   Color(0xFFD95F2B),
              ),
              _StatCard(
                icon:    Icons.check_circle_outline,
                label:   'Completed',
                value:   '110',
                color:   Color(0xFFB5CC30),
              ),
              _StatCard(
                icon:    Icons.restaurant_menu,
                label:   'Menu Items',
                value:   '24',
                color:   Color(0xFF5C4A1E),
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
          ...List.generate(5, (i) => _RecentOrderTile(index: i)),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8A8A))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent Order Tile ──────────────────────────────────────────────────────────

class _RecentOrderTile extends StatelessWidget {
  final int index;

  static const _statuses = [
    'Order Submitted',
    'Preparing',
    'Ready for Collection',
    'Completed',
    'Preparing',
  ];

  static const _statusColors = [
    Color(0xFF1E4620),
    Color(0xFFD95F2B),
    Color(0xFFB5CC30),
    Color(0xFF8A8A8A),
    Color(0xFFD95F2B),
  ];

  const _RecentOrderTile({required this.index});

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
            '#0${37 - index}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Caesar Salad, Custom Bowl',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B6B6B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColors[index].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statuses[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _statusColors[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}