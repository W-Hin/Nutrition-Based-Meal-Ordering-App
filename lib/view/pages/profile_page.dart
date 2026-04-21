import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../../service/supabase_conn.dart';
import 'profile/my_account_page.dart';
import 'profile/change_password_page.dart';
import 'profile/addresses_page.dart';
import 'profile/more_page.dart';
import '../admin/admin_shell.dart'; // Admin button for testing (Evelyn)

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<ProfileController>();
      c.loadProfile();
      c.loadUserName();
    });
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark),
              ),
              const SizedBox(height: 12),
              Text(
                'Log out will remove your access to personalized tracking and saved data until you log back in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.6), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dark,
                        side: BorderSide(color: _dark.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthController>().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profCtrl = context.watch<ProfileController>();
    final user     = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: _cream,
      // App Bar
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark),
        ),
        actions: [
          // Exit / Logout icon
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _orange, size: 24),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: profCtrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _green,
                        child: Text(
                          _initials(profCtrl.fullDisplayName),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profCtrl.fullDisplayName.isEmpty
                                ? 'User'
                                : profCtrl.fullDisplayName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _dark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: _dark.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Main Menu Group
                _menuCard([
                  _menuItem(
                    icon: Icons.person_outline,
                    label: 'My Account',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<ProfileController>(),
                        child: const MyAccountPage(),
                      ),
                    )),
                  ),
                  _dividerLine(),
                  _menuItem(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    )),
                  ),
                  _dividerLine(),
                  _menuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Addresses',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AddressesPage(),
                    )),
                  ),
                  _dividerLine(),
                  _menuItem(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<AuthController>(),
                        child: const MorePage(),
                      ),
                    )),
                  ),
                ]),
                const SizedBox(height: 12),

                // Log Out
                _menuCard([
                  _menuItem(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    labelColor: Colors.red.shade600,
                    iconColor: Colors.red.shade600,
                    onTap: () => _confirmLogout(context),
                  ),
                ]),
              ],
            ),

      // Admin FAB for testing (Evelyn)
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminShell()),
        ),
        backgroundColor: _orange,
        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
      ),
    );
  }

  // Card wrapper
  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _dividerLine() => Divider(
        height: 1,
        indent: 56,
        color: _dark.withValues(alpha: 0.08),
      );

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? _dark.withValues(alpha: 0.55)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? _dark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: _dark.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
