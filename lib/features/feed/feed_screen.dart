import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/theme/tokens.dart';
import 'models/feed_item.dart';
import 'providers/feed_provider.dart';
import 'package:go_router/go_router.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_page.dart';

/// Nombre de Players gardés en vie autour de l'index actif.
/// Ex: _kPoolRadius = 1 → on garde [i-1, i, i+1].
const int _kPoolRadius = 1;

class FeedScreen extends HookConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync   = ref.watch(feedItemsProvider);
    final currentIdx  = ref.watch(currentFeedIndexProvider);
    final pageCtrl    = usePageController();

    // ── Pool de Players (map index → Player) ──────────────────────────────────
    // On garde alive les players dans [currentIdx-radius, currentIdx+radius].
    final pool = useRef<Map<int, Player>>({});

    // Barre de statut blanche sur fond noir
    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
      return null;
    }, const []);

    // ── Gère le pool à chaque changement d'index ou de liste ─────────────────
    useEffect(() {
      final items = feedAsync.asData?.value;
      if (items == null || items.isEmpty) return null;

      final alive = <int>{};
      for (int i = currentIdx - _kPoolRadius;
          i <= currentIdx + _kPoolRadius;
          i++) {
        if (i < 0 || i >= items.length) continue;
        alive.add(i);

        // Créer et ouvrir le player s'il n'existe pas encore
        if (!pool.value.containsKey(i)) {
          final p = Player();
          final url = items[i].videoUrl;
          if (url.isNotEmpty) {
            p.open(Media(url), play: false);
          }
          pool.value[i] = p;
        }
      }

      // Disposer les players hors de la fenêtre
      final toDispose = pool.value.keys.toList()
        ..retainWhere((k) => !alive.contains(k));
      for (final k in toDispose) {
        pool.value.remove(k)?.dispose();
      }

      return null;
    }, [currentIdx, feedAsync]);

    // ── Dispose tout à la destruction du widget ───────────────────────────────
    useEffect(() {
      return () {
        for (final p in pool.value.values) {
          p.dispose();
        }
        pool.value.clear();
      };
    }, const []);

    return Scaffold(
      backgroundColor: colorBgBase,
      extendBody: true,
      body: feedAsync.when(
        loading: () => const _FeedSkeleton(),
        error:   (e, _) => _FeedError(message: e.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const _FeedEmpty();
          }

          return Stack(
            children: [
              // ── PageView vertical ──────────────────────────────────────────
              PageView.builder(
                controller:      pageCtrl,
                scrollDirection: Axis.vertical,
                physics:         const _SnapScrollPhysics(),
                itemCount:       items.length,
                onPageChanged: (i) {
                  ref.read(currentFeedIndexProvider.notifier).update(i);
                  // Pagination infinie : charge la page suivante quand on
                  // approche de la fin (3 items avant la dernière vidéo).
                  if (i >= items.length - 3) {
                    ref.read(feedItemsProvider.notifier).loadMore();
                  }
                },
                itemBuilder: (context, index) {
                  final player = pool.value[index];
                  if (player == null) {
                    // Player pas encore créé (rare — transition rapide)
                    return Container(color: colorBgBase);
                  }
                  return FeedPage(
                    item:     items[index],
                    player:   player,
                    isActive: currentIdx == index,
                  );
                },
              ),

              // ── Header flottant ────────────────────────────────────────────
              const FeedHeader(),

              // ── Spinner "chargement de plus" (pagination infinie) ─────────
              const Positioned(
                bottom: 60, left: 0, right: 0,
                child: _LoadingMoreIndicator(),
              ),

              // ── Bottom Nav ─────────────────────────────────────────────────
              const Positioned(
                left: 0, right: 0, bottom: 0,
                child: _FeedBottomNav(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicateur de chargement (pagination infinie)
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingMoreIndicator extends ConsumerWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(loadingMoreProvider);
    if (!loading) return const SizedBox.shrink();
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white70,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Physique snap (une page à la fois)
// ─────────────────────────────────────────────────────────────────────────────
class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({super.parent});

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapScrollPhysics(parent: buildParent(ancestor));

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
class _FeedBottomNav extends StatelessWidget {
  const _FeedBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end:   Alignment.topCenter,
          colors: [Color(0xB3000000), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,    label: 'Accueil', active: true),
              _NavItem(icon: Icons.group_rounded,   label: 'Amis',
                  onTap: () => context.push('/friends')),
              const _CreateButton(),
              _NavItem(icon: Icons.inbox_rounded,   label: 'Boîte',
                  onTap: () => context.push('/inbox')),
              _NavItem(icon: Icons.person_rounded,  label: 'Profil',
                  onTap: () => context.push('/profile')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? colorTextPrimary : colorTextSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF69C9D0), Color(0xFFEE1D52)],
        ),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// États vides / erreur / squelette
// ─────────────────────────────────────────────────────────────────────────────
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(color: colorBgCard),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: colorTextSecondary),
            const SizedBox(height: 16),
            Text('Impossible de charger le feed',
                style: const TextStyle(color: colorTextPrimary, fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: colorTextSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded, size: 48, color: colorTextSecondary),
          const SizedBox(height: 16),
          const Text('Aucun contenu disponible',
              style: TextStyle(color: colorTextPrimary, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Configure un serveur Watchtower pour voir du contenu.',
              style: TextStyle(color: colorTextSecondary, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => GoRouter.of(context).push('/profile'),
            icon: const Icon(Icons.person_rounded),
            label: const Text('Aller dans Compte'),
          ),
        ],
      ),
    );
  }
}
