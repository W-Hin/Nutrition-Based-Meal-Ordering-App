import '../model/order_model.dart';
import 'supabase_conn.dart';

class OrderService {
  static const _devUserId = 'fc33ae36-657a-4055-b81e-f6fe3de23278';

  String get _uid =>
      supabase.auth.currentUser?.id ?? _devUserId;

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
      'payment_method':   order.paymentMethod,
      'remark':           order.remark.isEmpty ? null : order.remark,
      'is_cancellable':   true,
      'order_date':       DateTime.now().toIso8601String(),
      // collection_code stored only for selfCollect orders
      if (order.collectionCode != null)
        'collection_code': order.collectionCode,
    })
        .select('order_id')
        .single();

    final orderId = orderResponse['order_id'].toString();

    // 2. Insert each cart item as a separate row, including image_url
    if (order.items.isNotEmpty) {
      await supabase.from('order_items').insert(
        order.items.map((item) => {
          'order_id': int.parse(orderId),
          'name':     item.name,
          'price':    item.price,
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
}