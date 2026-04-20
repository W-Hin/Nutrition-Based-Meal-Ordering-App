import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller/onboarding_controller.dart';

class OnboardingPersonalPage extends StatefulWidget {
  const OnboardingPersonalPage({super.key});

  @override
  State<OnboardingPersonalPage> createState() => _OnboardingPersonalPageState();
}

class _OnboardingPersonalPageState extends State<OnboardingPersonalPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _heightCtrl = TextEditingController(text: '165');
  final _weightCtrl = TextEditingController(text: '60');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context, OnboardingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) ctrl.setDob(picked);
  }

  void _goToBmi(OnboardingController ctrl) {
    if (!_formKey.currentState!.validate()) return;
    ctrl.fullName = _nameCtrl.text.trim();
    ctrl.phone    = _phoneCtrl.text.trim();
    ctrl.calculateBmiAndCalories();
    Navigator.pushNamed(context, '/onboarding/bmi');
  }

  void _skipToHome(OnboardingController ctrl) async {
    ctrl.fullName = _nameCtrl.text.trim();
    ctrl.phone    = _phoneCtrl.text.trim();

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Congratulations !',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You finished the register process successfully!',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (proceed == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Health Onboarding',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Step Indicator ───────────────────────────────────────────
            StepIndicator(current: 1, total: 2),
            const SizedBox(height: 8),

            // ── Scrollable Form ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Full Name ────────────────────────────────────
                      _label('Full Name *'),
                      const SizedBox(height: 6),
                      _textField(
                        ctrl: _nameCtrl,
                        hint: 'Yang',
                        validator: (v) =>
                        v!.isEmpty ? 'Full name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Phone ────────────────────────────────────────
                      _label('Phone *'),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _dark.withOpacity(0.12)),
                            ),
                            child: const Text('+60',
                                style: TextStyle(fontSize: 14, color: _dark)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _textField(
                              ctrl: _phoneCtrl,
                              hint: '186632510',
                              type: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Phone number is required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),


                      // ── Address ──────────────────────────────────────
                      _label('Address *'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/onboarding/address'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _dark.withOpacity(0.12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ctrl.street.isEmpty
                                    ? 'Tap to set address'
                                    : ctrl.deliveryLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ctrl.street.isEmpty
                                      ? _dark.withOpacity(0.35)
                                      : _dark,
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: _dark.withOpacity(0.4), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── DOB & Gender ─────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date of Birth
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Date of Birth *'),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () =>
                                      _selectDob(context, ctrl),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                          color:
                                          _dark.withOpacity(0.12)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          ctrl.dob != null
                                              ? '${ctrl.dob!.day.toString().padLeft(2, '0')}-'
                                              '${ctrl.dob!.month.toString().padLeft(2, '0')}-'
                                              '${ctrl.dob!.year}'
                                              : 'DD-MM-YYYY',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: ctrl.dob != null
                                                ? _dark
                                                : _dark.withOpacity(0.35),
                                          ),
                                        ),
                                        Icon(Icons.calendar_month,
                                            color: _dark.withOpacity(0.4),
                                            size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Gender
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Gender *'),
                                const SizedBox(height: 10),
                                Row(
                                  children:
                                  ['Male', 'Female'].map((g) {
                                    final selected = ctrl.gender == g;
                                    return GestureDetector(
                                      onTap: () => ctrl.setGender(g),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            right: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              selected
                                                  ? Icons
                                                  .radio_button_checked
                                                  : Icons
                                                  .radio_button_unchecked,
                                              color: selected
                                                  ? _green
                                                  : _dark.withOpacity(0.4),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(g,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: _dark)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Height & Weight ──────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Height
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Height (cm) *'),
                                const SizedBox(height: 6),
                                _textField(
                                  ctrl: _heightCtrl,
                                  hint: 'e.g. 165',
                                  type: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final h = int.tryParse(v);
                                    if (h == null || h < 50 || h > 300) return '50–300 cm';
                                    return null;
                                  },
                                  onChanged: (v) {
                                    final h = double.tryParse(v);
                                    if (h != null) ctrl.heightCm = h;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Weight
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Weight (kg) *'),
                                const SizedBox(height: 6),
                                _textField(
                                  ctrl: _weightCtrl,
                                  hint: 'e.g. 60',
                                  type: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final w = double.tryParse(v);
                                    if (w == null || w < 10 || w > 500) return '10–500 kg';
                                    return null;
                                  },
                                  onChanged: (v) {
                                    final w = double.tryParse(v);
                                    if (w != null) ctrl.weightKg = w;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Calculate BMI button ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: ctrl.isSaving
                              ? null
                              : () => _goToBmi(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Calculate BMI & Calories',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Skip button ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _skipToHome(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA0C850),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Skip Calculation and Start',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        text: text.replaceAll(' *', ''),
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _dark),
        children: text.contains('*')
            ? const [
          TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red))
        ]
            : [],
      ),
    );
  }

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    IconData? icon,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: _dark.withOpacity(0.35), fontSize: 14),
        prefixIcon: icon != null
            ? Icon(icon, color: _dark.withOpacity(0.4), size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _dark.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _dark.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _orange, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

}

// ── Step Indicator ─────────────────────────────────────────────────────────
class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepIndicator({super.key, required this.current, required this.total});

  static const _green = Color(0xFF1E4620);
  static const _dark  = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircle(1, current >= 1),
        _buildLine(current >= 2),
        _buildCircle(2, current >= 2),
      ],
    );
  }

  Widget _buildCircle(int num, bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? _green : const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$num',
          style: TextStyle(
            color: active ? Colors.white : _dark.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      width: 32,
      height: 2,
      color: active ? _green : const Color(0xFFE0E0E0),
    );
  }
}