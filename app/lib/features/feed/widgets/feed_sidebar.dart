import 'package:flutter/material.dart';
import 'package:watchtower_real/core/widgets/avatar.dart';
import 'package:watchtower_real/features/feed/data/mock_feed.dart';
import 'package:watchtower_real/features/feed/providers/feed_provider.dart';

/// Format a count the TikTok way: 263 → "263", 5919 → "5.9K", 256K → "256K", 1.1M
String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}K';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

// ─── From mock FeedItem ───────────────────────────────────────────────────────
class FeedSidebar extends StatefulWidget {
  const FeedSidebar({
    super.key,
    required this.item,
    this.onComment,
    this.onProfile,
  });
  final FeedItem item;
  final VoidCallback? onComment;
  final VoidCallback? onProfile;

  @override
  State<FeedSidebar> createState() => _FeedSidebarState();
}

class _FeedSidebarState extends State<FeedSidebar>
    with TickerProviderStateMixin {
  bool _liked = false;
  bool _bookmarked = false;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SidebarLayout(
      avatar: widget.item.authorAvatar,
      liked: _liked,
      bookmarked: _bookmarked,
      likeScale: _likeScale,
      likes: widget.item.likes + (_liked ? 1 : 0),
      comments: widget.item.comments,
      bookmarks: widget.item.bookmarks,
      shares: widget.item.shares,
      onLike: () {
        setState(() => _liked = !_liked);
        _likeCtrl.forward(from: 0);
      },
      onBookmark: () => setState(() => _bookmarked = !_bookmarked),
      onComment: widget.onComment,
      onProfile: widget.onProfile,
    );
  }
}

// ─── From FeedItemModel (API) ─────────────────────────────────────────────────
class FeedSidebarFromModel extends StatefulWidget {
  const FeedSidebarFromModel({
    super.key,
    required this.item,
    this.onComment,
    this.onProfile,
  });
  final FeedItemModel item;
  final VoidCallback? onComment;
  final VoidCallback? onProfile;

  @override
  State<FeedSidebarFromModel> createState() => _FeedSidebarFromModelState();
}

class _FeedSidebarFromModelState extends State<FeedSidebarFromModel>
    with TickerProviderStateMixin {
  bool _liked = false;
  bool _bookmarked = false;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SidebarLayout(
      avatar: widget.item.authorAvatar,
      liked: _liked,
      bookmarked: _bookmarked,
      likeScale: _likeScale,
      likes: widget.item.likes + (_liked ? 1 : 0),
      comments: widget.item.comments,
      bookmarks: widget.item.bookmarks,
      shares: widget.item.shares,
      onLike: () {
        setState(() => _liked = !_liked);
        _likeCtrl.forward(from: 0);
      },
      onBookmark: () => setState(() => _bookmarked = !_bookmarked),
      onComment: widget.onComment,
      onProfile: widget.onProfile,
    );
  }
}

// ─── Shared layout ─────────────────────────────────────────────────────────────
class _SidebarLayout extends StatelessWidget {
  const _SidebarLayout({
    required this.avatar,
    required this.liked,
    required this.bookmarked,
    required this.likeScale,
    required this.likes,
    required this.comments,
    required this.bookmarks,
    required this.shares,
    required this.onLike,
    required this.onBookmark,
    this.onComment,
    this.onProfile,
  });

  final String avatar;
  final bool liked, bookmarked;
  final Animation<double> likeScale;
  final int likes, comments, bookmarks, shares;
  final VoidCallback onLike, onBookmark;
  final VoidCallback? onComment;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar + animated follow button ─────────────────────
        WAvatarFollow(
          url: avatar,
          size: 48,
          onProfileTap: onProfile,
        ),
        const SizedBox(height: 20),

        // ── Like ────────────────────────────────────────────────
        _SidebarBtn(
          label: _fmt(likes),
          onTap: onLike,
          child: AnimatedBuilder(
            animation: likeScale,
            builder: (_, __) => Transform.scale(
              scale: likeScale.value,
              child: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? const Color(0xFFFE2C55) : Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── Comment ─────────────────────────────────────────────
        _SidebarBtn(
          label: _fmt(comments),
          onTap: onComment ?? () {},
          child: const _CommentIcon(),
        ),
        const SizedBox(height: 18),

        // ── Bookmark ────────────────────────────────────────────
        _SidebarBtn(
          label: _fmt(bookmarks),
          onTap: onBookmark,
          child: Icon(
            bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 18),

        // ── Share ───────────────────────────────────────────────
        _SidebarBtn(
          label: _fmt(shares),
          onTap: () {},
          child: const Icon(
            Icons.reply_rounded,
            color: Colors.white,
            size: 32,
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }
}

// ─── Custom comment bubble ────────────────────────────────────────────────────
class _CommentIcon extends StatelessWidget {
  const _CommentIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(painter: _BubblePainter()),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    const r = 5.0;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..arcToPoint(Offset(w * 0.9, h * 0.5), radius: const Radius.circular(r * 2.5))
      ..arcToPoint(Offset(w * 0.62, h * 0.82), radius: const Radius.circular(r * 2.5))
      ..lineTo(w * 0.25, h * 0.92)
      ..lineTo(w * 0.38, h * 0.82)
      ..arcToPoint(Offset(w * 0.1, h * 0.5), radius: const Radius.circular(r * 2.5))
      ..arcToPoint(Offset(w * 0.5, h * 0.1), radius: const Radius.circular(r * 2.5))
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter _) => false;
}

// ─── Generic button ──────────────────────────────────────────────────────────
class _SidebarBtn extends StatelessWidget {
  const _SidebarBtn({
    required this.child,
    required this.label,
    required this.onTap,
  });
  final Widget child;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}
