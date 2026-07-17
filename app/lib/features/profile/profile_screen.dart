import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/core/widgets/video_thumbnail.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _avatar = 'https://i.pravatar.cc/150?img=20';
  final _displayName = 'FERELKING';
  final _username = '@ferelking242';
  final _bio = 'ya rien ici';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = widget.userId == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _ProfileAppBar(
        displayName: _displayName,
        isOwn: isOwn,
        onMenu: () => _showSettingsMenu(context),
        onBack: () => Navigator.pop(context),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              avatar: _avatar,
              username: _username,
              bio: _bio,
              isOwn: isOwn,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                labelColor: Colors.black,
                unselectedLabelColor: AppTokens.colorTextSecondaryDark,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                  Tab(icon: Icon(Icons.lock_outline_rounded, size: 22)),
                  Tab(icon: Icon(Icons.repeat_rounded, size: 22)),
                  Tab(icon: Icon(Icons.bookmark_add_outlined, size: 22)),
                  Tab(icon: Icon(Icons.favorite_border_rounded, size: 22)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _VideoGrid(seed: 'profile_main'),
            _PrivateGrid(),
            _VideoGrid(seed: 'profile_repost'),
            _SavedGrid(),
            _LikedGrid(),
          ],
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsMenu(),
    );
  }
}

// ─── Profile AppBar ───────────────────────────────────────────────────────────
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar({
    required this.displayName,
    required this.isOwn,
    required this.onMenu,
    required this.onBack,
  });
  final String displayName;
  final bool isOwn;
  final VoidCallback onMenu, onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: isOwn
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: onBack,
            ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black, size: 20),
        ],
      ),
      centerTitle: true,
      actions: [
        if (isOwn) ...[
          // QR / binoculars icon
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.black),
            onPressed: () {},
          ),
          // Hamburger menu
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black),
            onPressed: onMenu,
          ),
        ],
      ],
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatar,
    required this.username,
    required this.bio,
    required this.isOwn,
  });
  final String avatar, username, bio;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with + button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CachedNetworkImage(
                imageUrl: avatar,
                imageBuilder: (_, img) =>
                    CircleAvatar(radius: 44, backgroundImage: img),
                placeholder: (_, __) => const CircleAvatar(
                    radius: 44, backgroundColor: Colors.black12),
                errorWidget: (_, __, ___) => const CircleAvatar(
                    radius: 44, backgroundColor: Colors.black12),
              ),
              if (isOwn)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF69C9D0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Username + QR icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.black54, size: 18),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          _StatsRow(),
          const SizedBox(height: 14),

          // Buttons
          if (isOwn)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Modifier le profil',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      minimumSize: const Size(0, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Ajout d\'amis',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Suivre',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),

          const SizedBox(height: 10),

          // Bio
          Text(
            bio,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(value: '2413', label: 'Suivis'),
        _VertDivider(),
        // Followers with badge
        _StatItemBadged(value: '110', label: 'Followers', badge: '+22'),
        _VertDivider(),
        _StatItem(value: '28', label: 'J\'aime'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItemBadged extends StatelessWidget {
  const _StatItemBadged(
      {required this.value, required this.label, required this.badge});
  final String value, label, badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              Positioned(
                top: -4,
                right: -30,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE2C55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 1, height: 28, child: VerticalDivider());
}

// ─── Settings Menu ────────────────────────────────────────────────────────────
class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _SettingsItem(
            icon: Icons.star_outline_rounded,
            label: 'Outils pour les créateurs',
            hasBadge: true,
            onTap: () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SettingsItem(
            icon: Icons.qr_code_rounded,
            label: 'Mon code QR',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SettingsItem(
            icon: Icons.settings_outlined,
            label: 'Paramètres et confidentialité',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasBadge = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasBadge)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFE2C55),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Grids ────────────────────────────────────────────────────────────────────
class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 12,
      itemBuilder: (_, i) => VideoThumbnail(
        url: 'https://picsum.photos/seed/${seed}_$i/200/356',
        views: '${(i + 1) * 55}',
      ),
    );
  }
}

class _PrivateGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Contenu privé',
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SavedGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tab bar
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const [
                _SubTab(label: 'Publications 2462', active: true),
                SizedBox(width: 16),
                _SubTab(label: 'Collections 1', active: false),
                SizedBox(width: 16),
                _SubTab(label: 'Sons 9', active: false),
                SizedBox(width: 16),
                _SubTab(label: 'Effets', active: false),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTokens.colorDividerLight),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 9 / 16,
            ),
            itemCount: 12,
            itemBuilder: (_, i) => VideoThumbnail(
              url: 'https://picsum.photos/seed/saved_$i/200/356',
              views: '${(i + 1) * 100}K',
            ),
          ),
        ),
      ],
    );
  }
}

class _LikedGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Privacy banner
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 13),
                    children: [
                      TextSpan(
                          text:
                              'Tu peux rendre publiques les vidéos sur lesquelles tu as laissé un j\'aime dans '),
                      TextSpan(
                        text: 'Paramètres de confidentialité',
                        style: TextStyle(
                          color: Color(0xFFFE2C55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.close, color: Colors.black54, size: 18),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTokens.colorDividerLight),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 9 / 16,
            ),
            itemCount: 12,
            itemBuilder: (_, i) => VideoThumbnail(
              url: 'https://picsum.photos/seed/liked_$i/200/356',
              views: '${(i + 1) * 200}K',
            ),
          ),
        ),
      ],
    );
  }
}

class _SubTab extends StatelessWidget {
  const _SubTab({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : const Color(0xFF8A8A8A),
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Tab bar delegate ─────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, color: AppTokens.colorDividerLight),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
