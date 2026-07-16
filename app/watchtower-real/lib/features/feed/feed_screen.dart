import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/theme/tokens.dart';
import 'data/mock_feed.dart';
import 'models/feed_item.dart';
import 'providers/feed_provider.dart';
import 'package:go_router/go_router.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_page.dart';

class FeedScreen extends HookConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedItemsProvider);
    final pageController = usePageController();
    final currentIndex = ref.watch(currentFeedIndexProvider);

    // Fond noir + barre de statut blanche pour le feed
    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: colorBgBase,
      extendBody: true,
      body: feedAsync.when(
        loading: () => _FeedSkeleton(),
        error: (e, _) => _FeedError(message: e.toString()),
        data: (items) => Stack(
          children: [
            // ── PageView vertical ──────────────────────────────────────────
            PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              physics: const _SnapScrollPhysics(),
              itemCount: items.length,
              onPageChanged: (i) {
                ref.read(currentFeedIndexProvider.notifier).state = i;
              },
              itemBuilder: (context, index) {
                return FeedPage(
                  item: items[index],
                  isActive: currentIndex == index,
                );
              },
            ),

            // ── Header flottant ────────────────────────────────────────────
            const FeedHeader(),

            // ── Bottom Nav ─────────────────────────────────────────────────
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FeedBottomNav(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Physique snap (une vidéo à la fois)
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
// Bottom Navigation Bar (transparent sur le feed)
// ─────────────────────────────────────────────────────────────────────────────
class _FeedBottomNav extends StatelessWidget {
  const _FeedBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
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
              _NavItem(icon: Icons.home_rounded, label: 'Accueil', active: true),
              _NavItem(icon: Icons.group_rounded, label: 'Amis'),
              _CreateButton(),
              _NavItem(icon: Icons.chat_bubble_rounded, label: 'Messages'),
              _NavItem(icon: Icons.person_rounded, label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.active = false});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: active ? colorTextPrimary : colorTextSecondary,
          size: 26,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: active ? colorTextPrimary : colorTextSecondary,
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Bouton central bicolore (cyan + rouge) avec icône +
class _CreateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rectangle cyan (gauche)
              Positioned(
                left: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: colorBrandCyan,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(6),
                    ),
                  ),
                ),
              ),
              // Rectangle rouge (droite)
              Positioned(
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: colorBrand,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                  ),
                ),
              ),
              // Bouton blanc central avec +
              Container(
                width: 30,
                height: 28,
                decoration: BoxDecoration(
                  color: colorTextPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded,
                    color: colorTextPrimaryDark, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '',
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton (chargement)
// ─────────────────────────────────────────────────────────────────────────────
class _FeedSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFF1C1C1E),
        highlightColor: Color(0xFF2C2C2E),
      ),
      child: Container(
        color: colorBgCard,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 15, width: 120, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 13, width: 220, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 13, width: 180, color: Colors.white),
              const SizedBox(height: 12),
              Container(height: 13, width: 160, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Erreur — avec boutons Réessayer + Configurer (fix écran bloqué iOS)
// ─────────────────────────────────────────────────────────────────────────────
class _FeedError extends ConsumerWidget {
  const _FeedError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: colorBrand, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger le feed',
              style: TextStyle(
                  color: colorTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: colorTextSecondary, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.invalidate(feedItemsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBrand,
                  foregroundColor: colorTextPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/connect'),
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Configurer le serveur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorTextPrimary,
                  side: const BorderSide(color: colorTextSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
