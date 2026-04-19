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

  // ── Load cart ─────────────────────────────────────────────────────────────
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

  // ── Add item ──────────────────────────────────────────────────────────────
  Future<void> addItem(CartItem item) async {
    try {
      // ── Step 1: Check for duplicate (same food + store) ──
      final existing = await _service.findExistingItem(
        foodId:  item.foodId,
        storeId: item.storeId,
      );

      if (existing != null && existing.cartItemId != null) {
        debugPrint('[CartController] duplicate found, incrementing qty');
        final newQty = existing.quantity + item.quantity;
        await _service.updateQuantity(existing.cartItemId!, newQty);

        // Update in local list
        final idx = _items.indexWhere(
              (i) => i.cartItemId == existing.cartItemId,
        );
        if (idx != -1) {
          _items[idx].quantity = newQty;
        } else {
          // Edge case: not in local list yet, reload
          await loadCart();
          return;
        }

        error = null;
        notifyListeners();
        return;
      }

      // ── Step 2: No duplicate — insert then reload ──
      // Instead of optimistic update (which causes the bad state error),
      // insert first, THEN add to local list with the real cartItemId
      debugPrint('[CartController] addItem: inserting "${item.name}"...');
      final saved = await _service.insertItem(item);
      debugPrint('[CartController] addItem: success, id=${saved.cartItemId}');

      _items.add(saved);  // ← add the SAVED item, not the original
      error = null;

    } catch (e) {
      error = e.toString();
      debugPrint('[CartController] addItem ERROR: $e');
    }

    notifyListeners();
  }

  // ── Increment ─────────────────────────────────────────────────────────────
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
        notifyListeners();
      }
    }
  }

  // ── Decrement ─────────────────────────────────────────────────────────────
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
      notifyListeners();
    }
  }
}