import '../model/order_model.dart';
import 'supabase_conn.dart';

class OrderService {
  // ── Save a new order + its items in one go ───────────────────
  Future<String> placeOrder(OrderModel order) async {
    // Insert order row
    final orderResponse = await supabase
        .from('orders')
        .insert({
      'user_id':        supabase.auth.currentUser?.id ?? 'fc33ae36-657a-4055-b81e-f6fe3de23278',
      'order_type':     order.orderType.name,
      'status':         order.status.name,
      'to_name':        order.toName,
      'to_phone':       order.toPhone,
      'to_address':     order.toAddress,
      'subtotal':       order.subtotal,
      'service_fee':    order.serviceFee,
      'payment_method': order.paymentMethod,
    })
        .select('order_id')
        .single();

    final orderId = orderResponse['order_id'].toString();

    // Insert all order items linked to that order
    await supabase.from('order_items').insert(
      order.items
          .map((item) => {
        'order_id': orderId,
        'name':     item.name,
        'price':    item.price,
        'add_ons':  item.addOns,
      })
          .toList(),
    );

    return orderId;
  }

  // ── Fetch a single order by ID ───────────────────────────────
  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    return await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('order_id', orderId)   // ← was 'id'
        .single();
  }

  // ── Fetch all orders for current user ────────────────────────
  Future<List<Map<String, dynamic>>> fetchUserOrders() async {
    return await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', supabase.auth.currentUser?.id ?? 'fc33ae36-657a-4055-b81e-f6fe3de23278')
        .order('created_at', ascending: false);
  }

  // ── Listen to real-time status changes (for order details page)
  Stream<Map<String, dynamic>> watchOrderStatus(String orderId) {
    return supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])   // ← was ['id']
        .eq('order_id', orderId)
        .map((rows) => rows.first);
  }

  // ── Cancel order ─────────────────────────────────────────────
  Future<void> cancelOrder(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'cancelled'})
        .eq('order_id', orderId);
  }
}