import 'package:flutter/material.dart';
import '../../../service/address_service.dart';
import '../../../service/supabase_conn.dart';

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _addresses = await _svc.fetchAddresses();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    await _svc.deleteAddress(id);
    await _load();
  }

  void _showAddDialog() {
    final streetCtrl  = TextEditingController();
    final cityCtrl    = TextEditingController();
    final stateCtrl   = TextEditingController();
    final postcodeCtrl = TextEditingController();
    final instrCtrl   = TextEditingController();
    String label = 'Home';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
                const SizedBox(height: 16),
                // Label chips
                Row(
                  children: ['Home', 'Work', 'Others'].map((l) {
                    final sel = label == l;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l),
                        selected: sel,
                        selectedColor: _orange,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(color: sel ? Colors.white : _dark, fontWeight: FontWeight.w600, fontSize: 12),
                        onSelected: (_) => setDs(() => label = l),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _dialogField(streetCtrl,   'Street Address'),
                const SizedBox(height: 10),
                _dialogField(cityCtrl,     'City'),
                const SizedBox(height: 10),
                _dialogField(stateCtrl,    'State'),
                const SizedBox(height: 10),
                _dialogField(postcodeCtrl, 'Postcode (5 digits)', type: TextInputType.number,
                    maxLength: 5),
                const SizedBox(height: 10),
                _dialogField(instrCtrl, 'Delivery Instruction (optional)'),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dark,
                      side: BorderSide(color: _dark.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      final uid = supabase.auth.currentUser?.id ?? '';
                      await supabase.from('addresses').insert({
                        'user_id':              uid,
                        'street':               streetCtrl.text.trim(),
                        'city':                 cityCtrl.text.trim(),
                        'state':                stateCtrl.text.trim(),
                        'postcode':             postcodeCtrl.text.trim(),
                        'delivery_instruction': instrCtrl.text.trim(),
                        'label':                label,
                        'is_default':           _addresses.isEmpty,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int? maxLength}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _dark.withValues(alpha: 0.35), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8F6F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _orange)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaults = _addresses.where((a) => a['is_default'] == true).toList();
    final others   = _addresses.where((a) => a['is_default'] != true).toList();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : RefreshIndicator(
              color: _green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (defaults.isNotEmpty) ...[
                    _sectionHeader('Default'),
                    ...defaults.map((a) => _addressTile(a)),
                    const SizedBox(height: 16),
                  ],
                  if (others.isNotEmpty) ...[
                    _sectionHeader('Others'),
                    ...others.map((a) => _addressTile(a)),
                  ],
                  if (_addresses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(Icons.location_off_outlined, size: 48, color: _dark.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('No addresses yet', style: TextStyle(color: _dark.withValues(alpha: 0.4), fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.45), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }

  Widget _addressTile(Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
              a['label'] == 'Work' ? Icons.work_outline : Icons.home_outlined,
              color: _green, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['label'] ?? 'Address',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: _dark)),
                const SizedBox(height: 2),
                Text(
                  [
                    a['street'], a['city'], a['state'], a['postcode']
                  ].where((v) => v != null && (v as String).isNotEmpty).join(', '),
                  style: TextStyle(fontSize: 12, color: _dark.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
            onPressed: () => _deleteAddress(a['id'].toString()),
          ),
        ],
      ),
    );
  }
}
