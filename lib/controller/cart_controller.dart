import 'package:flutter/material.dart';
import '../model/cart_item.dart';
import '../service/cart_service.dart';

class CartController extends ChangeNotifier {
  final CartService _service = CartService();

  List<CartItem> _items = [];
  bool isLoading = false;
  String? error;

  // Active store scope
  String? _activeStoreId;
  String? _activeStoreName;

  String? get activeStoreId   => _activeStoreId;
  String? get activeStoreName => _activeStoreName;

  List<CartItem> get items         => List.unmodifiable(_items);
  int    get totalItemCount        => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal              => _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get serviceFee            => subtotal * 0.05;
  double get total                 => subtotal + serviceFee;

  // Load cart (scoped to store)
  Future<void> loadCart({String? storeId}) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      _items = await _service.fetchCart(storeId: storeId ?? _activeStoreId);
      debugPrint('[CartController] loadCart: ${_items.length} items for store=$storeId');
    } catch (e) {
      error = e.toString();
      debugPrint('[CartController] loadCart ERROR: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Switch active store
  /// Call this when the user selects / enters a store.
  /// Reloads cart scoped to the new store.
  Future<void> setStore(String storeId, String storeName) async {
    if (_activeStoreId == storeId) return; // already on this store
    _activeStoreId   = storeId;
    _activeStoreName = storeName;
    _items = [];
    notifyListeners();
    await loadCart(storeId: storeId);
  }

  // Add item
  Future<void> addItem(CartItem item) async {
    // Guard: item must belong to the active store
    if (_activeStoreId != null &&
        item.storeId != null &&
        item.storeId != _activeStoreId) {
      // Different store — prompt caller to clear cart first
      error = 'DIFFERENT_STORE';
      notifyListeners();
      return;
    }

    try {
      // Step 1: Check for duplicate (same food + store)
      final existing = await _service.findExistingItem(
        foodId:  item.foodId,
        storeId: item.storeId,
      );

      if (existing != null && existing.cartItemId != null) {
        debugPrint('[CartController] duplicate found, incrementing qty');
        final newQty = existing.quantity + item.quantity;
        await _service.updateQuantity(existing.cartItemId!, newQty);

        final idx = _items.indexWhere(
              (i) => i.cartItemId == existing.cartItemId,
        );
        if (idx != -1) {
          _items[idx].quantity = newQty;
        } else {
          await loadCart(storeId: _activeStoreId);
          return;
        }

        error = null;
        notifyListeners();
        return;
      }

      // Step 2: No duplicate — insert then add to local list
      debugPrint('[CartController] addItem: inserting "${item.name}"...');
      final saved = await _service.insertItem(item);
      debugPrint('[CartController] addItem: success, id=${saved.cartItemId}');

      _items.add(saved);
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('[CartController] addItem ERROR: $e');
    }

    notifyListeners();
  }

  // Increment
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

  // Decrement
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

  // Clear cart (scoped to active store)
  Future<void> clearCart() async {
    final backup = List<CartItem>.from(_items);
    _items.clear();
    notifyListeners();

    try {
      await _service.clearCart(storeId: _activeStoreId);
    } catch (e) {
      _items = backup;
      error  = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    error = null;
    notifyListeners();
  }
}
