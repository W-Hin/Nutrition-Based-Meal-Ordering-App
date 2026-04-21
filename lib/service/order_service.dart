import 'dart:math';
import '../model/order_model.dart';
import 'supabase_conn.dart';

class OrderService {
  String get _uid => supabase.auth.currentUser?.id ?? '';

  // ── Place order → returns the real DB order_id ──────────────
  Future<String> placeOrder(OrderModel order) async {
    // 1. Insert the order row (includes collection_code for self-collect)
    final orderResponse = await supabase
        .from('orders')
        .insert({
      'user_id':          _uid,
      'store_id':         order.storeId,
      'order_type':       order.orderType.name,
      'status':           order.status.name,
      'to_name':          order.toName,
      'to_phone':         order.toPhone.isEmpty ? null : order.toPhone,
      'to_address':       order.toAddress,
      'subtotal':         order.subtotal,
      'service_fee':      order.serviceFee,
      'delivery_fee':     order.deliveryFee,
      'total':            order.total,
      'total_cal':        order.totalCal,
      'total_pro':        order.totalPro,
      'total_carb':       order.totalCarb,
      'total_fat':        order.totalFat,
      'payment_method':   order.paymentMethod,
      'remark':           order.remark.isEmpty ? null : order.remark,
      'is_cancellable':   true,
      'order_date':       DateTime.now().toIso8601String(),
      // Always store collection_code for all order types (delivery + self-collect)
      'collection_code': await _ensureUniqueCode(order.collectionCode),
    })
        .select('order_id')
        .single();

    final orderId = orderResponse['order_id'].toString();

    // 2. Insert each cart item as a separate row, including quantity and image_url
    if (order.items.isNotEmpty) {
      await supabase.from('order_items').insert(
        order.items.map((item) => {
          'order_id': int.parse(orderId),
          'name':     item.name,
          'price':    item.price,
          'quantity': item.quantity,  // FIX 1: persist quantity
          'add_ons':  item.addOns.isEmpty ? <String>[] : item.addOns,
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            'image_url': item.imageUrl,
        }).toList(),
      );
    }

    return orderId;
  }

  // ── Fetch a single order by ID ───────────────────────────────
  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    return await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('order_id', orderId)
        .single();
  }

  // ── Fetch all orders for current user ────────────────────────
  Future<List<Map<String, dynamic>>> fetchUserOrders() async {
    return await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
  }

  // ── Real-time status stream ───────────────────────────────────
  Stream<Map<String, dynamic>> watchOrderStatus(String orderId) {
    return supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq('order_id', orderId)
        .map((rows) => rows.first);
  }

  // ── Cancel order ─────────────────────────────────────────────
  Future<void> cancelOrder(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'cancelled', 'is_cancellable': false})
        .eq('order_id', orderId);
  }

  // ── Ensure collection_code is unique in the orders table ─────
  Future<String> _ensureUniqueCode(String? suggested) async {
    final rng = Random();
    String generate() => (100 + rng.nextInt(900)).toString();

    // Fetch all existing codes once
    final rows = await supabase
        .from('orders')
        .select('collection_code');
    final existing = <String>{};
    for (final r in List<Map<String, dynamic>>.from(rows)) {
      final c = r['collection_code'] as String?;
      if (c != null) existing.add(c);
    }

    // Try suggested code first, then random ones
    var code = suggested ?? generate();
    for (int i = 0; i < 10 && existing.contains(code); i++) {
      code = generate();
    }
    // Fallback to 4-digit if all 3-digit attempts collide
    if (existing.contains(code)) {
      code = (1000 + rng.nextInt(9000)).toString();
    }
    return code;
  }
}