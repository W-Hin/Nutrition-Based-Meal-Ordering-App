import 'package:flutter/material.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/payment.dart';
import 'package:provider/provider.dart';
import '../../controller/checkout_controller.dart';
import '../../controller/cart_controller.dart';
import '../../model/address_model.dart';
import 'edit_address.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutController(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  static const _green = Color(0xFF1E4620);
  static const _bg    = Color(0xFFF5F5F0);

  @override
  Widget build(BuildContext context) {
    final ctrl       = context.watch<CheckoutController>();
    final cart       = context.watch<CartController>();
    final isDelivery = ctrl.activeTab == CheckoutTab.delivery;
    final grandTotal = cart.total + ctrl.deliveryFee;

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
          'CHECKOUT',
          style: TextStyle(
            color: _green,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _TabBar(active: ctrl.activeTab, onSwitch: ctrl.setTab),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isDelivery
                  ? _DeliveryContent(ctrl: ctrl)
                  : _SelfCollectContent(ctrl: ctrl),
            ),
          ),
          _BottomBar(
            subtotal:    cart.total,
            deliveryFee: ctrl.deliveryFee,
            isDelivery:  isDelivery,
            label: isDelivery
                ? 'PLACE DELIVERY ORDER'
                : 'PLACE SELF COLLECT ORDER',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentPage(
                    checkoutCtrl: context.read<CheckoutController>(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar ────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final CheckoutTab active;
  final ValueChanged<CheckoutTab> onSwitch;

  const _TabBar({required this.active, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _Tab(
            label:    'Delivery',
            isActive: active == CheckoutTab.delivery,
            onTap:    () => onSwitch(CheckoutTab.delivery),
          ),
          _Tab(
            label:    'Self Collect',
            isActive: active == CheckoutTab.selfCollect,
            onTap:    () => onSwitch(CheckoutTab.selfCollect),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const _green = Color(0xFF1E4620);

  const _Tab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? _green : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color:      isActive ? _green : const Color(0xFF8A8A8A),
              fontSize:   14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delivery Content ───────────────────────────────────────────────────────────

class _DeliveryContent extends StatelessWidget {
  final CheckoutController ctrl;
  const _DeliveryContent({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final slots = ctrl.generateTimeSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.location_on_outlined, title: 'Delivery Address'),
        const SizedBox(height: 8),
        _AddressCard(
          address: ctrl.deliveryAddress,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditAddressPage(ctrl: ctrl)),
          ),
        ),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.directions_bike_outlined, title: 'Delivery Options'),
        const SizedBox(height: 8),

        // Eco
        _DeliveryOptionTile(
          label:      'Eco',
          subtitle:   '~40 mins',
          fee:        'RM 2.00',
          value:      DeliveryOption.eco,
          groupValue: ctrl.deliveryOption,
          onChanged:  ctrl.setDeliveryOption,
        ),
        const SizedBox(height: 8),

        // Standard
        _DeliveryOptionTile(
          label:      'Standard',
          subtitle:   '~20 mins',
          fee:        'RM 4.00',
          value:      DeliveryOption.standard,
          groupValue: ctrl.deliveryOption,
          onChanged:  ctrl.setDeliveryOption,
        ),
        const SizedBox(height: 8),

        // Fast
        _DeliveryOptionTile(
          label:      'Fast',
          subtitle:   '~10 mins',
          fee:        'RM 8.00',
          value:      DeliveryOption.fast,
          groupValue: ctrl.deliveryOption,
          onChanged:  ctrl.setDeliveryOption,
        ),
        const SizedBox(height: 8),

        // Order For Later
        _DeliveryOptionTile(
          label:      'Order For Later',
          subtitle:   'Choose your preferred time',
          fee:        'RM 4.00',
          value:      DeliveryOption.orderLater,
          groupValue: ctrl.deliveryOption,
          onChanged:  ctrl.setDeliveryOption,
        ),

        // Time dropdown — only shows when Order For Later is selected
        if (ctrl.deliveryOption == DeliveryOption.orderLater) ...[
          const SizedBox(height: 8),
          _TimeDropdown(
            slots:       slots,
            selected:    ctrl.selectedLaterTime,
            onChanged:   ctrl.setLaterTime,
          ),
        ],

        const SizedBox(height: 16),
        _SectionHeader(icon: Icons.sticky_note_2_outlined, title: 'Remarks'),
        const SizedBox(height: 8),
        _RemarksField(onChanged: ctrl.setRemarks),
      ],
    );
  }
}

// ── Self Collect Content ───────────────────────────────────────────────────────

class _SelfCollectContent extends StatelessWidget {
  final CheckoutController ctrl;
  const _SelfCollectContent({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final slots = ctrl.generateTimeSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.location_on_outlined, title: 'Self Collection Address'),
        const SizedBox(height: 8),
        _AddressCard(
          address: AddressModel(
            name:    'NuBurn - Tanjung Burma',
            phone:   '',
            address: '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21, ...',
          ),
          showArrow:     false,
          showSetCustom: false,
        ),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.shopping_basket_outlined, title: 'Self Collection Options'),
        const SizedBox(height: 8),

        // Pick Up Now
        _DeliveryOptionTile(
          label:      'Pick Up Now',
          subtitle:   'Ready in ~9 mins',
          fee:        'Free',
          value:      DeliveryOption.pickUpNow,
          groupValue: ctrl.selfCollectOption,
          onChanged:  ctrl.setSelfCollectOption,
          feeIsGreen: true,
        ),
        const SizedBox(height: 8),

        // Order For Later
        _DeliveryOptionTile(
          label:      'Order For Later',
          subtitle:   'Choose your preferred time',
          fee:        'Free',
          value:      DeliveryOption.selfLater,
          groupValue: ctrl.selfCollectOption,
          onChanged:  ctrl.setSelfCollectOption,
          feeIsGreen: true,
        ),

        // Time dropdown
        if (ctrl.selfCollectOption == DeliveryOption.selfLater) ...[
          const SizedBox(height: 8),
          _TimeDropdown(
            slots:     slots,
            selected:  ctrl.selectedSelfLaterTime,
            onChanged: ctrl.setSelfLaterTime,
          ),
        ],

        const SizedBox(height: 16),
        _SectionHeader(icon: Icons.sticky_note_2_outlined, title: 'Remarks'),
        const SizedBox(height: 8),
        _RemarksField(onChanged: ctrl.setRemarks),
      ],
    );
  }
}

