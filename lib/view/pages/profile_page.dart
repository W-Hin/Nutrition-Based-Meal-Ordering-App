import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../../controller/review_controller.dart';
import '../../model/profile_model.dart';
import '../../service/supabase_conn.dart';

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
      context.read<ProfileController>().loadProfile();
      context.read<ReviewController>().loadMyReviews();
    });
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _bmiColor(String? category) {
    switch (category) {
      case 'Underweight': return Colors.blue.shade400;
      case 'Normal':      return const Color(0xFF4CAF50);
      case 'Overweight':  return _orange;
      case 'Obese':       return Colors.red.shade600;
      default:            return Colors.grey;
    }
  }

  void _showEditDialog(BuildContext context, ProfileController ctrl) {
    final profile    = ctrl.profile;
    final nameCtrl   = TextEditingController(text: profile?.fullName ?? '');
    final phoneCtrl  = TextEditingController(text: profile?.phone ?? '');
    final heightCtrl = TextEditingController(text: profile?.heightCm?.toStringAsFixed(0) ?? '');
    final weightCtrl = TextEditingController(text: profile?.weightKg?.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
              const SizedBox(height: 16),
              _editField(nameCtrl,   'Full Name',  Icons.person_outline),
              const SizedBox(height: 12),
              _editField(phoneCtrl,  'Phone',      Icons.phone_outlined,      type: TextInputType.phone),
              const SizedBox(height: 12),
              _editField(heightCtrl, 'Height (cm)', Icons.height,             type: TextInputType.number),
              const SizedBox(height: 12),
              _editField(weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined, type: TextInputType.number),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dark,
                        side: BorderSide(color: _dark.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final uid       = supabase.auth.currentUser!.id;
                        final hCm       = double.tryParse(heightCtrl.text) ?? profile?.heightCm;
                        final wKg       = double.tryParse(weightCtrl.text) ?? profile?.weightKg;
                        final newBmi    = (hCm != null && wKg != null)
                            ? wKg / ((hCm / 100) * (hCm / 100))
                            : profile?.bmi;
                        final updated   = ProfileModel(
                          id:              profile?.id,
                          userId:          uid,
                          fullName:        nameCtrl.text.trim(),
                          phone:           phoneCtrl.text.trim(),
                          heightCm:        hCm,
                          weightKg:        wKg,
                          age:             profile?.age,
                          gender:          profile?.gender,
                          activityLevel:   profile?.activityLevel,
                          bmi:             newBmi,
                          dailyCalorieGoal: profile?.dailyCalorieGoal,
                          proteinGoalG:    profile?.proteinGoalG,
                          carbsGoalG:      profile?.carbsGoalG,
                          fatGoalG:        profile?.fatGoalG,
                        );
                        await ctrl.updateProfile(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller:   ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _dark.withValues(alpha: 0.4)),
        filled: true,
        fillColor: const Color(0xFFF8F6F2),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profCtrl   = context.watch<ProfileController>();
    final authCtrl   = context.watch<AuthController>();
    final reviewCtrl = context.watch<ReviewController>();
    final profile    = profCtrl.profile;
    final user       = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: _cream,
      body: profCtrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200,
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: _green,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar circle
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _orange,
                            child: Text(
                              _initials(profile?.fullName),
                              style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            profile?.fullName ?? user?.email ?? 'User',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(context, profCtrl),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Body Stats ───────────────────────────────────────────
                      if (profile != null) ...[
                        _sectionTitle('Body Stats'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _statTile('BMI', profile.bmi?.toStringAsFixed(1) ?? '--',
                                badge: profile.bmiCategory,
                                badgeColor: _bmiColor(profile.bmiCategory)),
                            const SizedBox(width: 12),
                            _statTile('Height', '${profile.heightCm?.toInt() ?? '--'} cm'),
                            const SizedBox(width: 12),
                            _statTile('Weight', '${profile.weightKg?.toInt() ?? '--'} kg'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Nutrition Goals ────────────────────────────────────
                        _sectionTitle('Daily Nutrition Goals'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            children: [
                              _goalRow(Icons.local_fire_department, 'Calories',
                                  '${profile.dailyCalorieGoal?.toStringAsFixed(0) ?? '--'} kcal', Colors.orangeAccent),
                              _goalRow(Icons.fitness_center, 'Protein',
                                  '${profile.proteinGoalG?.toStringAsFixed(0) ?? '--'} g', Colors.lightBlue.shade400),
                              _goalRow(Icons.grain,         'Carbs',
                                  '${profile.carbsGoalG?.toStringAsFixed(0) ?? '--'} g', Colors.amber.shade400),
                              _goalRow(Icons.opacity,       'Fat',
                                  '${profile.fatGoalG?.toStringAsFixed(0) ?? '--'} g', Colors.pink.shade300),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── My Reviews ──────────────────────────────────────────
                      _sectionTitle('My Reviews'),
                      const SizedBox(height: 10),
                      if (reviewCtrl.isLoading)
                        const Center(child: CircularProgressIndicator(color: _orange))
                      else if (reviewCtrl.myReviews.isEmpty)
                        _emptyReviews()
                      else
                        ...reviewCtrl.myReviews.take(3).map((r) => _reviewCard(r)),
                      if (reviewCtrl.myReviews.length > 3) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/my-reviews'),
                          child: const Text('View all reviews →', style: TextStyle(color: _green)),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── Logout ──────────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () async {
                            await authCtrl.logout();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFECEC),
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
      );

  Widget _statTile(String label, String value, {String? badge, Color? badgeColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor?.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: TextStyle(fontSize: 9, color: badgeColor, fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: _dark.withValues(alpha: 0.7))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        ],
      ),
    );
  }

  Widget _reviewCard(review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.storeName ?? 'Store', style: const TextStyle(fontWeight: FontWeight.w700, color: _dark, fontSize: 13)),
              const Spacer(),
              ...List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.comment, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.65))),
          if (review.adminReply != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings, color: _green, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(review.adminReply!, style: const TextStyle(fontSize: 11, color: _green))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyReviews() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, color: _dark.withValues(alpha: 0.25), size: 36),
            const SizedBox(height: 8),
            Text('No reviews yet', style: TextStyle(color: _dark.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
