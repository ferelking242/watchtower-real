import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/tokens.dart';
import '../models/feed_item.dart';
import 'feed_sidebar.dart';
import 'feed_overlay_bottom.dart';

/// Un item du feed TikTok-style.
/// [isActive] : true quand c'est la page visible dans le PageView.
class FeedPage extends HookWidget {
  const FeedPage({super.key, required this.item, required this.isActive});

  final FeedItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    // ── Contrôleur vidéo ────────────────────────────────────────────────────
    final controller = useRef<VideoPlayerController?>(null);
    final initialized = useState(false);
    final hasError = useState(false);

    useEffect(() {
      final c = VideoPlayerController.networkUrl(Uri.parse(item.videoUrl));
      controller.value = c;
      c.initialize().then((_) {
        if (context.mounted) {
          c.setLooping(true);
          initialized.value = true;
          if (isActive) c.play();
        }
      }).catchError((_) {
        if (context.mounted) hasError.value = true;
      });
      return c.dispose;
    }, const []);

    // Play/pause quand la page change
    useEffect(() {
      final c = controller.value;
      if (c == null || !initialized.value) return null;
      if (isActive) {
        c.play();
      } else {
        c.pause();
        c.seekTo(Duration.zero);
      }
      return null;
    }, [isActive, initialized.value]);

    return GestureDetector(
      onTap: () {
        // Pause/play au tap (comportement TikTok)
        final c = controller.value;
        if (c == null || !initialized.value) return;
        if (c.value.isPlaying) {
          c.pause();
        } else {
          c.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond (thumbnail ou vidéo) ───────────────────────────────────
          _VideoBackground(
            item: item,
            controller: controller.value,
            initialized: initialized.value,
            hasError: hasError.value,
          ),

          // ── Dégradé bas ─────────────────────────────────────────────────
          const _BottomGradient(),

          // ── Dégradé haut (pour le header) ───────────────────────────────
          const _TopGradient(),

          // ── Overlay bas : info + sidebar ────────────────────────────────
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
// Fond : vidéo si disponible, thumbnail sinon
// ─────────────────────────────────────────────────────────────────────────────
class _VideoBackground extends StatelessWidget {
  const _VideoBackground({
    required this.item,
    required this.controller,
    required this.initialized,
    required this.hasError,
  });

  final FeedItem item;
  final VideoPlayerController? controller;
  final bool initialized;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (initialized && !hasError && controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller!.value.size.width,
          height: controller!.value.size.height,
          child: VideoPlayer(controller!),
        ),
      );
    }

    // Thumbnail de fallback
    return CachedNetworkImage(
      imageUrl: item.thumbnailUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: colorBgCard),
      errorWidget: (_, __, ___) => Container(
        color: colorBgCard,
        child: const Center(
          child: Icon(Icons.play_circle_outline_rounded,
              color: colorTextSecondary, size: 64),
        ),
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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 320,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
            stops: [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

class _TopGradient extends StatelessWidget {
  const _TopGradient();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 140,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x80000000), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay bas : colonne info + sidebar droite côte à côte
// ─────────────────────────────────────────────────────────────────────────────
class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    // Hauteur de la bottom nav
    const double navH = 72;
    return Padding(
      padding: EdgeInsets.only(
        bottom: navH + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Info gauche
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  space16, 0, space12, space16),
              child: FeedOverlayBottom(item: item),
            ),
          ),
          // Sidebar droite
          Padding(
            padding: const EdgeInsets.only(right: space12, bottom: space16),
            child: FeedSidebar(item: item),
          ),
        ],
      ),
    );
  }
}
