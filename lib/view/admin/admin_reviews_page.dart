import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/review_controller.dart';
import '../../controller/store_controller.dart';
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

  // null = show all stores
  String? _filterStoreId;
  // 0 = All, 1 = Not Replied, 2 = Replied
  int _replyFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewController>().loadAllReviews();
    });
  }

  // Filtered list
  List<ReviewModel> _filtered(List<ReviewModel> all) {
    var list = _filterStoreId == null
        ? all
        : all.where((r) => r.storeId == _filterStoreId).toList();
    if (_replyFilter == 1) {
      list = list.where((r) => r.adminReply == null || r.adminReply!.isEmpty).toList();
    } else if (_replyFilter == 2) {
      list = list.where((r) => r.adminReply != null && r.adminReply!.isNotEmpty).toList();
    }
    return list;
  }

  // Reply dialog
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
                  const Text('Reply to Review',
                      style: TextStyle(
                          fontSize:   17,
                          fontWeight: FontWeight.w800,
                          color:      _dark)),
                ],
              ),
              const SizedBox(height: 6),
              if (review.userName != null)
                Text('Customer: ${review.userName}',
                    style: TextStyle(
                        fontSize: 12,
                        color:    _dark.withValues(alpha: 0.5))),
              const SizedBox(height: 14),

              // Customer review preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        _bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: List.generate(5, (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 14,
                    ))),
                    const SizedBox(height: 4),
                    Text(review.comment,
                        style: const TextStyle(fontSize: 12, color: _dark)),
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
                  border:        OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:   BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:   const BorderSide(color: _green)),
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
                        side: BorderSide(color: _dark.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (replyCtrl.text.trim().isEmpty) return;
                        final ok = await ctrl.replyReview(
                            review.id!, replyCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:         Text('Reply sent!'),
                              backgroundColor: Color(0xFF4CAF50),
                              behavior:        SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Send Reply',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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

  // Delete confirmation dialog
  Future<void> _confirmDelete(
      BuildContext context, ReviewModel review, ReviewController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From: ${review.userName ?? 'Anonymous'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              review.comment.isNotEmpty
                  ? '"${review.comment}"'
                  : '(No comment)',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B6B6B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A8A8A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation:       0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ctrl.deleteReview(review.id!);
    if (ok) {
      messenger.showSnackBar(const SnackBar(
        content:         Text('Review deleted.'),
        backgroundColor: Colors.red,
        behavior:        SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl       = context.watch<ReviewController>();
    final storeCtrl  = context.watch<StoreController>();
    final stores     = storeCtrl.stores;
    final displayed  = _filtered(ctrl.allReviews);

    return Column(
      children: [
        // Store filter bar
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: _green, size: 18),
              const SizedBox(width: 8),
              const Text('Store:',
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      _dark)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:        _bg,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: const Color(0xFFDDDACA)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value:       _filterStoreId,
                      isExpanded:  true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: _dark, size: 18),
                      style: const TextStyle(
                          fontSize: 13,
                          color:    _dark,
                          fontWeight: FontWeight.w500),
                      items: [
                        // "All Stores" option
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Stores'),
                        ),
                        // One item per store
                        ...stores.map((s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(
                            s.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      onChanged: (v) => setState(() => _filterStoreId = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${displayed.length}',
                  style: const TextStyle(
                      color:      _green,
                      fontSize:   12,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),

        // Reply filter bar
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.mark_chat_read_outlined,
                  color: _green, size: 16),
              const SizedBox(width: 8),
              const Text('Reply:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
              const SizedBox(width: 10),
              ...[
                (0, 'All'),
                (1, 'Not Replied'),
                (2, 'Replied'),
              ].map((entry) {
                final (val, label) = entry;
                final selected = _replyFilter == val;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _replyFilter = val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? _green
                            : _bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _green
                              : const Color(0xFFDDDACA),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _dark,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _orange))
              : displayed.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 60,
                              color: _dark.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(
                            _replyFilter == 1
                                ? 'No pending replies'
                                : _replyFilter == 2
                                    ? 'No replied reviews yet'
                                    : _filterStoreId == null
                                        ? 'No reviews yet'
                                        : 'No reviews for this store',
                            style: TextStyle(
                                color:    _dark.withValues(alpha: 0.4),
                                fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color:     _green,
                      onRefresh: () => ctrl.loadAllReviews(),
                      child: ListView.separated(
                        padding:          const EdgeInsets.all(16),
                        itemCount:        displayed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = displayed[index];
                          return _ReviewAdminCard(
                            review:   review,
                            onReply:  () =>
                                _showReplyDialog(context, review, ctrl),
                            onDelete: () =>
                                _confirmDelete(context, review, ctrl),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// Admin Review Card

class _ReviewAdminCard extends StatelessWidget {
  final ReviewModel  review;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  const _ReviewAdminCard({
    required this.review,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    [BoxShadow(
            color: _dark.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius:          18,
                  backgroundColor: _green.withValues(alpha: 0.12),
                  child: Text(
                    (review.userName?.isNotEmpty == true)
                        ? review.userName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color:      _green,
                        fontWeight: FontWeight.w800,
                        fontSize:   14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'Anonymous',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize:   14,
                            color:      _dark),
                      ),
                      Text(
                        review.storeName ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color:    _dark.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
                // Stars + date
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
                        style: TextStyle(
                            fontSize: 10,
                            color:    _dark.withValues(alpha: 0.35)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Comment
            if (review.comment.isNotEmpty)
              Text(review.comment,
                  style: TextStyle(
                      fontSize: 13,
                      color:    _dark.withValues(alpha: 0.8),
                      height:   1.4)),

            // Admin reply bubble
            if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        _green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: _green.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: _green, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(review.adminReply!,
                          style: const TextStyle(
                              fontSize: 12, color: _green)),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete button
                TextButton.icon(
                  onPressed: onDelete,
                  icon:  const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  label: const Text('Delete',
                      style: TextStyle(
                          color:      Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize:   13)),
                  style: TextButton.styleFrom(
                    padding:         const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    backgroundColor: Colors.red.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                // Reply button
                TextButton.icon(
                  onPressed: onReply,
                  icon: Icon(
                    review.adminReply != null
                        ? Icons.edit_outlined
                        : Icons.reply_rounded,
                    size:  16,
                    color: review.adminReply != null ? _orange : _green,
                  ),
                  label: Text(
                    review.adminReply != null ? 'Edit Reply' : 'Reply',
                    style: TextStyle(
                      color:      review.adminReply != null ? _orange : _green,
                      fontWeight: FontWeight.w700,
                      fontSize:   13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    backgroundColor: review.adminReply != null
                        ? _orange.withValues(alpha: 0.07)
                        : _green.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
