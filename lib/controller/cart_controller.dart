import 'package:flutter/material.dart';
import '../model/cart_item.dart';

class CartController extends ChangeNotifier {
  final List<CartItem> _items = [
    // Placeholder data — replace with real data from your backend later
    CartItem(
      name: 'Caesar Salad with Chicken Bites',
      price: 32.80,
      addOns: ['+ No Add Ons'],
      quantity: 3,
    ),
    CartItem(
      name: 'Custom Meal Bowl',
      price: 32.80,
      addOns: [
        'Brown Rice', 'Cherry Tomatoes',
        'Chicken Breast (100g)', 'Onions',
        'Minced Beef (100g)', 'Fresh Avocado',
      ],
      quantity: 3,
    ),
    CartItem(
      name: 'Caesar Salad with Chicken Bites',
      price: 32.80,
      addOns: ['+ No Add Ons'],
      quantity: 3,
    ),
    CartItem(
      name: 'Caesar Salad with Chicken Bites',
      price: 32.80,
      addOns: [
        'Cherry Tomatoes', 'Chicken Breast (150g)',
        'Onions', 'Minced Beef (100g)', 'Fresh Avocado',
      ],
      quantity: 3,
    ),
  ];

  // ── Read-only access ──────────────────────────────────────
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.lineTotal);

  double get serviceFee => subtotal * 0.05;

  double get total => subtotal + serviceFee;

  // ── Actions (called by View, notifies listeners) ──────────
  void increment(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  void decrement(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index); // remove item when qty reaches 0
    }
    notifyListeners();
  }

  void addItem(CartItem item) {
    // If item already exists, just increment quantity
    final existing = _items.where((e) => e.name == item.name).firstOrNull;
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}