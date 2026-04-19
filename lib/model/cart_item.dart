class CartItem {
  final String? cartItemId;   // uuid from DB (null for local-only items before sync)
  final String? foodId;       // uuid — null for custom bowls
  final String? storeId;
  final String itemType;      // 'preset' | 'custom'
  final String name;
  final double price;
  final List<String> addOns;
  final Map<String, dynamic>? customDetails; // jsonb — used for custom bowl breakdown
  final String? imageUrl;
  int quantity;

  CartItem({
    this.cartItemId,
    this.foodId,
    this.storeId,
    this.itemType = 'preset',
    required this.name,
    required this.price,
    this.addOns = const [],
    this.customDetails,
    this.imageUrl,
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;

  // ── From Supabase row ──────────────────────────────────────────────────────
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      cartItemId:    map['cart_item_id'] as String?,
      foodId:        map['food_id'] as String?,
      storeId:       map['store_id'] as String?,
      itemType:      map['item_type'] as String? ?? 'preset',
      name:          map['name'] as String,
      price:         (map['price'] as num).toDouble(),
      quantity:      map['quantity'] as int? ?? 1,
      addOns:        List<String>.from(map['add_ons'] ?? []),
      customDetails: map['custom_details'] as Map<String, dynamic>?,
      imageUrl:      map['image_url'] as String?,
    );
  }

  // ── To Supabase insert payload ─────────────────────────────────────────────
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id':        userId,
      if (storeId != null)  'store_id':       storeId,
      if (foodId != null)   'food_id':         foodId,
      'item_type':      itemType,
      'name':           name,
      'price':          price,
      'quantity':       quantity,
      'add_ons':        addOns,
      if (customDetails != null) 'custom_details': customDetails,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}