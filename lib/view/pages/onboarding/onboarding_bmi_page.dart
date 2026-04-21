import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/onboarding_controller.dart';
import 'onboarding_personal_page.dart' show StepIndicator;

class OnboardingBmiPage extends StatelessWidget {
  const OnboardingBmiPage({super.key});

  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  Color _bmiColor(String category) {
    switch (category) {
      case 'Underweight': return Colors.blue.shade400;
      case 'Normal':      return const Color(0xFF4CAF50);
      case 'Overweight':  return _orange;
      case 'Obese':       return Colors.red.shade600;
      default:            return _dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();
    final bmi      = ctrl.bmi ?? 0;
    final category = ctrl.bmiCategory;
    final bmiColor = _bmiColor(category);

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Health Onboarding',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            StepIndicator(current: 2, total: 2),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const Text(
                      'Your Results',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your body metrics using BMR formula.',
                      style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 24),

                    // BMI Circle
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _dark.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // BMI gauge circle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150, height: 150,
                                child: CircularProgressIndicator(
                                  value: (bmi / 40).clamp(0, 1),
                                  strokeWidth: 14,
                                  backgroundColor: const Color(0xFFEEEEEE),
                                  valueColor: AlwaysStoppedAnimation(bmiColor),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bmi.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: bmiColor,
                                    ),
                                  ),
                                  const Text(
                                    'BMI',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: bmiColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: bmiColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    Row(
                      children: [
                        _statCard('Height', '${ctrl.heightCm.toInt()} cm', Icons.height),
                        const SizedBox(width: 12),
                        _statCard('Weight', '${ctrl.weightKg.toInt()} kg', Icons.monitor_weight_outlined),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      icon: Icons.straighten,
                      title: 'Healthy Weight Range',
                      value: ctrl.healthyWeightRange,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 12),

                    // Daily Calorie Goal
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'Daily Nutrition Goals',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _goalRow('Calories',  '${ctrl.dailyCalorieGoal?.toStringAsFixed(0) ?? '--'} kcal', Colors.orangeAccent),
                          _goalRow('Protein',   '${ctrl.proteinGoalG?.toStringAsFixed(0) ?? '--'} g',    Colors.lightBlueAccent),
                          _goalRow('Carbs',     '${ctrl.carbsGoalG?.toStringAsFixed(0) ?? '--'} g',      Colors.yellowAccent),
                          _goalRow('Fat',       '${ctrl.fatGoalG?.toStringAsFixed(0) ?? '--'} g',        Colors.pinkAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save & Start button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: ctrl.isSaving
                            ? null
                            : () async {
                                final profileOk = await ctrl.saveProfile();
                                final addressOk = ctrl.street.isEmpty
                                    ? true   // no address entered — skip
                                    : await ctrl.saveAddress();
                                if (!context.mounted) return;
                                if (profileOk && addressOk) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/home', (_) => false);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Something went wrong. Please try again.'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: ctrl.isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Save & Start!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: _green, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.5))),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
