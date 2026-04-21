import 'package:flutter/material.dart';
import '../model/review_model.dart';
import '../service/review_service.dart';

class ReviewController extends ChangeNotifier {
  final ReviewService _svc = ReviewService();

  // ── State ──────────────────────────────────────────────────────────────────
  List<ReviewModel> myReviews    = [];
  List<ReviewModel> allReviews   = [];
  List<ReviewModel> storeReviews = [];

  bool   isLoading    = false;
  bool   isSubmitting = false;
  String errorMessage = '';

  // ── Load my reviews ────────────────────────────────────────────────────────
  Future<void> loadMyReviews() async {
    isLoading    = true;
    errorMessage = '';
    notifyListeners();
    try {
      myReviews = await _svc.fetchMyReviews();
    } catch (e) {
      errorMessage = 'Failed to load reviews.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Load all reviews (admin) ───────────────────────────────────────────────
  Future<void> loadAllReviews() async {
    isLoading    = true;
    errorMessage = '';
    notifyListeners();
    try {
      allReviews = await _svc.fetchAllReviews();
    } catch (e) {
      errorMessage = 'Failed to load reviews.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Load reviews for a specific store ─────────────────────────────────────
  Future<void> loadStoreReviews(String storeId) async {
    isLoading    = true;
    errorMessage = '';
    notifyListeners();
    try {
      storeReviews = await _svc.fetchStoreReviews(storeId);
    } catch (e) {
      errorMessage = 'Failed to load store reviews.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Submit review (customer) ───────────────────────────────────────────────
  Future<bool> submitReview(ReviewModel review) async {
    isSubmitting = true;
    errorMessage = '';
    notifyListeners();
    try {
      await _svc.submitReview(review);
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

  // ── Update review (customer edit) ─────────────────────────────────────────
  Future<bool> updateReview(String reviewId, int rating, String comment) async {
    isSubmitting = true;
    notifyListeners();
    try {
      await _svc.updateReview(reviewId, rating, comment);
      // Update local caches
      _updateInList(myReviews,    reviewId, rating, comment);
      _updateInList(storeReviews, reviewId, rating, comment);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update review.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _updateInList(List<ReviewModel> list, String id, int rating, String comment) {
    final i = list.indexWhere((r) => r.id == id);
    if (i != -1) {
      list[i] = list[i].copyWith(
        rating:    rating,
        comment:   comment,
        updatedAt: DateTime.now(),
      );
    }
  }

  // ── Admin reply ────────────────────────────────────────────────────────────
  Future<bool> replyReview(String reviewId, String reply) async {
    try {
      await _svc.replyReview(reviewId, reply);
      final i = allReviews.indexWhere((r) => r.id == reviewId);
      if (i != -1) {
        allReviews[i] = allReviews[i].copyWith(
          adminReply: reply,
          repliedAt:  DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Check already reviewed (orderId is int) ────────────────────────────────
  Future<bool> hasReviewedOrder(int orderId) =>
      _svc.hasReviewedOrder(orderId);

  // ── Get existing review for an order ──────────────────────────────────────
  Future<ReviewModel?> getOrderReview(int orderId) =>
      _svc.getOrderReview(orderId);

  // ── Delete review ──────────────────────────────────────────────────────────
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _svc.deleteReview(reviewId);
      myReviews.removeWhere((r)    => r.id == reviewId);
      storeReviews.removeWhere((r) => r.id == reviewId);
      allReviews.removeWhere((r)   => r.id == reviewId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Fetch rating stats for a store ────────────────────────────────────────
  Future<Map<String, dynamic>> fetchStoreRatingStats(String storeId) =>
      _svc.fetchStoreRatingStats(storeId);
}
