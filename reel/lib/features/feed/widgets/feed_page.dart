import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/theme/tokens.dart';
import '../models/feed_item.dart';
import 'feed_sidebar.dart';
import 'feed_overlay_bottom.dart';

/// Un item du feed TikTok-style.
///
/// [player]   : Player media_kit pré-créé et déjà ouvert par le pool du feed.
/// [isActive] : true quand c'est la page visible dans le PageView.
class FeedPage extends HookWidget {
  const FeedPage({
    super.key,
    required this.item,
    required this.player,
    required this.isActive,
  });

  final FeedItem item;
  final Player player;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    // ── Contrôleur vidéo ────────────────────────────────────────────────────
    final controller = useMemoized(() => VideoController(player), [player]);

    // ── Long-press pause ────────────────────────────────────────────────────
    final pausedByLongPress = useState(false);

    // ── Double-tap like : position + animation ───────────────────────────────
    final heartPosition = useState<Offset?>(null);
    final heartCtrl = useAnimationController(
      duration: const Duration(milliseconds: 700),
    );

    // ── Play / pause selon la page active ────────────────────────────────────
    useEffect(() {
      if (isActive) {
        player.play();
      } else {
        player.pause();
        player.seek(Duration.zero);
        pausedByLongPress.value = false;
      }
      return null;
    }, [isActive]);

    return GestureDetector(
      // ── Tap simple : play / pause (ignoré si long-press actif) ─────────────
      onTap: () {
        if (pausedByLongPress.value) return;
        if (player.state.playing) {
          player.pause();
        } else {
          player.play();
        }
      },

      // ── Double-tap : animation cœur ─────────────────────────────────────────
      onDoubleTapDown: (details) {
        heartPosition.value = details.localPosition;
      },
      onDoubleTap: () {
        heartCtrl.forward(from: 0);
      },

      // ── Long-press : pause pendant le hold ──────────────────────────────────
      onLongPressStart: (_) {
        if (!isActive) return;
        player.pause();
        pausedByLongPress.value = true;
      },
      onLongPressEnd: (_) {
        if (!isActive) return;
        player.play();
        pausedByLongPress.value = false;
      },
      onLongPressCancel: () {
        if (!isActive || !pausedByLongPress.value) return;
        player.play();
        pausedByLongPress.value = false;
      },

      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond : vidéo ou thumbnail ────────────────────────────────────────
          _VideoBackground(
            item: item,
            controller: controller,
            player: player,
          ),

          // ── Dégradés ─────────────────────────────────────────────────────────
          const _BottomGradient(),
          const _TopGradient(),

          // ── Overlay bas : infos + sidebar ────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomOverlay(item: item),
          ),

          // ── Progress bar (trait fin en bas, style TikTok) ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _VideoProgressBar(player: player),
          ),

          // ── Animation cœur double-tap ─────────────────────────────────────────
          if (heartPosition.value != null)
            Positioned(
              left: heartPosition.value!.dx - 55,
              top: heartPosition.value!.dy - 55,
              child: IgnorePointer(
                child: _HeartBurst(controller: heartCtrl),
              ),
            ),

          // ── Indicateur pause (long-press) ─────────────────────────────────────
          if (pausedByLongPress.value)
            const Center(child: _PauseIndicator()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress bar vidéo (thin bottom, style TikTok)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoProgressBar extends HookWidget {
  const _VideoProgressBar({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, posSnap) {
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          builder: (context, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final progress =
                dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

            return SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3,
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation cœur (double-tap like)
// ─────────────────────────────────────────────────────────────────────────────
class _HeartBurst extends HookWidget {
  const _HeartBurst({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // Scale : monte en flèche puis revient élastique
    final scale = useMemoized(
      () => TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.3, end: 1.4)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60,
        ),
      ]).animate(controller),
      [controller],
    );

    // Opacité : reste à 1 jusqu'à 60%, puis disparaît
    final opacity = useMemoized(
      () => TweenSequence<double>([
        TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
      ]).animate(controller),
      [controller],
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        if (controller.value == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: opacity.value,
          child: Transform.scale(
            scale: scale.value,
            child: const SizedBox(
              width: 110,
              height: 110,
              child: Icon(
                Icons.favorite_rounded,
                color: colorLike,
                size: 110,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicateur "⏸ PAUSÉ" (long-press)
// ─────────────────────────────────────────────────────────────────────────────
class _PauseIndicator extends StatelessWidget {
  const _PauseIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_rounded, color: Colors.white, size: 22),
          SizedBox(width: 6),
          Text(
            'Maintenir pour rester en pause',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fond : vidéo (media_kit) ou thumbnail (fallback)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoBackground extends HookWidget {
  const _VideoBackground({
    required this.item,
    required this.controller,
    required this.player,
  });

  final FeedItem item;
  final VideoController controller;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final hasVideo = item.videoUrl.isNotEmpty;

    if (!hasVideo) {
      return _Thumbnail(url: item.thumbnailUrl);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail visible tant que la vidéo n'est pas prête
        _Thumbnail(url: item.thumbnailUrl),

        // Vidéo media_kit
        StreamBuilder<bool>(
          stream: player.stream.buffering,
          builder: (context, snap) {
            final buffering = snap.data ?? true;
            return AnimatedOpacity(
              opacity: buffering ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                fill: Colors.transparent,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return Container(color: colorBgCard);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: colorBgCard),
      errorWidget: (_, __, ___) => Container(color: colorBgCard),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay bas (titre + sidebar)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FeedOverlayBottom(item: item),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: FeedSidebar(item: item),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dégradés
// ─────────────────────────────────────────────────────────────────────────────
class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
    );
  }
}

class _TopGradient extends StatelessWidget {
  const _TopGradient();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x88000000), Colors.transparent],
          ),
        ),
        child: SizedBox(height: 120, width: double.infinity),
      ),
    );
  }
}
