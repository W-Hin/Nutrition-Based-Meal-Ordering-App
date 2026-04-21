import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/review_controller.dart';
import '../../model/review_model.dart';
import '../../service/supabase_conn.dart';

class ReviewPage extends StatefulWidget {
  /// Pass the orderId and storeId when navigating to this page.
  final int    orderId;
  final String storeId;
  final String storeName;

  const ReviewPage({
    super.key,
    required this.orderId,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final _commentCtrl = TextEditingController();
  int   _rating      = 0;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final ctrl   = context.read<ReviewController>();
    final uid    = supabase.auth.currentUser!.id;
    final review = ReviewModel(
      userId:  uid,
      storeId: widget.storeId,
      orderId: widget.orderId,
      rating:  _rating,
      comment: _commentCtrl.text.trim(),
    );

    final ok = await ctrl.submitReview(review);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you 🎉'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ReviewController>();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Store card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reviewing', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(widget.storeName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Star rating ─────────────────────────────────────────────────
            const Text('Your Rating', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 44,
                      color: i < _rating ? Colors.amber.shade400 : _dark.withValues(alpha: 0.2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _rating == 0 ? 'Tap a star to rate'
                    : _rating == 1 ? 'Poor'
                    : _rating == 2 ? 'Fair'
                    : _rating == 3 ? 'Good'
                    : _rating == 4 ? 'Very Good'
                    : 'Excellent!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _rating == 0 ? _dark.withValues(alpha: 0.35) : Colors.amber.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Comment ─────────────────────────────────────────────────────
            const Text('Your Comment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 8),
            TextFormField(
              controller:  _commentCtrl,
              maxLines:    5,
              maxLength:   300,
              decoration: InputDecoration(
                hintText:  'Share your experience with this store and meal...',
                hintStyle: TextStyle(color: _dark.withValues(alpha: 0.35), fontSize: 13),
                filled:    true,
                fillColor: Colors.white,
                border:         OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _dark.withValues(alpha: 0.1))),
                enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _dark.withValues(alpha: 0.12))),
                focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _orange, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),

            // ── Tips ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tips for a helpful review:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _orange.withValues(alpha: 0.8))),
                  const SizedBox(height: 4),
                  ...[
                    'How was the food quality and freshness?',
                    'Was the delivery on time?',
                    'Were the nutrition values accurate?',
                  ].map((tip) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 4, color: _orange.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(tip, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.55))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: ctrl.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: ctrl.isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
