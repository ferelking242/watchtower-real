import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/tokens.dart';
import '../models/feed_item.dart';

class FeedSidebar extends StatefulWidget {
  const FeedSidebar({super.key, required this.item});

  final FeedItem item;

  @override
  State<FeedSidebar> createState() => _FeedSidebarState();
}

class _FeedSidebarState extends State<FeedSidebar> {
  bool _liked = false;
  bool _bookmarked = false;

  void _toggleLike() => setState(() => _liked = !_liked);
  void _toggleBookmark() => setState(() => _bookmarked = !_bookmarked);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + bouton Follow
        _AvatarWithFollow(avatarUrl: widget.item.authorAvatar),
        const SizedBox(height: space24),

        // Like
        _ActionButton(
          icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _liked ? colorLike : colorTextPrimary,
          label: widget.item.formattedLikes,
          onTap: _toggleLike,
          animated: true,
          isActive: _liked,
        ),
        const SizedBox(height: space20),

        // Commentaires
        _ActionButton(
          icon: Icons.chat_bubble_rounded,
          label: widget.item.formattedComments,
          onTap: () {},
        ),
        const SizedBox(height: space20),

        // Sauvegarder
        _ActionButton(
          icon: _bookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          iconColor: _bookmarked ? colorBrandCyan : colorTextPrimary,
          label: widget.item.formattedBookmarks,
          onTap: _toggleBookmark,
        ),
        const SizedBox(height: space20),

        // Partager
        _ActionButton(
          icon: Icons.reply_rounded, // miroir horizontal = partager TikTok
          label: widget.item.formattedShares,
          onTap: () {},
          iconMirror: true,
        ),
        const SizedBox(height: space20),

        // Disque tournant (son)
        _SpinningDisc(avatarUrl: widget.item.authorAvatar),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar + bouton +
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarWithFollow extends StatelessWidget {
  const _AvatarWithFollow({required this.avatarUrl});
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorTextPrimary, width: 1.5),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: colorBgCard),
                errorWidget: (_, __, ___) => Container(
                  color: colorBgCard,
                  child: const Icon(Icons.person_rounded,
                      color: colorTextSecondary, size: 24),
                ),
              ),
            ),
          ),
          // Bouton +
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: colorBrand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded,
                    color: colorTextPrimary, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton d'action (icône + compteur)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = colorTextPrimary,
    this.animated = false,
    this.isActive = false,
    this.iconMirror = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final bool animated;
  final bool isActive;
  final bool iconMirror;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: durationLike,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.35, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.animated) _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(widget.icon, color: widget.iconColor, size: 30);

    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        children: [
          if (widget.animated)
            ScaleTransition(
              scale: _scale,
              child: widget.iconMirror
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.1416),
                      child: iconWidget,
                    )
                  : iconWidget,
            )
          else
            widget.iconMirror
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.1416),
                    child: iconWidget,
                  )
                : iconWidget,
          const SizedBox(height: 3),
          Text(
            widget.label,
            style: const TextStyle(
              color: colorTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disque tournant (son)
// ─────────────────────────────────────────────────────────────────────────────
class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc({required this.avatarUrl});
  final String avatarUrl;

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF444444), width: 8),
          color: Colors.black,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: widget.avatarUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF333333)),
            errorWidget: (_, __, ___) => const Icon(Icons.music_note_rounded,
                color: colorTextSecondary, size: 16),
          ),
        ),
      ),
    );
  }
}
