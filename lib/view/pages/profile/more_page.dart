import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/auth_controller.dart';
import '../../../service/supabase_conn.dart';
import '../terms_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _dark   = Color(0xFF2D2D2D);
  static const _orange = Color(0xFFD95B2B);

  Future<void> _confirmDelete(BuildContext context) async {
    final name = supabase.auth.currentUser?.email?.split('@').first ?? 'User';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete account?\nPermanently remove your data and close your NuBurn account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.6), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dark,
                    side: BorderSide(color: _dark.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Delete user data from tables, then delete auth user
        final uid = supabase.auth.currentUser?.id;
        if (uid != null) {
          await supabase.from('profiles').delete().eq('user_id', uid);
          await supabase.from('addresses').delete().eq('user_id', uid);
          await supabase.from('calorie_logs').delete().eq('user_id', uid);
          await supabase.from('reviews').delete().eq('user_id', uid);
          await supabase.from('user').delete().eq('user_id', uid);
        }
        await context.read<AuthController>().logout();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to delete account. Please contact support.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _menuItem(
            context,
            icon: Icons.article_outlined,
            label: 'Term & Condition',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())),
          ),
          _menuItem(
            context,
            icon: Icons.delete_outline,
            label: 'Delete Account',
            labelColor: Colors.red.shade600,
            iconColor: Colors.red.shade600,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, {
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: labelColor ?? _dark),
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
