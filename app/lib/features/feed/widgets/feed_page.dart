import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/features/comments/comments_sheet.dart';
import 'package:watchtower_real/features/feed/providers/feed_provider.dart';
import 'package:watchtower_real/features/feed/widgets/feed_overlay_bottom.dart';
import 'package:watchtower_real/features/feed/widgets/feed_sidebar.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({
    super.key,
    required this.item,
    required this.isActive,
    this.preload = false,
  });
  final FeedItemModel item;
  final bool isActive;
  /// Preload video without playing (next item in feed)
  final bool preload;

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with TickerProviderStateMixin {
  // ── Video ──────────────────────────────────────────────────────────────────
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _playing = true;
  bool _resolving = false;

  // ── Photo carousel ─────────────────────────────────────────────────────────
  final PageController _photoCtrl = PageController();
  int _photoIndex = 0;

  // ── Gestures ───────────────────────────────────────────────────────────────
  Offset _tapPosition = Offset.zero;
  bool _speedMode = false;
  bool _showInfoBox = false;

  // ── 2× speed indicator anim ────────────────────────────────────────────────
  late final AnimationController _speedAnim;

  // ── Swipe → profile animation ──────────────────────────────────────────────
  double _swipeDx = 0;
  double _swipeSnapStart = 0;
  late final AnimationController _swipeSnapAnim;

  @override
  void initState() {
    super.initState();
    _speedAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _swipeSnapAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250))
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          _swipeDx = _swipeSnapStart *
              (1 - Curves.easeOut.transform(_swipeSnapAnim.value));
        });
      });

    // Resolve & init for active page OR next page (preload)
    if (!widget.item.isPhoto && (widget.isActive || widget.preload)) {
      _resolveAndInit();
    }
  }

  // ── Video init ─────────────────────────────────────────────────────────────
  Future<void> _resolveAndInit() async {
    String? url = widget.item.videoUrl;
    if (url == null && !_resolving) {
      setState(() => _resolving = true);
      url = await ref.read(feedProvider.notifier).resolveVideoUrl(widget.item);
      if (!mounted) return;
      setState(() => _resolving = false);
    }
    if (url == null) return;
    await _initPlayer(url);
  }

  Future<void> _initPlayer(String url) async {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(1.0);
      // Play only if active; preloaded pages stay paused
      if (widget.isActive && mounted) ctrl.play();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(FeedPage old) {
    super.didUpdateWidget(old);

    // Start preloading when this page becomes the next one
    if (!old.preload && widget.preload && !_initialized && !_resolving) {
      if (!widget.item.isPhoto) _resolveAndInit();
    }

    if (widget.isActive != old.isActive) {
      if (widget.isActive) {
        if (!_initialized && !_resolving && !widget.item.isPhoto) {
          _resolveAndInit();
        } else {
          _ctrl?.play();
        }
        if (mounted) setState(() => _playing = true);
      } else {
        _ctrl?.pause();
        if (_speedMode) _exitSpeedMode();
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _photoCtrl.dispose();
    _speedAnim.dispose();
    _swipeSnapAnim.dispose();
    super.dispose();
  }

  // ── Playback helpers ───────────────────────────────────────────────────────
  void _togglePlay() {
    if (_ctrl == null) return;
    setState(() {
      _playing = !_playing;
      _playing ? _ctrl!.play() : _ctrl!.pause();
    });
  }

  void _enterSpeedMode() {
    if (_speedMode) return;
    _speedMode = true;
    _speedAnim.forward(from: 0);
    _ctrl?.setPlaybackSpeed(2.0);
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _exitSpeedMode() {
    if (!_speedMode) return;
    _speedMode = false;
    _ctrl?.setPlaybackSpeed(1.0);
    setState(() {});
  }

  // ── Gesture handlers ───────────────────────────────────────────────────────
  void _onTapDown(TapDownDetails d) => _tapPosition = d.localPosition;

  void _onTap() {
    if (widget.item.isPhoto) return;
    _togglePlay();
  }

  void _onLongPressStart(LongPressStartDetails d) {
    final w = context.size?.width ?? 400;
    final x = d.localPosition.dx;
    if (x < w / 3 || x > w * 2 / 3) {
      _enterSpeedMode();
    } else {
      HapticFeedback.selectionClick();
      setState(() => _showInfoBox = true);
    }
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _exitSpeedMode();
    setState(() => _showInfoBox = false);
  }

  void _onLongPressCancel() {
    _exitSpeedMode();
    setState(() => _showInfoBox = false);
  }

  // ── Swipe left → profile (progressive animation) ───────────────────────────
  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    // Only track leftward drags
    if (d.delta.dx < 0 || _swipeDx < 0) {
      _swipeSnapAnim.stop();
      final sw = context.size?.width ?? 400.0;
      setState(() {
        _swipeDx = (_swipeDx + d.delta.dx).clamp(-sw, 0.0);
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    final sw = context.size?.width ?? 400.0;
    if (_swipeDx < -(sw * 0.35) || (d.primaryVelocity ?? 0) < -500) {
      final uid = widget.item.author.replaceAll('@', '');
      setState(() => _swipeDx = 0);
      context.push('/profile/$uid');
    } else {
      // Snap back with animation
      _swipeSnapStart = _swipeDx;
      _swipeSnapAnim.forward(from: 0);
    }
  }

  // ── Open comments ──────────────────────────────────────────────────────────
  void _openComments() {
    showCommentsSheet(context, commentCount: widget.item.comments);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTap: _onTap,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background (video or image carousel) ────────────────
          widget.item.isPhoto
              ? _buildPhotoBackground()
              : _buildVideoBackground(),

          // ── Gradients ───────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 160,
            child: _gradient(Alignment.topCenter, Alignment.bottomCenter,
                const Color(0xAA000000)),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 280,
            child: _gradient(Alignment.bottomCenter, Alignment.topCenter,
                const Color(0xCC000000)),
          ),

          // ── Loading / pause ─────────────────────────────────────
          if (!widget.item.isPhoto) ...[
            if (_resolving)
              const Center(
                child: CircularProgressIndicator(
                    color: AppTokens.colorBrand, strokeWidth: 2),
              )
            else if (!_playing && _initialized)
              const Center(
                child: Icon(Icons.play_circle_filled,
                    color: Colors.white54, size: 64),
              ),
          ],

          // ── 2× speed overlay ────────────────────────────────────
          if (_speedMode)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _speedAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fast_forward_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('2×',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Info popup (long press center) ───────────────────────
          if (_showInfoBox)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.author,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // ── Photo dots (bottom center) ───────────────────────────
          if (widget.item.isPhoto && widget.item.photoCount > 1)
            Positioned(
              bottom: 84,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.item.photoCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _photoIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _photoIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // ── Photo counter (top left, below header) ──────────────
          if (widget.item.isPhoto && widget.item.photoCount > 1)
            Positioned(
              top: 56,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_photoIndex + 1}/${widget.item.photoCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ── Sidebar ─────────────────────────────────────────────
          Positioned(
            right: AppTokens.space12,
            bottom: 92,
            child: FeedSidebarFromModel(
              item: widget.item,
              onComment: _openComments,
              onProfile: () {
                final uid = widget.item.author.replaceAll('@', '');
                context.push('/profile/$uid');
              },
            ),
          ),

          // ── Bottom overlay ──────────────────────────────────────
          Positioned(
            left: AppTokens.space16,
            right: 88,
            bottom: 92,
            child: FeedOverlayBottomFromModel(item: widget.item),
          ),

          // ── Progress bar (video only) ───────────────────────────
          if (_initialized && _ctrl != null && !widget.item.isPhoto)
            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: _ThinProgressBar(
                controller: _ctrl!,
                isPlaying: _playing,
              ),
            ),

          // ── Profile swipe-in preview ─────────────────────────────
          if (_swipeDx < 0) ...[
            // dim current content proportionally
            Opacity(
              opacity: (-_swipeDx / sw) * 0.35,
              child: Container(color: Colors.black),
            ),
            // profile card slides in from the right
            Transform.translate(
              offset: Offset(sw + _swipeDx, 0),
              child: _ProfileSwipePreview(
                author: widget.item.author,
                avatarUrl: widget.item.authorAvatar,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Photo carousel builder ─────────────────────────────────────────────────
  Widget _buildPhotoBackground() {
    final urls = widget.item.photoUrls.isNotEmpty
        ? widget.item.photoUrls
        : [widget.item.thumbnailUrl];

    if (urls.length == 1) {
      return Image.network(urls.first, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppTokens.colorBgSurface));
    }

    return PageView.builder(
      controller: _photoCtrl,
      itemCount: urls.length,
      onPageChanged: (i) => setState(() => _photoIndex = i),
      itemBuilder: (_, i) => Image.network(
        urls[i],
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: AppTokens.colorBgSurface),
      ),
    );
  }

  // ── Video background builder ───────────────────────────────────────────────
  Widget _buildVideoBackground() {
    if (_initialized && _ctrl != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _ctrl!.value.size.width,
          height: _ctrl!.value.size.height,
          child: VideoPlayer(_ctrl!),
        ),
      );
    }
    final thumb = widget.item.thumbnailUrl;
    if (thumb.isNotEmpty) {
      return Image.network(thumb, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: AppTokens.colorBgSurface));
    }
    return Container(color: AppTokens.colorBgSurface);
  }

  Widget _gradient(Alignment begin, Alignment end, Color startColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [startColor, Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Profile swipe preview ────────────────────────────────────────────────────
class _ProfileSwipePreview extends StatelessWidget {
  const _ProfileSwipePreview({
    required this.author,
    required this.avatarUrl,
  });
  final String author;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white12,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white54, size: 48)
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            author,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Voir le profil →',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Thin white scrubable progress bar ───────────────────────────────────────
class _ThinProgressBar extends StatefulWidget {
  const _ThinProgressBar({
    required this.controller,
    required this.isPlaying,
  });
  final VideoPlayerController controller;
  final bool isPlaying;

  @override
  State<_ThinProgressBar> createState() => _ThinProgressBarState();
}

class _ThinProgressBarState extends State<_ThinProgressBar> {
  bool _dragging = false;
  double _dragFraction = 0;

  void _seek(double fraction) {
    final dur = widget.controller.value.duration;
    widget.controller.seekTo(dur * fraction.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (_, value, __) {
        final dur = value.duration.inMilliseconds;
        final fraction = _dragging
            ? _dragFraction
            : (dur > 0 ? value.position.inMilliseconds / dur : 0.0);

        final paused = !widget.isPlaying;
        // Dot: small when playing, bigger when paused or dragging
        final dotSize = (_dragging || paused) ? 14.0 : 8.0;
        final showShadow = _dragging || paused;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            setState(() {
              _dragging = true;
              _dragFraction =
                  (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            setState(() {
              _dragFraction =
                  (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            _seek(_dragFraction);
            setState(() => _dragging = false);
          },
          // LayoutBuilder wraps the Stack so we know the real width
          // for positioning the dot — Positioned inside Stack needs explicit coords.
          child: SizedBox(
            height: 28,
            child: LayoutBuilder(builder: (_, constraints) {
              final maxW = constraints.maxWidth;
              final filled = (fraction * maxW).clamp(0.0, maxW);
              // Dot left edge: centred on the playhead, clamped inside track
              final dotLeft = (filled - dotSize / 2).clamp(0.0, maxW - dotSize);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Track (grey background) — bottom of hit area ──
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(height: 2, color: Colors.white24),
                  ),
                  // ── Filled portion ───────────────────────────────
                  Positioned(
                    bottom: 0,
                    left: 0,
                    width: filled,
                    child: Container(height: 2, color: Colors.white),
                  ),
                  // ── Playhead dot — always visible ────────────────
                  Positioned(
                    bottom: -(dotSize / 2 - 1),
                    left: dotLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: showShadow
                            ? const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
