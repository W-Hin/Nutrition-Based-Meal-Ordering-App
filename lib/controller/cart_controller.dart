import 'package:flutter/material.dart';
import '../model/cart_item.dart';
import '../service/cart_service.dart';

class CartController extends ChangeNotifier {
  final CartService _service = CartService();

  List<CartItem> _items = [];
  bool isLoading = false;
  String? error;

  // ── Read-only access ───────────────────────────────────────────────────────
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get serviceFee => subtotal * 0.05;

  double get total => subtotal + serviceFee;

  // ── Load cart from Supabase ────────────────────────────────────────────────
  Future<void> loadCart() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _items = await _service.fetchCart();
      debugPrint('[CartController] loadCart: ${_items.length} items loaded');
    } catch (e) {
      error = e.toString();
      debugPrint('[CartController] loadCart ERROR: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Add item ───────────────────────────────────────────────────────────────
  Future<void> addItem(CartItem item) async {
    // Optimistic: show immediately in UI
    _items.add(item);
    notifyListeners();

    try {
      debugPrint('[CartController] addItem: inserting "${item.name}"...');
      final saved = await _service.insertItem(item);
      debugPrint('[CartController] addItem: success, id=${saved.cartItemId}');

      final idx = _items.indexOf(item);
      if (idx != -1) _items[idx] = saved;
      error = null;
    } catch (e) {
      _items.remove(item);
      error = e.toString();
      debugPrint('[CartController] addItem ERROR: $e');
    }

    notifyListeners();
  }

  // ── Increment quantity ─────────────────────────────────────────────────────
  Future<void> increment(int index) async {
    final item = _items[index];
    item.quantity++;
    notifyListeners();

    if (item.cartItemId != null) {
      try {
        await _service.updateQuantity(item.cartItemId!, item.quantity);
      } catch (e) {
        item.quantity--;
        error = e.toString();
        debugPrint('[CartController] increment ERROR: $e');
        notifyListeners();
      }
    }
  }

  // ── Decrement quantity ─────────────────────────────────────────────────────
  Future<void> decrement(int index) async {
    final item = _items[index];

    if (item.quantity > 1) {
      item.quantity--;
      notifyListeners();

      if (item.cartItemId != null) {
        try {
          await _service.updateQuantity(item.cartItemId!, item.quantity);
        } catch (e) {
          item.quantity++;
          error = e.toString();
          debugPrint('[CartController] decrement ERROR: $e');
          notifyListeners();
        }
      }
    } else {
      _items.removeAt(index);
      notifyListeners();

      if (item.cartItemId != null) {
        try {
          await _service.deleteItem(item.cartItemId!);
        } catch (e) {
          _items.insert(index, item);
          error = e.toString();
          debugPrint('[CartController] deleteItem ERROR: $e');
          notifyListeners();
        }
      }
    }
  }

  // ── Clear cart ─────────────────────────────────────────────────────────────
  Future<void> clearCart() async {
    final backup = List<CartItem>.from(_items);
    _items.clear();
    notifyListeners();

    try {
      await _service.clearCart();
    } catch (e) {
      _items = backup;
      error = e.toString();
      debugPrint('[CartController] clearCart ERROR: $e');
      notifyListeners();
    }
  }
}