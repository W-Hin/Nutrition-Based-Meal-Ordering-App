import '../model/review_model.dart';
import 'supabase_conn.dart';

class ReviewService {
  String get _uid => supabase.auth.currentUser?.id ?? 'test_user_ui_mode';

  // ── Submit a new review (customer) ───────────────────────────────────────
  Future<void> submitReview(ReviewModel review) async {
    await supabase.from('reviews').insert(review.toMap());
  }

  // ── Check if current user already reviewed a specific order ──────────────
  Future<bool> hasReviewedOrder(String orderId) async {
    final row = await supabase
        .from('reviews')
        .select('id')
        .eq('user_id', _uid)
        .eq('order_id', orderId)
        .maybeSingle();
    return row != null;
  }

  // ── Fetch current user's own reviews ─────────────────────────────────────
  Future<List<ReviewModel>> fetchMyReviews() async {
    final rows = await supabase
        .from('reviews')
        .select('*, stores(name)')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => ReviewModel.fromMap(r)).toList();
  }

  // ── Fetch ALL reviews with user name — for admin ──────────────────────────
  Future<List<ReviewModel>> fetchAllReviews() async {
    final rows = await supabase
        .from('reviews')
        .select('*, users(full_name), stores(name)')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => ReviewModel.fromMap(r)).toList();
  }

  // ── Admin reply ───────────────────────────────────────────────────────────
  Future<void> replyReview(String reviewId, String reply) async {
    await supabase.from('reviews').update({
      'admin_reply': reply,
      'replied_at':  DateTime.now().toIso8601String(),
    }).eq('id', reviewId);
  }

  // ── Delete a review (customer can delete own) ─────────────────────────────
  Future<void> deleteReview(String reviewId) async {
    await supabase.from('reviews').delete().eq('id', reviewId);
  }
}
