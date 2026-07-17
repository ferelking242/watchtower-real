import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _InboxAppBar(),
      body: ListView(
        children: const [
          // Stories row
          _StoriesRow(),
          Divider(height: 1, color: AppTokens.colorDividerLight),
          // Contact discovery
          _ContactDiscoveryTile(),
          Divider(height: 1, color: AppTokens.colorDividerLight),
          // System notifications
          _NotifGroupTile(
            icon: Icons.people_alt_rounded,
            iconBg: Color(0xFF3897F0),
            title: 'Nouveaux followers',
            preview: '🦋Miss skinny🧸❤️ s\'est abonné(e...',
            timeLabel: '7/5',
          ),
          Divider(height: 1, color: AppTokens.colorDividerLight),
          _NotifGroupTile(
            icon: Icons.favorite_rounded,
            iconBg: Color(0xFFFE2C55),
            title: 'Activité',
            preview: 'rika78u1 a aimé ton commentaire.',
            timeLabel: 'Lundi',
            badge: 8,
          ),
          Divider(height: 1, color: AppTokens.colorDividerLight),
          // DM conversations
          _DmTile(
            avatar: 'https://i.pravatar.cc/150?img=20',
            name: '🦋Miss skinny🧸❤️',
            status: 'Actif maintenant',
            isOnline: true,
          ),
          Divider(height: 1, color: AppTokens.colorDividerLight),
          _DmTile(
            avatar: 'https://i.pravatar.cc/150?img=21',
            name: 'Severina Elenga',
            status: 'Actif hier',
            isOnline: false,
          ),
          Divider(height: 1, color: AppTokens.colorDividerLight),
          _NotifGroupTile(
            icon: Icons.notifications_rounded,
            iconBg: Color(0xFF333333),
            title: 'Notifications système',
            preview: 'Mises à jour du compte: Une conne...',
            timeLabel: '6/27',
            badge: 1,
          ),
          Divider(height: 1, color: AppTokens.colorDividerLight),
        ],
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────
class _InboxAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _InboxAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.add_comment_outlined, color: Colors.black),
        onPressed: () {},
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Boîte de réception',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF20D060),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black, size: 18),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ─── Stories row ─────────────────────────────────────────────────────────────
class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  static final _stories = [
    _StoryData('', 'Créer', false, true),
    _StoryData('https://i.pravatar.cc/150?img=30', 'Ce jour-là', false, false),
    _StoryData('https://i.pravatar.cc/150?img=1', 'Medusa', true, false),
    _StoryData('https://i.pravatar.cc/150?img=4', '🕵 ENNEMI D...', true, false),
    _StoryData('https://i.pravatar.cc/150?img=5', 'Chef...', true, false),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => _StoryAvatar(data: _stories[i]),
      ),
    );
  }
}

class _StoryData {
  const _StoryData(this.avatar, this.name, this.hasLive, this.isCreate);
  final String avatar, name;
  final bool hasLive, isCreate;
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.data});
  final _StoryData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.isCreate)
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: const Icon(Icons.add, color: Colors.black54, size: 28),
              ),
            ],
          )
        else
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: data.hasLive
                      ? Border.all(color: const Color(0xFFFE2C55), width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Image.network(
                    data.avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300),
                  ),
                ),
              ),
              if (data.hasLive)
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE2C55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        Text(
          data.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Contact discovery ────────────────────────────────────────────────────────
class _ContactDiscoveryTile extends StatelessWidget {
  const _ContactDiscoveryTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF20C060),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Discute avec tes conta...',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trouve-les et discute avec eux',
                  style: TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFE2C55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Trouver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification group tile ─────────────────────────────────────────────────
class _NotifGroupTile extends StatelessWidget {
  const _NotifGroupTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.preview,
    required this.timeLabel,
    this.badge,
  });

  final IconData icon;
  final Color iconBg;
  final String title, preview, timeLabel;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        style: const TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null && badge! > 0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFE2C55),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DM tile ─────────────────────────────────────────────────────────────────
class _DmTile extends StatelessWidget {
  const _DmTile({
    required this.avatar,
    required this.name,
    required this.status,
    required this.isOnline,
  });
  final String avatar, name, status;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(avatar),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF20C060),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: isOnline
                        ? const Color(0xFF20C060)
                        : const Color(0xFF8A8A8A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Text('👋', style: TextStyle(fontSize: 14)),
            label: const Text(
              'Envoie un',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
