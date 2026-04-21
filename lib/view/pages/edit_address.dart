import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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

  final MapController _mapController = MapController();
  late LatLng _markerPos;
  bool _isGeocoding = false;

  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    final addr       = widget.ctrl.deliveryAddress;
    _addressCtrl     = TextEditingController(text: addr.address);
    _nameCtrl        = TextEditingController(text: addr.name);
    _phoneCtrl       = TextEditingController(text: addr.phone);
    _customLabelCtrl = TextEditingController(text: addr.customLabelName);
    _selectedLabel   = addr.label;

    _markerPos = LatLng(
      widget.ctrl.deliveryLat,
      widget.ctrl.deliveryLng,
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  // Reverse geocode: LatLng → address string via Nominatim
  Future<void> _reverseGeocode(LatLng pos) async {
    if (_isGeocoding) return;
    setState(() => _isGeocoding = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${pos.latitude}&lon=${pos.longitude}'
            '&format=json&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'NuBurnApp/1.0 (support@nuburn.app)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data        = json.decode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';

        final addr    = data['address'] as Map<String, dynamic>? ?? {};
        final road    = addr['road']          as String? ?? '';
        final suburb  = addr['suburb']        as String?
            ?? addr['neighbourhood']          as String? ?? '';
        final city    = addr['city']          as String?
            ?? addr['town']                   as String?
            ?? addr['village']                as String? ?? '';
        final state   = addr['state']         as String? ?? '';
        final postcode = addr['postcode']     as String? ?? '';

        final parts     = [road, suburb, city, state, postcode]
            .where((p) => p.isNotEmpty)
            .toList();
        final formatted = parts.isNotEmpty ? parts.join(', ') : displayName;

        if (mounted) {
          setState(() => _addressCtrl.text = formatted);
        }
      }
    } catch (_) {
      // Silently fail — user can still type manually
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _save() {
    widget.ctrl.updateAddress(
      AddressModel(
        name:            _nameCtrl.text,
        phone:           _phoneCtrl.text,
        address:         _addressCtrl.text,
        label:           _selectedLabel,
        customLabelName: _customLabelCtrl.text,
      ),
      lat: _markerPos.latitude,
      lng: _markerPos.longitude,
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
          icon:      const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EDIT ADDRESS',
          style: TextStyle(
            color:         Color(0xFF2C2C2C),
            fontWeight:    FontWeight.w800,
            letterSpacing: 1.4,
            fontSize:      18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInteractiveMap(),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.touch_app_outlined,
                    size: 14, color: Color(0xFF8A8A8A)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Tap anywhere on the map to pin your location — address will auto-fill below.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.location_on, color: _green, size: 20),
                const SizedBox(width: 8),
                const Text('Current Set Address',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                widget.ctrl.deliveryAddress.address,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
              ),
            ),
            const Divider(height: 28),

            _FieldLabel('New Address'),
            Stack(
              children: [
                _InputField(
                    controller: _addressCtrl, hint: 'Tap map above or type here'),
                if (_isGeocoding)
                  const Positioned(
                    right: 12,
                    top:   12,
                    child: SizedBox(
                      width:  18,
                      height: 18,
                      child:  CircularProgressIndicator(
                          strokeWidth: 2, color: _green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            _FieldLabel('Your Name'),
            _InputField(controller: _nameCtrl, hint: 'John Doe'),
            const SizedBox(height: 14),

            _FieldLabel('Contact Number'),
            _InputField(controller: _phoneCtrl, hint: '012-345 6789'),
            const Divider(height: 28),

            _FieldLabel('Label Address As'),
            const SizedBox(height: 10),
            Row(
              children: [
                _LabelChip(
                  icon:     Icons.home_outlined,
                  label:    'Home',
                  value:    AddressLabel.home,
                  selected: _selectedLabel,
                  onTap:    (v) => setState(() {
                    _selectedLabel = v;
                    if (v != AddressLabel.others) _customLabelCtrl.clear();
                  }),
                ),
                const SizedBox(width: 10),
                _LabelChip(
                  icon:     Icons.work_outline,
                  label:    'Work',
                  value:    AddressLabel.work,
                  selected: _selectedLabel,
                  onTap:    (v) => setState(() {
                    _selectedLabel = v;
                    if (v != AddressLabel.others) _customLabelCtrl.clear();
                  }),
                ),
                const SizedBox(width: 10),
                _LabelChip(
                  icon:     Icons.add,
                  label:    'Others',
                  value:    AddressLabel.others,
                  selected: _selectedLabel,
                  onTap:    (v) => setState(() => _selectedLabel = v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_selectedLabel == AddressLabel.others) ...[
              _FieldLabel('Label Name'),
              _InputField(
                  controller: _customLabelCtrl,
                  hint: 'e.g. Gym, Parents\' Home'),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 14),

            SizedBox(
              width:  double.infinity,
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
                      fontSize:   15,
                      letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Interactive flutter_map
  Widget _buildInteractiveMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _markerPos,
                initialZoom:   15.0,

                onTap: (tapPos, latLng) {
                  setState(() => _markerPos = latLng);
                  // Move the map camera so the pin stays visible in frame
                  _mapController.move(latLng, _mapController.camera.zoom);
                  _reverseGeocode(latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains:          const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.nuburn.nutritionapp.mealshop.v4',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point:  _markerPos,
                      width:  48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFD95F2B),
                        size:  48,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // "Tap to pin" hint badge
            Positioned(
              top:   10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color:     Colors.black.withOpacity(0.12),
                        blurRadius: 6),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 14, color: _green),
                    SizedBox(width: 4),
                    Text('Tap to pin',
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      _green)),
                  ],
                ),
              ),
            ),

            // Geocoding overlay
            if (_isGeocoding)
              Positioned(
                bottom: 10,
                left:   0,
                right:  0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color:        Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width:  12,
                          height: 12,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 1.5),
                        ),
                        SizedBox(width: 8),
                        Text('Getting address…',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   12,
                                fontWeight: FontWeight.w500)),
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
}

// Label Chip

class _LabelChip extends StatelessWidget {
  final IconData              icon;
  final String                label;
  final AddressLabel          value;
  final AddressLabel?         selected;
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
          color:        isSelected ? _terracotta : Colors.white,
          border:       Border.all(color: _terracotta, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size:  16,
                color: isSelected ? Colors.white : _terracotta),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      isSelected ? Colors.white : _terracotta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable small widgets

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   13,
            color:      Color(0xFF2C2C2C))),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style:      const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText:  hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      filled:    true,
      fillColor: const Color(0xFFEEEBDE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:   BorderSide.none,
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
