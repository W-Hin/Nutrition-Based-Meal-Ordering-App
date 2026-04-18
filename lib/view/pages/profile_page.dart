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
  static const _dark   = Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadProfile();
    });
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
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
              const Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
              const SizedBox(height: 12),
              Text(
                'Log out will remove your account to personalised NuBurn and you will miss your daily tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.65), height: 1.5),
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
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final profile  = profCtrl.profile;
    final user     = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: _cream,
      body: profCtrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD95B2B)))
          : CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 180,
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: _green,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFFD95B2B),
                            child: Text(
                              _initials(profile?.fullName),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            profile?.fullName ?? 'User',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ),
                    collapseMode: CollapseMode.pin,
                  ),
                ),

                // ── Menu Items ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
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
                      _menuItem(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        )),
                      ),
                      _menuItem(
                        icon: Icons.location_on_outlined,
                        label: 'Addresses',
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AddressesPage(),
                        )),
                      ),
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

                      const SizedBox(height: 8),
                      _divider(),
                      _menuItem(
                        icon: Icons.logout,
                        label: 'Log Out',
                        labelColor: Colors.red.shade600,
                        iconColor: Colors.red.shade600,
                        onTap: () => _confirmLogout(context),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton( // Admin button for testing (Evelyn)
        onPressed: () => Navigator.push( // Admin button for testing (Evelyn)
          context, // Admin button for testing (Evelyn)
          MaterialPageRoute(builder: (_) => const AdminShell()), // Admin button for testing (Evelyn)
        ), // Admin button for testing (Evelyn)
        backgroundColor: const Color(0xFFD95B2B), // Admin button for testing (Evelyn)
        child: const Icon(Icons.admin_panel_settings, color: Colors.white), // Admin button for testing (Evelyn)
      ), // Admin button for testing (Evelyn)
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? _dark.withValues(alpha: 0.6)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
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

  Widget _divider() => Container(height: 8, color: _cream);
}
