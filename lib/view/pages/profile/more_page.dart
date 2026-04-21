import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/auth_controller.dart';
import '../../../controller/profile_controller.dart';
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
      // Cache refs before async gaps to avoid unsafe BuildContext use
      final authCtrl = context.read<AuthController>();
      final nav = Navigator.of(context);
      try {
        // Use Supabase RPC to securely delete the account from auth.users and all related data.
        await supabase.rpc('delete_user_account');

        await authCtrl.logout();
        if (context.mounted) {
          nav.pushNamedAndRemoveUntil('/auth', (_) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  Future<void> _generateDummyData(BuildContext context) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _green)),
    );

    try {
      // 1. Get a valid store ID
      final stores = await supabase.from('stores').select('id').limit(1);
      final storeId = stores.isNotEmpty ? stores.first['id'] : null;

      if (storeId == null) throw Exception("No stores found in database.");

      final now = DateTime.now();
      
      final dummyItems = [
        {'name': 'Grilled Chicken Salad', 'price': 18.5, 'cal': 450, 'pro': 40, 'fat': 15, 'carb': 20, 'icon': 'https://cjsxgpiahswppkyackpk.supabase.co/storage/v1/object/public/meal-images/meals/chicken_salad.png'},
        {'name': 'Salmon Quinoa Bowl', 'price': 24.0, 'cal': 520, 'pro': 35, 'fat': 22, 'carb': 45, 'icon': 'https://cjsxgpiahswppkyackpk.supabase.co/storage/v1/object/public/meal-images/meals/salmon_bowl.png'},
        {'name': 'Vegan Tofu Wrap', 'price': 15.0, 'cal': 380, 'pro': 20, 'fat': 12, 'carb': 50, 'icon': 'https://cjsxgpiahswppkyackpk.supabase.co/storage/v1/object/public/meal-images/meals/tofu_wrap.png'},
        {'name': 'Custom Bowl', 'price': 25.0, 'cal': 600, 'pro': 50, 'fat': 20, 'carb': 55, 'icon': 'https://cjsxgpiahswppkyackpk.supabase.co/storage/v1/object/public/meal-images/meals/customBowl.png'},
      ];

      for (int i = 0; i < 30; i++) {
        // Randomly skip some days so heatmap has gaps, but NEVER skip today (i=0)
        if (i != 0 && i % 6 == 0) continue;

        // Let's create an order for Lunch (1pm) and maybe Dinner (7pm)
        final lunchDate = DateTime(now.year, now.month, now.day - i, 13, 0);
        
        final dItem = dummyItems[(i * 3) % dummyItems.length];

        // Ensure order_date passes formatting properly
        final orderRes = await supabase.from('orders').insert({
          'user_id': uid,
          'store_id': storeId,
          'order_type': 'delivery',
          'status': 'completed',
          'to_name': 'Test User',
          'to_address': 'Test Address',
          'subtotal': dItem['price'],
          'service_fee': 2.0,
          'delivery_fee': 5.0,
          'total': (dItem['price'] as double) + 7.0,
          'total_cal': dItem['cal'],
          'total_pro': dItem['pro'],
          'total_carb': dItem['carb'],
          'total_fat': dItem['fat'],
          'payment_method': 'card',
          'order_date': lunchDate.toIso8601String(),
          'collection_code': 'DUMMY$i',
        }).select('order_id').single();

        final orderId = orderRes['order_id'];

        // Insert Order Item
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'name': dItem['name'],
          'price': dItem['price'],
          'image_url': dItem['icon'],
          'add_ons': dItem['name'] == 'Custom Bowl' ? ['Brown Rice x1', 'Chicken Breast x2', 'Lettuce x1', 'Sesame Sauce x1'] : [],
        });

        // Add to Calorie Log for that day
        final dateStr = lunchDate.toIso8601String().split('T').first;
        
        // Upsert calorie log manually since it is backdated
        final existing = await supabase
            .from('calorie_logs')
            .select('id, total_calories, total_protein_g, total_carbs_g, total_fat_g')
            .eq('user_id', uid)
            .eq('log_date', dateStr);

        if (existing.isNotEmpty) {
          final log = existing.first;
          await supabase.from('calorie_logs').update({
            'total_calories': (log['total_calories'] ?? 0) + dItem['cal'],
            'total_protein_g': (log['total_protein_g'] ?? 0) + dItem['pro'],
            'total_carbs_g': (log['total_carbs_g'] ?? 0) + dItem['carb'],
            'total_fat_g': (log['total_fat_g'] ?? 0) + dItem['fat'],
          }).eq('id', log['id']);
        } else {
          await supabase.from('calorie_logs').insert({
            'user_id': uid,
            'log_date': dateStr,
            'total_calories': dItem['cal'],
            'total_protein_g': dItem['pro'],
            'total_carbs_g': dItem['carb'],
            'total_fat_g': dItem['fat'],
          });
        }
      }

      if (context.mounted) {
        context.read<ProfileController>().loadDashboardData();
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('30 days of Dummy Data successfully generated! Check Dashboard.'),
            backgroundColor: _green));
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error generating dummy data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _clearDummyData(BuildContext context) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _green)),
    );

    try {
      final dummyOrders = await supabase
          .from('orders')
          .select('order_id')
          .eq('user_id', uid)
          .like('collection_code', 'DUMMY%');

      for (var order in dummyOrders) {
        await supabase.from('order_items').delete().eq('order_id', order['order_id']);
        await supabase.from('orders').delete().eq('order_id', order['order_id']);
      }

      // Wipe calorie_logs to reset dashboard completely
      await supabase.from('calorie_logs').delete().eq('user_id', uid);

      if (context.mounted) {
        context.read<ProfileController>().loadDashboardData();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dev Dummy Data cleared successfully. Dashboard reset.'),
            backgroundColor: _green));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error clearing dummy data: $e'), backgroundColor: Colors.red));
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
            icon: Icons.auto_awesome,
            label: 'Generate Dev Dummy Data',
            onTap: () => _generateDummyData(context),
            iconColor: _orange,
            labelColor: _orange,
          ),
          _menuItem(
            context,
            icon: Icons.cleaning_services_rounded,
            label: 'Clear Dev Dummy Data',
            onTap: () => _clearDummyData(context),
            iconColor: _orange,
            labelColor: _orange,
          ),
          _menuItem(
            context,
            icon: Icons.article_outlined,
            label: 'Term & Condition',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage(readOnly: true))),
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
