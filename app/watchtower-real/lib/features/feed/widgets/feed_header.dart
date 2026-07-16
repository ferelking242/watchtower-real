import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../providers/feed_provider.dart';

class FeedHeader extends ConsumerWidget {
  const FeedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(feedTabProvider);
    final serverStatus = ref.watch(serverStatusProvider);
    final isConnected = serverStatus != null && serverStatus.startsWith('✓');

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: space56,
              child: Row(
                children: [
                  const SizedBox(width: space16),
                  // Badge LIVE
                  _LiveBadge(),
                  const Spacer(),
                  // Tabs Suivis | Pour toi
                  _FeedTab(
                    label: 'Suivis',
                    index: 1,
                    activeTab: activeTab,
                    onTap: () =>
                        ref.read(feedTabProvider.notifier).state = 1,
                  ),
                  const SizedBox(width: space20),
                  _FeedTab(
                    label: 'Pour toi',
                    index: 0,
                    activeTab: activeTab,
                    onTap: () =>
                        ref.read(feedTabProvider.notifier).state = 0,
                  ),
                  const Spacer(),
                  // Bouton de connexion serveur
                  GestureDetector(
                    onTap: () => context.push('/connect'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          const Icon(
                            Icons.settings_rounded,
                            color: colorTextPrimary,
                            size: 24,
                          ),
                          // Point indicateur connexion
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? const Color(0xFF2ECC71)
                                    : colorTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Loupe
                  IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: colorTextPrimary,
                      size: 26,
                    ),
                    onPressed: () {
                      // TODO: go_router → /search
                    },
                  ),
                ],
              ),
            ),
            // Bannière statut serveur
            if (serverStatus != null && !isConnected)
              _ServerBanner(message: serverStatus),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bannière info serveur
// ─────────────────────────────────────────────────────────────────────────────
class _ServerBanner extends StatelessWidget {
  const _ServerBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: space16, vertical: 6),
      color: const Color(0xCC1A1A1A),
      child: Text(
        message,
        style: const TextStyle(
          color: colorTextSecondary,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Suivis / Pour toi
// ─────────────────────────────────────────────────────────────────────────────
class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.index,
    required this.activeTab,
    required this.onTap,
  });

  final String label;
  final int index;
  final int activeTab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: durationNormal,
        opacity: isActive ? 1.0 : 0.65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colorTextPrimary,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: durationNormal,
              height: 2,
              width: isActive ? 24 : 0,
              decoration: const BoxDecoration(
                color: colorTextPrimary,
                borderRadius: BorderRadius.all(Radius.circular(1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge LIVE pulsant
// ─────────────────────────────────────────────────────────────────────────────
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: durationPulse)
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.6).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colorLiveRed,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            color: colorTextPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
