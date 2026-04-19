// cart_controller.dart
import 'package:flutter/material.dart';
import '../model/cart_item.dart';
import '../service/cart_service.dart';

class CartController extends ChangeNotifier {
  final CartService _service = CartService();

  List<CartItem> _items = [];
  bool isLoading = false;
  String? error;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get serviceFee => subtotal * 0.05;

  double get total => subtotal + serviceFee;

  // ── Load cart ────────────────────────────────────────────────────────────
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

  // ── Add item (with duplicate check) ──────────────────────────────────────
  Future<void> addItem(CartItem item) async {
    try {
      // Check if same food+store already exists in cart
      final existing = await _service.findExistingItem(
        foodId:  item.foodId,
        storeId: item.storeId,
      );

      if (existing != null && existing.cartItemId != null) {
        // Found duplicate — just increment quantity instead
        debugPrint('[CartController] duplicate found, incrementing qty');

        final newQty = existing.quantity + item.quantity;
        await _service.updateQuantity(existing.cartItemId!, newQty);

        // Update local list
        final idx = _items.indexWhere(
              (i) => i.cartItemId == existing.cartItemId,
        );
        if (idx != -1) {
          _items[idx].quantity = newQty;
        }

        error = null;
        notifyListeners();
        return;
      }

      // No duplicate — insert as new item (optimistic)
      _items.add(item);
      notifyListeners();

      final saved = await _service.insertItem(item);
      debugPrint('[CartController] addItem: success, id=${saved.cartItemId}');

      // Replace optimistic item with saved (has real cartItemId)
      final idx = _items.lastIndexOf(item);
      if (idx != -1) _items[idx] = saved;
      error = null;

    } catch (e) {
      // Remove optimistic item on failure
      _items.remove(item);
      error = e.toString();
      debugPrint('[CartController] addItem ERROR: $e');
    }

    notifyListeners();
  }

  // ── Increment ────────────────────────────────────────────────────────────
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

  // ── Decrement ────────────────────────────────────────────────────────────
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

  // ── Clear cart ────────────────────────────────────────────────────────────
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