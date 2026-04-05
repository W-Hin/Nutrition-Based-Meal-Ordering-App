import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/checkout_controller.dart';
import '../../model/address_model.dart';

class EditAddressPage extends StatefulWidget {
  final CheckoutController ctrl;
  const EditAddressPage({super.key, required this.ctrl});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  late TextEditingController _addressCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _customLabelCtrl;
  AddressLabel? _selectedLabel;

  static const _green = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    final addr = widget.ctrl.deliveryAddress; // ← was context.read<CheckoutController>()
    _addressCtrl     = TextEditingController(text: addr.address);
    _nameCtrl        = TextEditingController(text: addr.name);
    _phoneCtrl       = TextEditingController(text: addr.phone);
    _customLabelCtrl = TextEditingController(text: addr.customLabelName);
    _selectedLabel   = addr.label;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.ctrl.updateAddress(        // ← was context.read<CheckoutController>()
      AddressModel(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        label: _selectedLabel,
        customLabelName: _customLabelCtrl.text,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EDIT ADDRESS',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Map placeholder ──
            _MapPlaceholder(),
            const SizedBox(height: 16),

            // ── Current address ──
            Row(
              children: [
                const Icon(Icons.location_on, color: _green, size: 20),
                const SizedBox(width: 8),
                const Text('Current Set Address',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                widget.ctrl.deliveryAddress.address,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B6B6B)),
              ),
            ),
            const Divider(height: 28),

            // ── Form fields ──
            _FieldLabel('New Address'),
            _InputField(
              controller: _addressCtrl,
              hint: 'Address Details (e.g., Block/Unit Number, Landmarks)',
            ),
            const SizedBox(height: 14),

            _FieldLabel('Your Name'),
            _InputField(controller: _nameCtrl, hint: 'John Doe'),
            const SizedBox(height: 14),

            _FieldLabel('Contact Number'),
            _InputField(controller: _phoneCtrl, hint: '012-345 6789'),
            const Divider(height: 28),

            // ── Label Address As ──
            _FieldLabel('Label Address As'),
            const SizedBox(height: 10),
            Row(
              children: [
                _LabelChip(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  value: AddressLabel.home,
                  selected: _selectedLabel,
                  onTap: (v) => setState(() => _selectedLabel = v),
                ),
                const SizedBox(width: 10),
                _LabelChip(
                  icon: Icons.work_outline,
                  label: 'Home', // matches design text
                  value: AddressLabel.work,
                  selected: _selectedLabel,
                  onTap: (v) => setState(() => _selectedLabel = v),
                ),
                const SizedBox(width: 10),
                _LabelChip(
                  icon: Icons.add,
                  label: 'Others',
                  value: AddressLabel.others,
                  selected: _selectedLabel,
                  onTap: (v) => setState(() => _selectedLabel = v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _FieldLabel('Label Name'),
            _InputField(controller: _customLabelCtrl, hint: 'Custom Name'),
            const SizedBox(height: 28),

            // ── Update button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _terracotta,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'UPDATE ADDRESS',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Label Chip ─────────────────────────────────────────────────────────────────
// Terracotta border + white fill = unselected
// Terracotta fill + white text  = selected

class _LabelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AddressLabel value;
  final AddressLabel? selected;
  final ValueChanged<AddressLabel> onTap;

  static const _terracotta = Color(0xFFD95F2B);

  const _LabelChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _terracotta : Colors.white,
          border: Border.all(color: _terracotta, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : _terracotta),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _terracotta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable small widgets ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF2C2C2C))),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFEEEBDE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    decoration: BoxDecoration(
      color: const Color(0xFFD9D5C5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Center(
      child: Icon(Icons.map_outlined, size: 40, color: Color(0xFF9E9880)),
    ),
  );
}