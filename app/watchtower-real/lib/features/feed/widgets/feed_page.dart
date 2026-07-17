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
    // ── Contrôleur vidéo (léger, ne gère pas le cycle de vie du Player) ───────
    final controller = useMemoized(() => VideoController(player), [player]);

    // ── Play / pause selon la page active ────────────────────────────────────
    useEffect(() {
      if (isActive) {
        player.play();
      } else {
        player.pause();
        player.seek(Duration.zero);
      }
      return null;
    }, [isActive]);

    return GestureDetector(
      onTap: () {
        // Pause/play au tap (comportement TikTok)
        if (player.state.playing) {
          player.pause();
        } else {
          player.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond : vidéo ou thumbnail ───────────────────────────────────────
          _VideoBackground(
            item: item,
            controller: controller,
            player: player,
          ),

          // ── Dégradés ────────────────────────────────────────────────────────
          const _BottomGradient(),
          const _TopGradient(),

          // ── Overlay bas : infos + sidebar ───────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomOverlay(item: item),
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
