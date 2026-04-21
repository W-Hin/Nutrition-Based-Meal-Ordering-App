import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/review_controller.dart';
import '../../model/review_model.dart';
import '../../service/supabase_conn.dart';

class ReviewWritePage extends StatefulWidget {
  final int    orderId;
  final String storeId;
  final String storeName;
  final ReviewModel? existing;

  const ReviewWritePage({
    super.key,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    this.existing,
  });

  @override
  State<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends State<ReviewWritePage>
    with SingleTickerProviderStateMixin {
  // Palette
  static const _forest  = Color(0xFF1E4620);
  static const _lime    = Color(0xFFB5CC30);
  static const _orange  = Color(0xFFD95B2B);
  static const _bg      = Color(0xFFF3F2EC);
  static const _card    = Colors.white;

  late int    _rating;
  late final TextEditingController _commentCtrl;
  late AnimationController _starAnim;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  static const _labels = ['', 'Terrible 😞', 'Poor 😕', 'Okay 😐', 'Good 😊', 'Excellent! 🤩'];

  @override
  void initState() {
    super.initState();
    _rating      = widget.existing?.rating ?? 0;
    _commentCtrl = TextEditingController(text: widget.existing?.comment ?? '');
    _starAnim    = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    if (_rating > 0) _starAnim.forward();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _starAnim.dispose();
    super.dispose();
  }

  void _selectStar(int star) {
    setState(() => _rating = star);
    _starAnim.reset();
    _starAnim.forward();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _shake();
      return;
    }

    setState(() => _submitting = true);
    final ctrl      = context.read<ReviewController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    bool ok;

    if (_isEdit) {
      if (widget.existing!.id == null) {
        setState(() => _submitting = false);
        return;
      }
      ok = await ctrl.updateReview(
        widget.existing!.id!,
        _rating,
        _commentCtrl.text.trim(),
      );
    } else {
      final uid = supabase.auth.currentUser?.id ?? '';
      if (uid.isEmpty) {
        setState(() => _submitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You must be logged in to submit a review.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      ok = await ctrl.submitReview(ReviewModel(
        userId:  uid,
        storeId: widget.storeId,
        orderId: widget.orderId,
        rating:  _rating,
        comment: _commentCtrl.text.trim(),
      ));
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(_isEdit ? 'Review updated!' : 'Review submitted!'),
        ]),
        backgroundColor: _forest,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(ctrl.errorMessage.isNotEmpty
            ? ctrl.errorMessage
            : 'Something went wrong. Please try again.'),
        backgroundColor: Colors.red.shade700,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _shake() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.star_border_rounded, color: Colors.amber, size: 18),
        SizedBox(width: 8),
        Text('Please tap a star to rate your experience.'),
      ]),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 160,
            floating:   false,
            pinned:     true,
            backgroundColor: _forest,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Text(
                _isEdit ? 'Edit Your Review' : 'Write a Review',
                style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize:   18,
                  letterSpacing: 0.3,
                ),
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
                    // Decorative circles
                    Positioned(
                      top: -30, right: -30,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20, left: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lime.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Info Card
                  _StoreCard(
                    storeName: widget.storeName,
                    orderId:   widget.orderId,
                  ),
                  const SizedBox(height: 24),

                  // Star Rating Card
                  _buildRatingCard(),
                  const SizedBox(height: 20),

                  // Comment Card
                  _buildCommentCard(),
                  const SizedBox(height: 28),

                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color:        _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'How would you rate it?',
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w800,
              color:      Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star    = i + 1;
              final filled  = star <= _rating;
              return GestureDetector(
                onTap: () => _selectStar(star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve:    Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  transform: filled
                      ? (Matrix4.identity()..scale(1.15))
                      : Matrix4.identity(),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? Colors.amber.shade400 : const Color(0xFFDDDDDD),
                    size:  46,
                  ),
                ),
              );
            }),
          ),
          // Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _rating > 0
                ? Padding(
                    key: ValueKey(_rating),
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _labels[_rating],
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize:   13,
                        ),
                      ),
                    ),
                  )
                : const Padding(
                    key: ValueKey(0),
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Tap a star to rate',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFAAAAAA)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      decoration: BoxDecoration(
        color:        _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:        _forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: _forest, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Share your thoughts',
                  style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Optional',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
          TextField(
            controller: _commentCtrl,
            maxLines:   6,
            style: const TextStyle(fontSize: 14, height: 1.6),
            decoration: const InputDecoration(
              hintText: 'Tell others what you loved (or didn\'t)…',
              hintStyle: TextStyle(
                  color: Color(0xFFBBBBBB), fontSize: 13),
              border:         InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
          // Tip row
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        _orange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: _orange, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Was the food fresh? Was delivery on time? Your feedback helps others!',
                    style: TextStyle(
                      fontSize: 11,
                      color:    _orange.withValues(alpha: 0.85),
                      height:   1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD95B2B), Color(0xFFE8732A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      _orange.withValues(alpha: 0.4),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:        _submitting ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: _submitting
                ? const SizedBox(
                    width:  22,
                    height: 22,
                    child:  CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEdit
                            ? Icons.check_circle_outline_rounded
                            : Icons.send_rounded,
                        color: Colors.white, size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEdit ? 'Save Changes' : 'Post Review',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize:   16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Store Card

class _StoreCard extends StatelessWidget {
  final String storeName;
  final int    orderId;

  static const _forest = Color(0xFF1E4620);

  const _StoreCard({required this.storeName, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _forest,
            const Color(0xFF2E6B30),
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      _forest.withValues(alpha: 0.35),
            blurRadius: 16,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  50,
            height: 50,
            decoration: BoxDecoration(
              color:        Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.store_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize:   15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Order #$orderId',
                    style: const TextStyle(
                        color:    Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded,
              color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}
