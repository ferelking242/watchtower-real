import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// TikTok-style top header:
/// [LIVE] [Explorer] [Suivis] [Pour toi] [🔍]
class FeedHeader extends StatefulWidget {
  const FeedHeader({super.key});

  @override
  State<FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends State<FeedHeader> {
  // 0=Explorer, 1=Suivis, 2=Pour toi
  int _tab = 2;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── LIVE badge ─────────────────────────────────────────
              GestureDetector(
                onTap: () => context.push('/live'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      height: 1,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Tabs ───────────────────────────────────────────────
              _TabItem(label: 'Explorer', index: 0, current: _tab,
                  onTap: (i) => setState(() => _tab = i)),
              const SizedBox(width: 20),
              _TabItem(label: 'Suivis', index: 1, current: _tab,
                  onTap: (i) => setState(() => _tab = i)),
              const SizedBox(width: 20),
              _TabItem(label: 'Pour toi', index: 2, current: _tab,
                  onTap: (i) => setState(() => _tab = i)),

              const Spacer(),

              // ── Search ─────────────────────────────────────────────
              GestureDetector(
                onTap: () => context.push('/search'),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final String label;
  final int index, current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontSize: active ? 16 : 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: active ? 18 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
