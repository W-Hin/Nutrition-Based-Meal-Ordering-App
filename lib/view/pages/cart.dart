import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/cart_controller.dart';
import '../../model/cart_item.dart';
import 'checkout.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5C4A1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'YOUR CART',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Consumer<CartController>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(color: Color(0xFF8A7E6A), fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _CartItemCard(
                    item: cart.items[index],
                    onIncrement: () => cart.increment(index),
                    onDecrement: () => cart.decrement(index),
                  ),
                ),
              ),
              _CartSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

// ── Cart Item Card ─────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CartItemImage(imageUrl: item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM${item.price % 1 == 0 ? item.price.toInt().toString() : item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 4),
                _AddOnsList(addOns: item.addOns),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuantityControl(
            quantity: item.quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

// ── Image widget with proper fallback ──────────────────────────────────────────

class _CartItemImage extends StatelessWidget {
  final String? imageUrl;

  const _CartItemImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D5C5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.fastfood_outlined,
        color: Color(0xFF9E9880),
        size: 32,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEBDE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1E4620),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

// ── Add-ons list — shows "- No Add Ons" when empty ────────────────────────────

class _AddOnsList extends StatelessWidget {
  final List<String> addOns;
  const _AddOnsList({required this.addOns});

  @override
  Widget build(BuildContext context) {

    if (addOns.isEmpty) {
      return const Text(
        '+ No Add Ons',
        style: TextStyle(fontSize: 11, color: Color(0xFF8A7E6A)),
      );
    }
    if (addOns.length == 1) {
      return Text(addOns.first,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A7E6A)));
    }
    final half = (addOns.length / 2).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _col(addOns.sublist(0, half))),
        Expanded(child: _col(addOns.sublist(half))),
      ],
    );
  }

  Widget _col(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map((a) => Text('• $a',
        style: const TextStyle(
            fontSize: 10, color: Color(0xFF8A7E6A))))
        .toList(),
  );
}

// ── [ + qty - ] control ────────────────────────────────────────────────────────

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCC9B8)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.add, onTap: onIncrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$quantity',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF2C2C2C))),
          ),
          _Btn(icon: Icons.remove, onTap: onDecrement),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEBDE),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF2C2C2C)),
      ),
    );
  }
}

// ── Summary + Checkout ─────────────────────────────────────────────────────────

class _CartSummary extends StatelessWidget {
  final CartController cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 12, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(label: 'Subtotal', value: cart.subtotal),
          const SizedBox(height: 6),
          _Row(label: 'Service Fee (5%)', value: cart.serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          _Row(
            label: 'Total (${cart.totalItemCount} items)',
            value: cart.total,
            isBold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF5D32),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  const _Row({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      fontSize: isBold ? 15 : 14,
      color: const Color(0xFF2C2C2C),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
            'RM ${value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2)}',
            style: style),
      ],
    );
  }
}