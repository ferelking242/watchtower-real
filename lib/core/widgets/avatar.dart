import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';

// ─── Simple avatar (no follow button) ────────────────────────────────────────
class WAvatar extends StatelessWidget {
  const WAvatar({
    super.key,
    required this.url,
    required this.size,
    this.isLive = false,
  });

  final String url;
  final double size;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    Widget img = ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _Fallback(size: size),
      ),
    );

    if (isLive) {
      img = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTokens.colorBrand, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _Fallback(size: size),
            ),
          ),
        ),
      );
    }
    return img;
  }
}

// ─── Avatar with animated follow (+) button ───────────────────────────────────
/// Shows a red + button below the avatar. On tap: + spins → ✓ → disappears.
class WAvatarFollow extends StatefulWidget {
  const WAvatarFollow({
    super.key,
    required this.url,
    required this.size,
    this.onProfileTap,
    this.onFollowed,
  });

  final String url;
  final double size;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFollowed;

  @override
  State<WAvatarFollow> createState() => _WAvatarFollowState();
}

enum _FollowPhase { plus, spinning, check, gone }

class _WAvatarFollowState extends State<WAvatarFollow>
    with TickerProviderStateMixin {
  _FollowPhase _phase = _FollowPhase.plus;

  late final AnimationController _rotCtrl;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
        value: 1.0);
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _follow() async {
    if (_phase != _FollowPhase.plus) return;
    setState(() => _phase = _FollowPhase.spinning);
    await _rotCtrl.forward();
    if (!mounted) return;
    setState(() => _phase = _FollowPhase.check);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() => _phase = _FollowPhase.gone);
    widget.onFollowed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final btnSize = widget.size * 0.46; // ~22px for size 48
    return GestureDetector(
      onTap: _phase == _FollowPhase.gone
          ? widget.onProfileTap
          : null,
      child: SizedBox(
        width: widget.size,
        // extra height for the badge below
        height: widget.size + (btnSize / 2) + 4,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── Avatar circle ──────────────────────────────────────
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.url,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _Fallback(size: widget.size),
              ),
            ),

            // ── Follow badge ───────────────────────────────────────
            if (_phase != _FollowPhase.gone)
              Positioned(
                bottom: 0,
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: GestureDetector(
                    onTap: _follow,
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFE2C55),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: _phase == _FollowPhase.check
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : RotationTransition(
                              turns: _rotCtrl,
                              child: const Icon(Icons.add_rounded,
                                  size: 15, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal fallback ────────────────────────────────────────────────────────
class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppTokens.colorBgCard,
      child: Icon(Icons.person_rounded,
          size: size * 0.6, color: AppTokens.colorTextSecondary),
    );
  }
}
