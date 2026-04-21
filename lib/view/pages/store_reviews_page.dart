import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/review_controller.dart';
import '../../model/review_model.dart';
import '../../service/supabase_conn.dart';
import 'review_write_page.dart';

class StoreReviewsPage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreReviewsPage({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreReviewsPage> createState() => _StoreReviewsPageState();
}

class _StoreReviewsPageState extends State<StoreReviewsPage> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const _forest = Color(0xFF1E4620);
  static const _lime   = Color(0xFFB5CC30);
  static const _bg     = Color(0xFFF3F2EC);

  Map<String, dynamic> _stats = {
    'average': 0.0,
    'count':   0,
    'distribution': <int, int>{},
  };
  bool _statsLoading = true;

  String get _currentUid => supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final ctrl = context.read<ReviewController>();
    await Future.wait([
      ctrl.loadStoreReviews(widget.storeId),
      _loadStats(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    final ctrl  = context.read<ReviewController>();
    final stats = await ctrl.fetchStoreRatingStats(widget.storeId);
    if (mounted) setState(() { _stats = stats; _statsLoading = false; });
  }

  Future<void> _confirmDelete(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color:        Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Review?',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize:   18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your review will be permanently removed.\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:    Color(0xFF8A8A8A),
                    fontSize: 13,
                    height:   1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B6B6B),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation:       0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Delete',
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
    if (confirmed != true || !mounted) return;
    if (review.id == null) return;
    final ctrl      = context.read<ReviewController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ctrl.deleteReview(review.id!);
    if (!mounted) return;
    if (ok) {
      await _loadStats();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Review deleted.'),
        ]),
        behavior:        SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _editReview(ReviewModel review) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewWritePage(
          orderId:   review.orderId,
          storeId:   widget.storeId,
          storeName: widget.storeName,
          existing:  review,
        ),
      ),
    );
    if (result == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl    = context.watch<ReviewController>();
    final reviews = ctrl.storeReviews;

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Gradient SliverAppBar ─────────────────────────────────────
          SliverAppBar(
            pinned:          true,
            expandedHeight:  130,
            backgroundColor: _forest,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.storeName,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize:   16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(
                        color:    Colors.white60,
                        fontSize: 11),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [Color(0xFF1E4620), Color(0xFF2E6B30)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30, left: 60,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lime.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color:     _forest,
          onRefresh: _load,
          child: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _forest))
              : CustomScrollView(
                  slivers: [
                    // ── Rating Summary ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: _RatingSummaryCard(
                        stats:   _stats,
                        loading: _statsLoading,
                      ),
                    ),

                    if (reviews.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color:        _forest.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.rate_review_outlined,
                                    size: 38, color: _forest),
                              ),
                              const SizedBox(height: 16),
                              const Text('No reviews yet.',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize:   16,
                                      color:      Color(0xFF333333))),
                              const SizedBox(height: 6),
                              const Text(
                                'Complete an order to leave the first review!',
                                style: TextStyle(
                                    color:    Color(0xFFAAAAAA),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final review  = reviews[i];
                              final isOwner = review.userId == _currentUid;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _ReviewCard(
                                  review:   review,
                                  isOwner:  isOwner,
                                  onEdit:   () => _editReview(review),
                                  onDelete: () => _confirmDelete(review),
                                ),
                              );
                            },
                            childCount: reviews.length,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Rating Summary Card ───────────────────────────────────────────────────────

