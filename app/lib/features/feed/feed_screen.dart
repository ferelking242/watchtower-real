import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/features/feed/providers/feed_provider.dart';
import 'package:watchtower_real/features/feed/widgets/feed_header.dart';
import 'package:watchtower_real/features/feed/widgets/feed_page.dart';
import 'package:watchtower_real/features/feed/widgets/live_stories_bar.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _controller = PageController();
  int _currentIndex = 0;
  int _navIndex = 0;
  // 0 = Suivis, 1 = Pour toi
  int _feedTab = 1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == 0) {
      setState(() => _navIndex = 0);
      return;
    }
    switch (i) {
      case 1:
        context.push('/search');
        break;
      case 3:
        context.push('/inbox');
        break;
      case 4:
        context.push('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTokens.colorBgBase,
      extendBody: true,
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTokens.colorBrand),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur : $e',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(feedProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.colorBrand),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (feedState) {
          final items = feedState.items;
          if (items.isEmpty) {
            return const Center(
              child: Text('Aucun contenu',
                  style: TextStyle(color: Colors.white)),
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification &&
                  _controller.position.extentAfter < 200) {
                ref.read(feedProvider.notifier).loadMore();
              }
              return false;
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  physics: const _FastPageScrollPhysics(),
                  itemCount:
                      items.length + (feedState.isLoadingMore ? 1 : 0),
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTokens.colorBrand),
                      );
                    }
                    return FeedPage(
                      key: ValueKey(items[index].id),
                      item: items[index],
                      isActive: index == _currentIndex,
                      preload: index == _currentIndex + 1,
                    );
                  },
                ),

                // ── Header overlay ───────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FeedHeader(
                    onTabChanged: (tab) => setState(() => _feedTab = tab),
                  ),
                ),

                // ── Live stories (Suivis tab) ────────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  top: _feedTab == 0 ? MediaQuery.of(context).padding.top + 44 : -110,
                  left: 0,
                  right: 0,
                  child: const LiveStoriesBar(),
                ),

                // ── Error banner (non-blocking) ──────────────────────
                if (feedState.error != null)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feedState.error!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─── Fast snapping page physics ──────────────────────────────────────────────
class _FastPageScrollPhysics extends PageScrollPhysics {
  const _FastPageScrollPhysics() : super(parent: const ClampingScrollPhysics());

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 80,
        stiffness: 100,
        damping: 1,
      );
}

// ─── Bottom navigation ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 52 + bottom,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_filled,
            iconOff: Icons.home_outlined,
            label: 'Accueil',
            index: 0,
            current: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.people_alt_rounded,
            iconOff: Icons.people_alt_outlined,
            label: 'Amis',
            index: 1,
            current: currentIndex,
            onTap: onTap,
            badge: 69,
          ),
          // Centre + button
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: _AddButton(),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.chat_bubble_rounded,
            iconOff: Icons.chat_bubble_outline_rounded,
            label: 'Boîte de réception',
            index: 3,
            current: currentIndex,
            onTap: onTap,
            badge: 8,
          ),
          _NavItem(
            icon: Icons.person_rounded,
            iconOff: Icons.person_outline_rounded,
            label: 'Profil',
            index: 4,
            current: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconOff,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge,
  });

  final IconData icon, iconOff;
  final String label;
  final int index, current;
  final void Function(int) onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? icon : iconOff,
                  color: Colors.white,
                  size: 26,
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE2C55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cyan left tab
          Positioned(
            left: 0,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF69C9D0),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          // Red right tab
          Positioned(
            right: 0,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFE2C55),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          // White center
          Positioned(
            left: 4,
            child: Container(
              width: 36,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
