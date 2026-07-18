import 'package:flutter/material.dart';

class LiveStoriesBar extends StatelessWidget {
  const LiveStoriesBar({super.key});

  static final _stories = [
    _Story('https://i.pravatar.cc/150?img=1', 'Medusa', true),
    _Story('https://i.pravatar.cc/150?img=2', 'OhPlai', true),
    _Story('https://i.pravatar.cc/150?img=3', 'JoJobox ⭐', true),
    _Story('https://i.pravatar.cc/150?img=4', '🕵 ENNEMI...', true),
    _Story('https://i.pravatar.cc/150?img=5', 'Bie...', true),
    _Story('https://i.pravatar.cc/150?img=6', 'Drake', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _StoryItem(story: _stories[i]),
      ),
    );
  }
}

class _Story {
  const _Story(this.avatar, this.name, this.isLive);
  final String avatar, name;
  final bool isLive;
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.story});
  final _Story story;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Pink border ring for LIVE
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: story.isLive
                        ? Border.all(color: const Color(0xFFFE2C55), width: 2.5)
                        : Border.all(color: Colors.white24, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: ClipOval(
                    child: Image.network(
                      story.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1C2340),
                        child: const Icon(Icons.person, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                if (story.isLive)
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE2C55),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              story.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
