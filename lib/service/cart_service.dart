import '../model/cart_item.dart';
import 'supabase_conn.dart';

class CartService {
  String get _uid => supabase.auth.currentUser?.id ?? '';

  // ── Fetch all cart items for the current user ──────────────────────────────
  Future<List<CartItem>> fetchCart() async {
    final rows = await supabase
        .from('cart_items')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: true);

    return (rows as List).map((r) => CartItem.fromMap(r)).toList();
  }

  // ── Insert a new item, return the saved row (with cart_item_id) ────────────
  Future<CartItem> insertItem(CartItem item) async {
    final row = await supabase
        .from('cart_items')
        .insert(item.toInsertMap(_uid))
        .select()
        .single();

    return CartItem.fromMap(row);
  }

  // ── Update quantity for an existing item ───────────────────────────────────
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('cart_item_id', cartItemId)
        .eq('user_id', _uid); // safety: only update own rows
  }

  // ── Delete a single item ───────────────────────────────────────────────────
  Future<void> deleteItem(String cartItemId) async {
    await supabase
        .from('cart_items')
        .delete()
        .eq('cart_item_id', cartItemId)
        .eq('user_id', _uid);
  }

  // ── Clear the entire cart for this user ───────────────────────────────────
  Future<void> clearCart() async {
    await supabase
        .from('cart_items')
        .delete()
        .eq('user_id', _uid);
  }
}