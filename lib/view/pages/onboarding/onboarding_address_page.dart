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

  final _formKey         = GlobalKey<FormState>();
  final _streetCtrl      = TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _postcodeCtrl    = TextEditingController();
  final _instrCtrl       = TextEditingController();
  final _customLabelCtrl = TextEditingController();

  // Local state — avoids relying on ChangeNotifier for UI reactivity
  String _selectedLabel = 'Home';
  bool   _isDefault     = true;
  String _selectedState = 'Selangor';

  final List<String> _labels = ['Home', 'Work', 'Others'];
  final List<String> _states = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
    'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Pulau Pinang',
    'Putrajaya', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<OnboardingController>();
      _streetCtrl.text   = ctrl.street;
      _cityCtrl.text     = ctrl.city;
      _postcodeCtrl.text = ctrl.postcode;
      _instrCtrl.text    = ctrl.deliveryInstruction;
      _isDefault         = ctrl.isDefaultAddress;
      _selectedState     = ctrl.state;
      if (['Home', 'Work'].contains(ctrl.deliveryLabel)) {
        _selectedLabel = ctrl.deliveryLabel;
      } else if (ctrl.deliveryLabel.isNotEmpty) {
        _selectedLabel = 'Others';
        _customLabelCtrl.text = ctrl.deliveryLabel;
      }
      setState(() {});
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

  void _save(OnboardingController ctrl) {
    if (!_formKey.currentState!.validate()) return;
    final label = (_selectedLabel == 'Others' && _customLabelCtrl.text.trim().isNotEmpty)
        ? _customLabelCtrl.text.trim()
        : _selectedLabel;
    ctrl
      ..setAddress(
        street:              _streetCtrl.text.trim(),
        city:                _cityCtrl.text.trim(),
        postcode:            _postcodeCtrl.text.trim(),
        deliveryInstruction: _instrCtrl.text.trim(),
        label:               label,
      )
      ..isDefaultAddress = _isDefault
      ..state = _selectedState;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<OnboardingController>();
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    child: Text('Set Address',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _dark)),
                      const SizedBox(height: 4),
                      Text('Where should we deliver your healthy meals?',
                        style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.55))),
                      const SizedBox(height: 20),

                      // Default toggle
                      _card(Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: _orange.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.star_rounded, color: _orange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Set as Default', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                          Text('Used automatically at checkout', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ])),
                        Switch(value: _isDefault, activeColor: _orange, onChanged: (v) => setState(() => _isDefault = v)),
                      ])),
                      const SizedBox(height: 14),

                      // Label
                      _sectionTitle('Address Label'),
                      const SizedBox(height: 8),
                      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Wrap(spacing: 8, runSpacing: 8, children: _labels.map((l) {
                          final sel = _selectedLabel == l;
                          final icon = l == 'Home' ? Icons.home_outlined
                                     : l == 'Work' ? Icons.work_outline
                                     : Icons.label_outline;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedLabel = l;
                              if (l != 'Others') _customLabelCtrl.clear();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? _orange : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? _orange : Colors.grey.shade300),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(icon, size: 14, color: sel ? Colors.white : _dark.withValues(alpha: 0.6)),
                                const SizedBox(width: 6),
                                Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : _dark)),
                              ]),
                            ),
                          );
                        }).toList()),

                        // Custom label — shown IMMEDIATELY via setState
                        if (_selectedLabel == 'Others') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customLabelCtrl,
                            decoration: _inputDeco(hint: "e.g. Gym, Parent's House...", icon: Icons.edit_outlined),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a custom label' : null,
                          ),
                        ],
                      ])),
                      const SizedBox(height: 14),

                      // Address Details
                      _sectionTitle('Address Details'),
                      const SizedBox(height: 8),
                      _card(Column(children: [
                        _field(ctrl: _streetCtrl, label: 'Street Address',
                          hint: 'No. 12, Jalan Sutera Utama 7/5', icon: Icons.location_on_outlined,
                          validator: (v) => v!.trim().isEmpty ? 'Street address is required' : null),
                        const SizedBox(height: 12),
                        _field(ctrl: _cityCtrl, label: 'City', hint: 'e.g. Subang Jaya',
                          icon: Icons.apartment_outlined,
                          validator: (v) => v!.trim().isEmpty ? 'City is required' : null),
                        const SizedBox(height: 12),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _fieldLabel('State'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedState, isExpanded: true,
                                  style: const TextStyle(fontSize: 14, color: _dark),
                                  icon: Icon(Icons.arrow_drop_down, color: _dark.withValues(alpha: 0.4)),
                                  items: _states.map((e) => DropdownMenuItem(value: e,
                                    child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) => setState(() => _selectedState = v ?? _selectedState),
                                ),
                              ),
                            ),
                          ])),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _field(
                            ctrl: _postcodeCtrl, label: 'Postcode', hint: '47500',
                            icon: Icons.pin_outlined, type: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                            validator: (v) {
                              if (v!.isEmpty) return 'Required';
                              if (v.length != 5) return '5 digits';
                              return null;
                            },
                          )),
                        ]),
                      ])),
                      const SizedBox(height: 14),

                      // Delivery Instruction
                      _sectionTitle('Delivery Instruction (Optional)'),
                      const SizedBox(height: 8),
                      _card(TextFormField(
                        controller: _instrCtrl,
                        maxLines: 2,
                        decoration: _inputDeco(
                          hint: 'e.g. Leave at door, call upon arrival',
                          icon: Icons.notes_outlined,
                        ).copyWith(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                      )),
                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () => _save(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Save Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 28),
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

  // Helpers

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _sectionTitle(String t) => Text(t,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dark));

  Widget _fieldLabel(String t) => Text(t,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark.withValues(alpha: 0.6)));

  InputDecoration _inputDeco({required String hint, required IconData icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _dark.withValues(alpha: 0.35), fontSize: 13),
    prefixIcon: Icon(icon, color: _dark.withValues(alpha: 0.4), size: 18),
    filled: true, fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border:            OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange, width: 1.5)),
    errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: type,
        validator: validator, inputFormatters: inputFormatters,
        decoration: _inputDeco(hint: hint, icon: icon),
      ),
    ]);
  }
}
