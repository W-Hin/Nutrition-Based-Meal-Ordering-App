import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/onboarding_controller.dart';
import 'onboarding_personal_page.dart' show StepIndicator;

class OnboardingAddressPage extends StatefulWidget {
  const OnboardingAddressPage({super.key});

  @override
  State<OnboardingAddressPage> createState() => _OnboardingAddressPageState();
}

class _OnboardingAddressPageState extends State<OnboardingAddressPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final _formKey       = GlobalKey<FormState>();
  final _streetCtrl    = TextEditingController();
  final _cityCtrl      = TextEditingController();
  final _postcodeCtrl  = TextEditingController();
  final _instrCtrl     = TextEditingController();

  final List<String> _labels  = ['Home', 'Work', 'Others'];
  final List<String> _states  = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
    'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Pulau Pinang',
    'Putrajaya', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndFinish(OnboardingController ctrl) async {
    if (!_formKey.currentState!.validate()) return;

    ctrl.street              = _streetCtrl.text.trim();
    ctrl.city                = _cityCtrl.text.trim();
    ctrl.postcode            = _postcodeCtrl.text.trim();
    ctrl.deliveryInstruction = _instrCtrl.text.trim();

    final profileOk  = await ctrl.saveProfile();
    final addressOk  = await ctrl.saveAddress();

    if (!mounted) return;

    if (profileOk && addressOk) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            StepIndicator(current: 3, total: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Delivery Address',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Where should we deliver your healthy meals?',
                        style: TextStyle(fontSize: 13, color: _dark.withOpacity(0.55)),
                      ),
                      const SizedBox(height: 20),

                      // ── Default toggle ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _dark.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: _orange, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Set as default address',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dark),
                              ),
                            ),
                            Switch(
                              value: ctrl.isDefaultAddress,
                              activeColor: _orange,
                              onChanged: (v) => setState(() => ctrl.isDefaultAddress = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Delivery Label ─────────────────────────────────────
                      _label('Delivery Label'),
                      const SizedBox(height: 8),
                      Row(
                        children: _labels.map((l) {
                          final selected = ctrl.deliveryLabel == l;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(l),
                              selected: selected,
                              selectedColor: _orange,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : _dark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              onSelected: (_) => setState(() => ctrl.deliveryLabel = l),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // ── Delivery Instruction ───────────────────────────────
                      _label('Delivery Instruction (Optional)'),
                      const SizedBox(height: 6),
                      _textField(
                        ctrl: _instrCtrl,
                        hint: 'e.g. Leave at door, call upon arrival',
                        icon: Icons.notes_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // ── Street ────────────────────────────────────────────
                      _label('Street Address'),
                      const SizedBox(height: 6),
                      _textField(
                        ctrl: _streetCtrl,
                        hint: 'No. 12, Jalan Sutera Utama 7/5',
                        icon: Icons.location_on_outlined,
                        validator: (v) => v!.isEmpty ? 'Street address is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // ── City ──────────────────────────────────────────────
                      _label('City'),
                      const SizedBox(height: 6),
                      _textField(
                        ctrl: _cityCtrl,
                        hint: 'e.g. Subang Jaya',
                        icon: Icons.apartment_outlined,
                        validator: (v) => v!.isEmpty ? 'City is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // ── State & Postcode ──────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('State'),
                                const SizedBox(height: 6),
                                _dropdown(
                                  items: _states,
                                  value: ctrl.state,
                                  onChanged: (v) => setState(() => ctrl.state = v ?? ctrl.state),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Postcode'),
                                const SizedBox(height: 6),
                                _textField(
                                  ctrl: _postcodeCtrl,
                                  hint: '47500',
                                  icon: Icons.pin_outlined,
                                  type: TextInputType.number,
                                  validator: (v) {
                                    if (v!.isEmpty) return 'Required';
                                    if (v.length != 5) return '5 digits';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Set Address button ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: ctrl.isSaving ? null : () => _saveAndFinish(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: ctrl.isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text("Set Address & Start!", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('← Back', style: TextStyle(color: _green.withOpacity(0.7), fontWeight: FontWeight.w600)),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dark),
      );

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   ctrl,
      keyboardType: type,
      maxLines:     maxLines,
      validator:    validator,
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  TextStyle(color: _dark.withOpacity(0.35), fontSize: 14),
        prefixIcon: Icon(icon, color: _dark.withOpacity(0.4), size: 20),
        filled:     true,
        fillColor:  Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _dark.withOpacity(0.1))),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _dark.withOpacity(0.12))),
        focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
        errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

  Widget _dropdown({required List<String> items, required String value, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dark.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: _dark),
          icon: Icon(Icons.arrow_drop_down, color: _dark.withOpacity(0.4)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
