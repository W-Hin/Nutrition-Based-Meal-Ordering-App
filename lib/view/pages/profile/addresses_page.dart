import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../service/address_service.dart';
import '../../../service/supabase_conn.dart';

//  Addresses Page  (profile → My Addresses)
class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});
  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final _svc = AddressService();
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _addresses = await _svc.fetchAddresses(); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _setDefault(String id) async {
    final uid = supabase.auth.currentUser?.id ?? '';
    // Remove default from all, then set new default
    await supabase.from('addresses').update({'is_default': false}).eq('user_id', uid);
    await supabase.from('addresses').update({'is_default': true}).eq('address_id', id);
    await _load();
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await supabase.from('addresses').delete().eq('address_id', id);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _openAddSheet({Map<String, dynamic>? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(existing: existing, onSaved: _load),
    );
    // Always reload after sheet closes (whether saved or cancelled)
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = _addresses.where((a) => a['is_default'] == true).toList();
    final others   = _addresses.where((a) => a['is_default'] != true).toList();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream, elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Addresses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : RefreshIndicator(
              color: _orange, onRefresh: _load,
              child: _addresses.isEmpty
                  ? _emptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      children: [
                        if (defaults.isNotEmpty) ...[
                          _sectionHeader('Default Address'),
                          ..._buildCards(defaults),
                          const SizedBox(height: 12),
                        ],
                        if (others.isNotEmpty) ...[
                          _sectionHeader('Other Addresses'),
                          ..._buildCards(others),
                        ],
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        backgroundColor: _orange, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  List<Widget> _buildCards(List<Map<String, dynamic>> list) =>
      list.map((a) => _AddressCard(
        address: a,
        onSetDefault: () => _setDefault(a['address_id'].toString()),
        onEdit:       () => _openAddSheet(existing: a),
        onDelete:     () => _delete(a['address_id'].toString()),
      )).toList();

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: _dark.withValues(alpha: 0.4), letterSpacing: 0.8)),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.location_on_outlined, size: 40, color: _green),
        ),
        const SizedBox(height: 16),
        const Text('No addresses saved', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 6),
        Text('Tap the button below to add your first delivery address.',
          style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.45)), textAlign: TextAlign.center),
      ]),
    ),
  );
}

//  Address Card Widget
class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final VoidCallback onSetDefault, onEdit, onDelete;
  const _AddressCard({required this.address, required this.onSetDefault, required this.onEdit, required this.onDelete});

  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    final isDefault = address['is_default'] == true;
    final label     = address['label'] as String? ?? 'Address';
    final fullAddr  = [address['street'], address['city'], address['state'], address['postcode']]
        .where((v) => v != null && (v as String).isNotEmpty).join(', ');
    final instr     = address['delivery_instruction'] as String? ?? '';

    final iconData = label == 'Work' ? Icons.work_outline
                   : label == 'Home' ? Icons.home_outlined
                   : Icons.label_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDefault ? _orange.withValues(alpha: 0.4) : Colors.transparent, width: 1.5),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row: icon + label + default badge
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isDefault ? _orange.withValues(alpha: 0.12) : _green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: isDefault ? _orange : _green, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark))),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _orange)),
              ),
          ]),
        ),
        // Address text
        Padding(
          padding: const EdgeInsets.fromLTRB(64, 4, 16, 0),
          child: Text(fullAddr, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.6))),
        ),
        if (instr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 4, 16, 0),
            child: Row(children: [
              Icon(Icons.notes_outlined, size: 12, color: _dark.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Expanded(child: Text(instr, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45)))),
            ]),
          ),
        // Action buttons
        const Divider(height: 20, thickness: 0.5),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(children: [
            if (!isDefault)
              _actionBtn(icon: Icons.star_border_rounded, label: 'Set Default', color: _orange, onTap: onSetDefault),
            _actionBtn(icon: Icons.edit_outlined, label: 'Edit', color: _dark, onTap: onEdit),
            const Spacer(),
            _actionBtn(icon: Icons.delete_outline, label: 'Delete', color: Colors.red.shade400, onTap: onDelete),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) =>
    TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
    );
}

