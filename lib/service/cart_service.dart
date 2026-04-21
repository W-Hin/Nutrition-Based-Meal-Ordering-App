import '../model/cart_item.dart';
import 'supabase_conn.dart';

class CartService {
  /// Returns null when no user is signed in.
  String? get _uid => supabase.auth.currentUser?.id;

  // Check if same food from same store already in cart
  Future<CartItem?> findExistingItem({
    required String? foodId,
    required String? storeId,
  }) async {
    // Custom bowls (foodId null) are never merged
    if (foodId == null) return null;
    // Guard: storeId must be a valid non-empty value
    if (storeId == null || storeId.isEmpty) return null;
    final uid = _uid;
    if (uid == null || uid.isEmpty) return null;

    final rows = await supabase
        .from('cart_items')
        .select()
        .eq('user_id', uid)
        .eq('food_id', foodId)
        .eq('store_id', storeId)
        .eq('item_type', 'preset')
        .limit(1);

    if ((rows as List).isEmpty) return null;
    return CartItem.fromMap(rows.first);
  }

  // Fetch all cart items for the current user, filtered by store
  Future<List<CartItem>> fetchCart({String? storeId}) async {
    final uid = _uid;
    // Not signed in — return empty list instead of crashing with bad UUID
    if (uid == null || uid.isEmpty) return [];

    var query = supabase
        .from('cart_items')
        .select()
        .eq('user_id', uid);

    if (storeId != null && storeId.isNotEmpty) {
      query = query.eq('store_id', storeId);
    }

    final rows = await query.order('created_at', ascending: true);
    return (rows as List).map((r) => CartItem.fromMap(r)).toList();
  }

  // Insert a new item, return the saved row (with cart_item_id)
  Future<CartItem> insertItem(CartItem item) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) throw Exception('Not authenticated');
    final row = await supabase
        .from('cart_items')
        .insert(item.toInsertMap(uid))
        .select()
        .single();

    return CartItem.fromMap(row);
  }

  // Update quantity for an existing item
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('cart_item_id', cartItemId)
        .eq('user_id', uid);
  }

  // Delete a single item
  Future<void> deleteItem(String cartItemId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await supabase
        .from('cart_items')
        .delete()
        .eq('cart_item_id', cartItemId)
        .eq('user_id', uid);
  }

  // Clear cart for this user (optionally scoped to a store)
  Future<void> clearCart({String? storeId}) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    var query = supabase
        .from('cart_items')
        .delete()
        .eq('user_id', uid);

    if (storeId != null && storeId.isNotEmpty) {
      query = query.eq('store_id', storeId);
    }

    await query;
  }
}
