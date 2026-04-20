import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller/onboarding_controller.dart';

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
  final _customLabelCtrl = TextEditingController();

  final List<String> _labels  = ['Home', 'Work', 'Others'];
  final List<String> _states  = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
    'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Pulau Pinang',
    'Putrajaya', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields from controller so returning to this page remembers values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<OnboardingController>();
      _streetCtrl.text   = ctrl.street;
      _cityCtrl.text     = ctrl.city;
      _postcodeCtrl.text = ctrl.postcode;
      _instrCtrl.text    = ctrl.deliveryInstruction;
      // If a custom label was previously saved, restore it
      if (!['Home', 'Work', 'Others'].contains(ctrl.deliveryLabel)) {
        _customLabelCtrl.text = ctrl.deliveryLabel;
        // Set deliveryLabel to 'Others' in ctrl so the chip shows as selected
        ctrl.deliveryLabel = 'Others';
      }
    });
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _instrCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  void _setAddress(OnboardingController ctrl) {
    if (!_formKey.currentState!.validate()) return;

    // Resolve final label
    final label = (ctrl.deliveryLabel == 'Others' &&
            _customLabelCtrl.text.trim().isNotEmpty)
        ? _customLabelCtrl.text.trim()
        : ctrl.deliveryLabel;

    // Update controller and trigger notifyListeners so Personal page rebuilds
    ctrl.setAddress(
      street:              _streetCtrl.text.trim(),
      city:                _cityCtrl.text.trim(),
      postcode:            _postcodeCtrl.text.trim(),
      deliveryInstruction: _instrCtrl.text.trim(),
      label:               label,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ─────────────────────────────────────────────────
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
                      'Set Address',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
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
                        style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(height: 20),

                      // ── Default toggle ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _dark.withValues(alpha: 0.1)),
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
                      Wrap(
                        spacing: 8,
                        children: _labels.map((l) {
                          final selected = ctrl.deliveryLabel == l || (l == 'Others' && !_labels.sublist(0, 2).contains(ctrl.deliveryLabel));
                          return ChoiceChip(
                            label: Text(l),
                            selected: selected,
                            selectedColor: _orange,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : _dark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            onSelected: (_) => setState(() {
                              ctrl.deliveryLabel = l;
                              if (l != 'Others') _customLabelCtrl.clear();
                            }),
                          );
                        }).toList(),
                      ),
                      // Show custom label input when Others is selected
                      if (ctrl.deliveryLabel == 'Others') ...[
                        const SizedBox(height: 10),
                        _textField(
                          ctrl: _customLabelCtrl,
                          hint: 'e.g. Gym, Parent\'s House...',
                          icon: Icons.label_outline,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please enter a custom label'
                              : null,
                        ),
                      ],
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

                      // ── City ──────────────────────────────────────────────────
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
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(5),
                                  ],
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
                          onPressed: () => _setAddress(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Set Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   ctrl,
      keyboardType: type,
      maxLines:     maxLines,
      validator:    validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  TextStyle(color: _dark.withValues(alpha: 0.35), fontSize: 14),
        prefixIcon: Icon(icon, color: _dark.withValues(alpha: 0.4), size: 20),
        filled:     true,
        fillColor:  Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _dark.withValues(alpha: 0.1))),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
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
        border: Border.all(color: _dark.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: _dark),
          icon: Icon(Icons.arrow_drop_down, color: _dark.withValues(alpha: 0.4)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
