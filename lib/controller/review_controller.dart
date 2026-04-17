import 'package:flutter/material.dart';
import '../model/review_model.dart';
import '../service/review_service.dart';

class ReviewController extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  // Customer's own reviews
  List<ReviewModel> myReviews   = [];
  // All reviews — for admin
  List<ReviewModel> allReviews  = [];

  bool   isLoading     = false;
  bool   isSubmitting  = false;
  String errorMessage  = '';

  // ── Load my reviews ───────────────────────────────────────────────────────
  Future<void> loadMyReviews() async {
    isLoading    = true;
    errorMessage = '';
    notifyListeners();

    try {
      myReviews = await _reviewService.fetchMyReviews();
    } catch (e) {
      errorMessage = 'Failed to load reviews. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Load all reviews (admin) ──────────────────────────────────────────────
  Future<void> loadAllReviews() async {
    isLoading    = true;
    errorMessage = '';
    notifyListeners();

    try {
      allReviews = await _reviewService.fetchAllReviews();
    } catch (e) {
      errorMessage = 'Failed to load reviews.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Submit review (customer) ──────────────────────────────────────────────
  Future<bool> submitReview(ReviewModel review) async {
    isSubmitting = true;
    errorMessage = '';
    notifyListeners();

    try {
      await _reviewService.submitReview(review);
      myReviews.insert(0, review);
      return true;
    } catch (e) {
      errorMessage = 'Failed to submit review. Please try again.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Admin reply ───────────────────────────────────────────────────────────
  Future<bool> replyReview(String reviewId, String reply) async {
    try {
      await _reviewService.replyReview(reviewId, reply);
      final index = allReviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        final old = allReviews[index];
        allReviews[index] = ReviewModel(
          id:          old.id,
          userId:      old.userId,
          storeId:     old.storeId,
          orderId:     old.orderId,
          rating:      old.rating,
          comment:     old.comment,
          adminReply:  reply,
          repliedAt:   DateTime.now(),
          createdAt:   old.createdAt,
          userName:    old.userName,
          storeName:   old.storeName,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Check already reviewed ────────────────────────────────────────────────
  Future<bool> hasReviewedOrder(String orderId) =>
      _reviewService.hasReviewedOrder(orderId);

  // ── Delete review ─────────────────────────────────────────────────────────
  Future<void> deleteReview(String reviewId) async {
    await _reviewService.deleteReview(reviewId);
    myReviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }
}