//  Add / Edit Address Bottom Sheet
class _AddressSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _AddressSheet({this.existing, required this.onSaved});
  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final _formKey      = GlobalKey<FormState>();
  final _streetCtrl   = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _instrCtrl    = TextEditingController();
  final _customLabelCtrl = TextEditingController();

  String _label         = 'Home';
  String _selectedState = 'Selangor';
  bool   _isDefault     = false;
  bool   _saving        = false;

  final List<String> _states = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka',
    'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Pulau Pinang',
    'Putrajaya', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    if (a != null) {
      _streetCtrl.text   = a['street'] ?? '';
      _cityCtrl.text     = a['city'] ?? '';
      _postcodeCtrl.text = a['postcode'] ?? '';
      _instrCtrl.text    = a['delivery_instruction'] ?? '';
      _isDefault         = a['is_default'] == true;
      _selectedState     = a['state'] ?? 'Selangor';
      final l = a['label'] as String? ?? 'Home';
      if (['Home', 'Work'].contains(l)) {
        _label = l;
      } else {
        _label = 'Others';
        _customLabelCtrl.text = l;
      }
    }
  }

  @override
  void dispose() {
    _streetCtrl.dispose(); _cityCtrl.dispose();
    _postcodeCtrl.dispose(); _instrCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid   = supabase.auth.currentUser?.id ?? '';
      final label = (_label == 'Others' && _customLabelCtrl.text.trim().isNotEmpty)
          ? _customLabelCtrl.text.trim() : _label;
      final data  = {
        'user_id':              uid,
        'street':               _streetCtrl.text.trim(),
        'city':                 _cityCtrl.text.trim(),
        'state':                _selectedState,
        'postcode':             _postcodeCtrl.text.trim(),
        'delivery_instruction': _instrCtrl.text.trim(),
        'label':                label,
        'is_default':           _isDefault,
      };
      if (_isDefault) {
        // Clear all others first
        await supabase.from('addresses').update({'is_default': false}).eq('user_id', uid);
      }
      if (_isEditing) {
        await supabase.from('addresses').update(data).eq('address_id', widget.existing!['address_id'].toString());
      } else {
        await supabase.from('addresses').insert(data);
      }
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle bar
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Text(_isEditing ? 'Edit Address' : 'New Address',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 22)),
            ]),
          ),
          const Divider(height: 1),

          // Form
          Expanded(child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(20), children: [
            Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Default toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDefault ? _orange.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isDefault ? _orange.withValues(alpha: 0.3) : Colors.grey.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.star_rounded, color: _isDefault ? _orange : Colors.grey.shade400, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Set as default address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Switch(value: _isDefault, activeColor: _orange, onChanged: (v) => setState(() => _isDefault = v)),
                ]),
              ),
              const SizedBox(height: 20),

              // Label
              _sectionLabel('Address Label'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['Home', 'Work', 'Others'].map((l) {
                final sel  = _label == l;
                final icon = l == 'Home' ? Icons.home_outlined
                           : l == 'Work' ? Icons.work_outline : Icons.label_outline;
                return GestureDetector(
                  onTap: () => setState(() { _label = l; if (l != 'Others') _customLabelCtrl.clear(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _orange : Colors.grey.shade300),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 13, color: sel ? Colors.white : _dark.withValues(alpha: 0.6)),
                      const SizedBox(width: 5),
                      Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _dark)),
                    ]),
                  ),
                );
              }).toList()),
              if (_label == 'Others') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customLabelCtrl,
                  decoration: _inputDeco(hint: "e.g. Gym, Parent's House...", icon: Icons.edit_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a custom label' : null,
                ),
              ],
              const SizedBox(height: 20),

              // Address fields
              _sectionLabel('Street Address'),
              const SizedBox(height: 6),
              TextFormField(controller: _streetCtrl, decoration: _inputDeco(hint: 'No. 12, Jalan Sutera 7/5', icon: Icons.location_on_outlined),
                validator: (v) => v!.trim().isEmpty ? 'Street address is required' : null),
              const SizedBox(height: 14),

              _sectionLabel('City'),
              const SizedBox(height: 6),
              TextFormField(controller: _cityCtrl, decoration: _inputDeco(hint: 'e.g. Subang Jaya', icon: Icons.apartment_outlined),
                validator: (v) => v!.trim().isEmpty ? 'City is required' : null),
              const SizedBox(height: 14),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('State'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200)),
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
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('Postcode'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _postcodeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                    decoration: _inputDeco(hint: '47500', icon: Icons.pin_outlined),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v.length != 5) return '5 digits';
                      return null;
                    },
                  ),
                ])),
              ]),
              const SizedBox(height: 14),

              _sectionLabel('Delivery Instruction (Optional)'),
              const SizedBox(height: 6),
              TextFormField(controller: _instrCtrl, maxLines: 2,
                decoration: _inputDeco(hint: 'e.g. Leave at door, call upon arrival', icon: Icons.notes_outlined)),
              const SizedBox(height: 28),

              // Save button
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(_isEditing ? 'Update Address' : 'Save Address',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            ])),
          ])),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _dark.withValues(alpha: 0.6)));

  InputDecoration _inputDeco({required String hint, required IconData icon}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: _dark.withValues(alpha: 0.35), fontSize: 13),
    prefixIcon: Icon(icon, color: _dark.withValues(alpha: 0.4), size: 18),
    filled: true, fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border:            OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange, width: 1.5)),
    errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}
