import 'package:flutter/material.dart';
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
      // CheckoutController is local to this flow — not app-wide
      create: (_) => CheckoutController(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  static const _green      = Color(0xFF1E4620);
  static const _bg         = Color(0xFFF5F5F0);

  @override
  Widget build(BuildContext context) {
    final ctrl  = context.watch<CheckoutController>();
    final cart  = context.watch<CartController>();
    final isDelivery = ctrl.activeTab == CheckoutTab.delivery;

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
          // ── Tab bar ──
          _TabBar(active: ctrl.activeTab, onSwitch: ctrl.setTab),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isDelivery
                  ? _DeliveryContent(ctrl: ctrl)
                  : _SelfCollectContent(ctrl: ctrl),
            ),
          ),

          // ── Bottom total + CTA ──
          _BottomBar(
            total: cart.total,
            label: isDelivery
                ? 'PLACE DELIVERY ORDER'
                : 'PLACE SELF COLLECT ORDER',
            onPressed: () {
              // TODO: submit order
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
            label: 'Delivery',
            isActive: active == CheckoutTab.delivery,
            onTap: () => onSwitch(CheckoutTab.delivery),
          ),
          _Tab(
            label: 'Self Collect',
            isActive: active == CheckoutTab.selfCollect,
            onTap: () => onSwitch(CheckoutTab.selfCollect),
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

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

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
              fontWeight:
              isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? _green : const Color(0xFF8A8A8A),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delivery Tab Content ───────────────────────────────────────────────────────

class _DeliveryContent extends StatelessWidget {
  final CheckoutController ctrl;
  const _DeliveryContent({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address card — tappable, goes to EditAddressPage
        _SectionHeader(icon: Icons.location_on_outlined, title: 'Delivery Address'),
        const SizedBox(height: 8),
        _AddressCard(
          address: ctrl.deliveryAddress,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditAddressPage(ctrl: ctrl), // ← pass ctrl here
            ),
          ),
        ),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.directions_bike_outlined, title: 'Delivery Options'),
        const SizedBox(height: 8),
        _RadioOption(
          label: 'Standard - 20 mins',
          value: DeliveryOption.standard,
          groupValue: ctrl.deliveryOption,
          onChanged: ctrl.setDeliveryOption,
        ),
        const SizedBox(height: 8),
        _RadioOption(
          label: 'Order For Later',
          value: DeliveryOption.orderLater,
          groupValue: ctrl.deliveryOption,
          onChanged: ctrl.setDeliveryOption,
        ),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.attach_money, title: 'Payment Method'),
        const SizedBox(height: 8),
        _PaymentCard(),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.sticky_note_2_outlined, title: 'Remarks'),
        const SizedBox(height: 8),
        _RemarksField(onChanged: ctrl.setRemarks),
      ],
    );
  }
}

// ── Self Collect Tab Content ───────────────────────────────────────────────────

class _SelfCollectContent extends StatelessWidget {
  final CheckoutController ctrl;
  const _SelfCollectContent({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.location_on_outlined, title: 'Self Collection Address'),
        const SizedBox(height: 8),
        // Static card — not tappable for self collect
        _AddressCard(
          address: AddressModel(
            name: 'NuBurn - Tanjung Burma',
            phone: '',
            address: '1-2-32, Medan Kampung Miao 2, Bulit Gelugor 21, ...',
          ),
          showArrow: false,
          showSetCustom: false,
        ),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.shopping_basket_outlined, title: 'Self Collection Options'),
        const SizedBox(height: 8),
        _RadioOption(
          label: 'Pick Up Now - After 9 mins',
          value: DeliveryOption.standard,
          groupValue: ctrl.selfCollectOption,
          onChanged: ctrl.setSelfCollectOption,
        ),
        const SizedBox(height: 8),
        _RadioOption(
          label: 'Order For Later',
          value: DeliveryOption.orderLater,
          groupValue: ctrl.selfCollectOption,
          onChanged: ctrl.setSelfCollectOption,
        ),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.attach_money, title: 'Payment Method'),
        const SizedBox(height: 8),
        _PaymentCard(),
        const SizedBox(height: 16),

        _SectionHeader(icon: Icons.sticky_note_2_outlined, title: 'Remarks'),
        const SizedBox(height: 8),
        _RemarksField(onChanged: ctrl.setRemarks),
      ],
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

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
    this.showArrow = true,
    this.showSetCustom = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDDDD0)),
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
            // Map placeholder
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D5C5),
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

class _RadioOption extends StatelessWidget {
  final String label;
  final DeliveryOption value;
  final DeliveryOption groupValue;
  final ValueChanged<DeliveryOption> onChanged;

  static const _green = Color(0xFF1E4620);

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDDDD0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C))),
            ),
            // Outer ring
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? _green : const Color(0xFFAAAAAA),
                    width: 2),
              ),
              // Inner dot when selected
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDDDD0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E4620),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.credit_card, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credit / Debit Card',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text('**** **** **** 1234',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFF6B6B6B), size: 20),
        ],
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
      hintText: 'Leave a Note... (Optional)',
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

class _BottomBar extends StatelessWidget {
  final double total;
  final String label;
  final VoidCallback onPressed;

  static const _terracotta = Color(0xFFD95F2B);

  const _BottomBar({
    required this.total,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x18000000),
              blurRadius: 12,
              offset: Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Text(
            'Total: RM ${total.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF2C2C2C)),
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
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}