class _RatingSummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;

  static const _forest = Color(0xFF1E4620);

  const _RatingSummaryCard({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final avg   = (stats['average'] as double?) ?? 0.0;
    final count = (stats['count']   as int?)    ?? 0;
    final dist  = (stats['distribution'] as Map<int, int>?) ?? {};

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset:     const Offset(0, 5),
          ),
        ],
      ),
      child: loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child:   CircularProgressIndicator(
                    color: _forest, strokeWidth: 2.5),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left — big score
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFF1E4620), Color(0xFF4CAF50)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ).createShader(r),
                      child: Text(
                        avg == 0 ? '-' : avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize:   62,
                          fontWeight: FontWeight.w900,
                          color:      Colors.white,
                          height:     1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => Icon(
                        i < avg.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber.shade400,
                        size:  17,
                      )),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color:        _forest.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count Review${count != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      _forest,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 24),
                const VerticalDivider(width: 1, color: Color(0xFFEEEBDE)),
                const SizedBox(width: 24),

                // Right — distribution bars
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final star      = 5 - i;
                      final starCount = dist[star] ?? 0;
                      final fraction  = count > 0
                          ? (starCount / count).clamp(0.0, 1.0)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              child: Text('$star',
                                  style: const TextStyle(
                                      fontSize:   11,
                                      fontWeight: FontWeight.w700,
                                      color:      Color(0xFF6B6B6B))),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: fraction),
                                  duration: const Duration(milliseconds: 800),
                                  curve:    Curves.easeOutCubic,
                                  builder: (_, value, __) =>
                                      LinearProgressIndicator(
                                    value:           value,
                                    minHeight:       8,
                                    backgroundColor: const Color(0xFFF0EFE8),
                                    valueColor: AlwaysStoppedAnimation(
                                      fraction > 0.5
                                          ? _forest
                                          : const Color(0xFF5A9E5D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 22,
                              child: Text(
                                '$starCount',
                                style: const TextStyle(
                                    fontSize:   10,
                                    color:      Color(0xFF8A8A8A),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel  review;
  final bool         isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _forest = Color(0xFF1E4620);
  static const _dark   = Color(0xFF1A1A1A);

  const _ReviewCard({
    required this.review,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365)  return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30)   return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1)   return '${diff.inDays}d ago';
    if (diff.inHours >= 1)  return '${diff.inHours}h ago';
    if (diff.inMinutes > 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Color _ratingColor(int r) {
    if (r >= 4) return const Color(0xFF1E4620);
    if (r == 3) return const Color(0xFF8A6900);
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (review.userName?.isNotEmpty == true)
        ? review.userName!
        : 'Anonymous';
    final parts    = displayName.trim().split(' ');
    final initials = parts.map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final color    = _ratingColor(review.rating);

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                Row(
                  children: [
                    // Avatar
                    Container(
                      width:  44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.7),
                            color,
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize:   15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize:   14,
                              color:      _dark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              // Stars
                              ...List.generate(5, (i) => Icon(
                                i < review.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber.shade400,
                                size:  14,
                              )),
                              const SizedBox(width: 8),
                              // Rating badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:        color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${review.rating}.0',
                                  style: TextStyle(
                                    color:      color,
                                    fontSize:   10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Owner menu / timestamp
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isOwner)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 20, color: Color(0xFF8A8A8A)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined,
                                      size: 17, color: _forest),
                                  const SizedBox(width: 8),
                                  const Text('Edit'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      size: 17, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                            onSelected: (v) =>
                                v == 'edit' ? onEdit() : onDelete(),
                          ),
                        Text(
                          _timeAgo(review.createdAt?.toLocal()),
                          style: const TextStyle(
                              fontSize: 10,
                              color:    Color(0xFFAAAAAA)),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Comment ────────────────────────────────────────────
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    review.comment,
                    style: TextStyle(
                      fontSize: 13,
                      color:    _dark.withValues(alpha: 0.75),
                      height:   1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Admin Reply Strip ──────────────────────────────────────────
          if (review.adminReply != null && review.adminReply!.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color:        const Color(0xFF1E4620).withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF1E4620).withValues(alpha: 0.08),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width:  30,
                    height: 30,
                    decoration: BoxDecoration(
                      color:        _forest.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: _forest, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NuBurn Response',
                          style: TextStyle(
                            color:      _forest,
                            fontWeight: FontWeight.w800,
                            fontSize:   11,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          review.adminReply!,
                          style: TextStyle(
                            fontSize: 12,
                            color:    _forest.withValues(alpha: 0.8),
                            height:   1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
