import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'admin_menu_management.dart';
import 'admin_order_tracking.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);

  final List<_DrawerItem> _drawerItems = [
    _DrawerItem(icon: Icons.dashboard_outlined,    label: 'Dashboard'),
    _DrawerItem(icon: Icons.restaurant_menu,        label: 'Menu Management'),
    _DrawerItem(icon: Icons.receipt_long_outlined,  label: 'Order Tracking'),
  ];

  final List<Widget> _pages = [
    const AdminDashboardPage(),
    const AdminMenuManagementPage(),
    const AdminOrderTrackingPage(),
  ];

  String get _currentTitle => _drawerItems[_selectedIndex].label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          _currentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        // Hamburger icon — Flutter adds this automatically when Drawer is present
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _AdminDrawer(
        items:         _drawerItems,
        selectedIndex: _selectedIndex,
        onSelect: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context); // close drawer
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}

// ── Drawer ─────────────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  final List<_DrawerItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _bg         = Color(0xFFF5F5F0);

  const _AdminDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _bg,
      child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            color: _green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'NuBurn Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Management Panel',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Nav items ──
          ...List.generate(items.length, (index) {
            final item       = items[index];
            final isSelected = index == selectedIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                onTap: () => onSelect(index),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tileColor: isSelected
                    ? _green.withOpacity(0.1)
                    : Colors.transparent,
                leading: Icon(
                  item.icon,
                  color: isSelected ? _green : const Color(0xFF6B6B6B),
                  size: 22,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? _green : const Color(0xFF2C2C2C),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                trailing: isSelected
                    ? Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    : null,
              ),
            );
          }),

          const Spacer(),

          // ── Footer ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tileColor: const Color(0xFFFFEEEE),
              leading: const Icon(Icons.logout, color: Colors.red, size: 20),
              title: const Text('Logout',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                // TODO: auth logout
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  const _DrawerItem({required this.icon, required this.label});
}