// ── Delivery Option Tile (replaces old _RadioOption) ──────────────────────────

class _DeliveryOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String fee;
  final DeliveryOption value;
  final DeliveryOption groupValue;
  final ValueChanged<DeliveryOption> onChanged;
  final bool feeIsGreen;

  static const _green = Color(0xFF1E4620);

  const _DeliveryOptionTile({
    required this.label,
    required this.subtitle,
    required this.fee,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.feeIsGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _green : const Color(0xFFDDDDD0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width:  20,
              height: 20,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _green : const Color(0xFFAAAAAA),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width:  10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),

            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:      const Color(0xFF2C2C2C),
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                ],
              ),
            ),

            // Fee badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        feeIsGreen
                    ? _green.withOpacity(0.08)
                    : const Color(0xFFEEEBDE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                fee,
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      feeIsGreen ? _green : const Color(0xFF5C4A1E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time Dropdown ──────────────────────────────────────────────────────────────

class _TimeDropdown extends StatelessWidget {
  final List<String> slots;
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _green = Color(0xFF1E4620);

  const _TimeDropdown({
    required this.slots,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No available time slots today (orders close at 9:00 PM).',
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:       selected,
          isExpanded:  true,
          hint: const Text('Select a time',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          icon: const Icon(Icons.access_time, color: Color(0xFF8A8A8A), size: 18),
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF2C2C2C)),
          items: slots
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Shared widgets (unchanged from original) ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  static const _green = Color(0xFF1E4620);

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _green, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF2C2C2C))),
    ],
  );
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool showSetCustom;

  static const _green = Color(0xFF1E4620);

  const _AddressCard({
    required this.address,
    this.onTap,
    this.showArrow    = true,
    this.showSetCustom = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: const Color(0xFFDDDDD0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(address.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      if (address.phone.isNotEmpty) ...[
                        const Text('  |  ',
                            style: TextStyle(color: Color(0xFFAAAAAA))),
                        Text(address.phone,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B6B6B))),
                      ],
                    ],
                  ),
                ),
                if (showSetCustom)
                  const Text('Set Custom Address',
                      style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(address.address,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B6B6B))),
                ),
                if (showArrow)
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF6B6B6B), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color:        const Color(0xFFD9D5C5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.map_outlined,
                    size: 30, color: Color(0xFF9E9880)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemarksField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _RemarksField({required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText:  'Leave a Note... (Optional)',
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

class _BottomBar extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final bool isDelivery;
  final String label;
  final VoidCallback onPressed;

  static const _terracotta = Color(0xFFD95F2B);
  static const _green      = Color(0xFF1E4620);

  const _BottomBar({
    required this.subtotal,
    required this.deliveryFee,
    required this.isDelivery,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final grandTotal = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color:     Colors.white,
        boxShadow: [
          BoxShadow(
              color:  Color(0x18000000),
              blurRadius: 12,
              offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show delivery fee breakdown if delivery
          if (isDelivery && deliveryFee > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
                Text('RM ${deliveryFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8A8A8A))),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                  Text(
                    'RM ${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF2C2C2C)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _terracotta,
                      foregroundColor: Colors.white,
                      elevation:       0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize:   12,
                            letterSpacing: 0.8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}