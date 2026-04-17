import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/review_controller.dart';
import '../../model/review_model.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);
  static const _bg     = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewController>().loadAllReviews();
    });
  }

  void _showReplyDialog(BuildContext context, ReviewModel review, ReviewController ctrl) {
    final replyCtrl = TextEditingController(text: review.adminReply ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.reply_rounded, color: _green, size: 20),
                  const SizedBox(width: 8),
                  const Text('Reply to Review', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
                ],
              ),
              const SizedBox(height: 6),
              if (review.userName != null)
                Text('Customer: ${review.userName}', style: TextStyle(fontSize: 12, color: _dark.withOpacity(0.5))),
              const SizedBox(height: 14),

              // Customer's original review
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 14,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(review.comment, style: const TextStyle(fontSize: 12, color: _dark)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Reply field
              TextField(
                controller: replyCtrl,
                maxLines:   3,
                decoration: InputDecoration(
                  hintText:  'Type your reply...',
                  filled:    true,
                  fillColor: _bg,
                  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dark,
                        side: BorderSide(color: _dark.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (replyCtrl.text.trim().isEmpty) return;
                        final ok = await ctrl.replyReview(review.id!, replyCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reply sent!'),
                              backgroundColor: Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Send Reply', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ReviewController>();

    if (ctrl.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }

    if (ctrl.allReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined, size: 60, color: _dark.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('No reviews yet', style: TextStyle(color: _dark.withOpacity(0.4), fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: () => ctrl.loadAllReviews(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.allReviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final review = ctrl.allReviews[index];
          return _ReviewAdminCard(
            review: review,
            onReply: () => _showReplyDialog(context, review, ctrl),
          );
        },
      ),
    );
  }
}

class _ReviewAdminCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onReply;

  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  const _ReviewAdminCard({required this.review, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _dark.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _green.withOpacity(0.12),
                  child: Text(
                    (review.userName?.isNotEmpty == true) ? review.userName![0].toUpperCase() : '?',
                    style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                      ),
                      Text(
                        review.storeName ?? '',
                        style: TextStyle(fontSize: 11, color: _dark.withOpacity(0.45)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(children: List.generate(5, (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 14,
                    ))),
                    if (review.createdAt != null)
                      Text(
                        '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}',
                        style: TextStyle(fontSize: 10, color: _dark.withOpacity(0.35)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Comment ──────────────────────────────────────────────────────
            Text(review.comment, style: TextStyle(fontSize: 13, color: _dark.withOpacity(0.8), height: 1.4)),

            // ── Admin reply ───────────────────────────────────────────────────
            if (review.adminReply != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _green.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: _green, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review.adminReply!,
                        style: const TextStyle(fontSize: 12, color: _green),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Reply button ──────────────────────────────────────────────────
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: Icon(
                  review.adminReply != null ? Icons.edit_outlined : Icons.reply_rounded,
                  size: 16,
                  color: review.adminReply != null ? _orange : _green,
                ),
                label: Text(
                  review.adminReply != null ? 'Edit Reply' : 'Reply',
                  style: TextStyle(
                    color: review.adminReply != null ? _orange : _green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: review.adminReply != null
                      ? _orange.withOpacity(0.07)
                      : _green.withOpacity(0.07),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
