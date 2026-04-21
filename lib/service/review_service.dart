import '../model/review_model.dart';
import 'supabase_conn.dart';

class ReviewService {
  String get _uid => supabase.auth.currentUser?.id ?? '';

  // Submit a new review (customer)
  Future<ReviewModel> submitReview(ReviewModel review) async {
    final row = await supabase
        .from('reviews')
        .insert(review.toMap())
        .select('*')
        .single();
    return ReviewModel.fromMap(Map<String, dynamic>.from(row));
  }

  // Update an existing review (customer)
  Future<void> updateReview(String reviewId, int rating, String comment) async {
    await supabase.from('reviews').update({
      'rating':     rating,
      'comment':    comment,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reviewId);
  }

  // Check if current user already reviewed a specific order
  Future<bool> hasReviewedOrder(int orderId) async {
    final row = await supabase
        .from('reviews')
        .select('id, rating, comment')
        .eq('user_id', _uid)
        .eq('order_id', orderId)
        .maybeSingle();
    return row != null;
  }

  // Get existing review for an order (null if none)
  Future<ReviewModel?> getOrderReview(int orderId) async {
    final row = await supabase
        .from('reviews')
        .select('*')
        .eq('user_id', _uid)
        .eq('order_id', orderId)
        .maybeSingle();
    if (row == null) return null;
    return ReviewModel.fromMap(Map<String, dynamic>.from(row));
  }

  // Fetch current user's own reviews
  Future<List<ReviewModel>> fetchMyReviews() async {
    final rows = await supabase
        .from('reviews')
        .select('*, stores(name)')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReviewModel.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  // Fetch all reviews for a specific store (for store page)
  Future<List<ReviewModel>> fetchStoreReviews(String storeId) async {
    final rows = await supabase
        .from('reviews')
        .select('*')
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return _attachUserNames(rows as List);
  }

  // Fetch ALL reviews with user name — for admin
  Future<List<ReviewModel>> fetchAllReviews() async {
    final rows = await supabase
        .from('reviews')
        .select('*, stores(name)')
        .order('created_at', ascending: false);
    return _attachUserNames(rows as List);
  }

  // Helper: attach first_name+last_name from public.user
  Future<List<ReviewModel>> _attachUserNames(List rows) async {
    if (rows.isEmpty) return [];
    // Collect unique user_ids
    final uids = rows
        .map((r) => r['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    // Fetch names from public.user table
    final Map<String, String> nameMap = {};
    if (uids.isNotEmpty) {
      final userRows = await supabase
          .from('user')
          .select('user_id, first_name, last_name')
          .inFilter('user_id', uids);
      for (final u in (userRows as List)) {
        final uid   = u['user_id'] as String? ?? '';
        final first = (u['first_name'] as String? ?? '').trim();
        final last  = (u['last_name']  as String? ?? '').trim();
        nameMap[uid] = [first, last].where((s) => s.isNotEmpty).join(' ');
      }
    }
    return rows.map((r) {
      final map  = Map<String, dynamic>.from(r);
      final uid  = map['user_id'] as String? ?? '';
      map['user'] = {'first_name': nameMap[uid] ?? '', 'last_name': ''};
      return ReviewModel.fromMap(map);
    }).toList();
  }

  // Admin reply
  Future<void> replyReview(String reviewId, String reply) async {
    await supabase.from('reviews').update({
      'admin_reply': reply,
      'replied_at':  DateTime.now().toIso8601String(),
    }).eq('id', reviewId);
  }

  // Delete a review (customer can delete own)
  Future<void> deleteReview(String reviewId) async {
    await supabase.from('reviews').delete().eq('id', reviewId);
  }

  // Fetch rating stats for a store
  Future<Map<String, dynamic>> fetchStoreRatingStats(String storeId) async {
    final rows = await supabase
        .from('reviews')
        .select('rating')
        .eq('store_id', storeId);
    // Filter out any null ratings defensively
    final list  = (rows as List)
        .map((r) => (r['rating'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    if (list.isEmpty) return {'average': 0.0, 'count': 0, 'distribution': <int, int>{}};
    final avg   = list.reduce((a, b) => a + b) / list.length;
    final dist  = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    for (final r in list) {
      if (r >= 1 && r <= 5) dist[r] = (dist[r] ?? 0) + 1;
    }
    return {'average': avg, 'count': list.length, 'distribution': dist};
  }
}
