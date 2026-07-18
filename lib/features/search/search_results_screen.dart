import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:reel/core/theme/tokens.dart';
import 'package:reel/core/widgets/video_thumbnail.dart';
import 'package:reel/features/search/search_filters_sheet.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.query});
  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar + filter icon
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: Colors.black,
                  unselectedLabelColor: const Color(0xFF8A8A8A),
                  indicatorColor: Colors.black,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400),
                  tabs: const [
                    Tab(text: 'Top'),
                    Tab(text: 'Vidéos'),
                    Tab(text: 'Utilisateurs'),
                    Tab(text: 'Sons'),
                    Tab(text: 'LIVE'),
                    Tab(text: 'Hashtags'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTokens.radiusLg)),
                  ),
                  builder: (_) => const SearchFiltersSheet(),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(Icons.tune_rounded, color: Colors.black, size: 22),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _TopTab(query: widget.query),
              _VideosTab(query: widget.query),
              _UsersTab(query: widget.query),
              _SoundsTab(),
              _LiveTab(),
              _HashtagsTab(query: widget.query),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top tab ─────────────────────────────────────────────────────────────────
class _TopTab extends StatelessWidget {
  const _TopTab({required this.query});
  final String query;

  static final _videos = [
    _VideoResult(
      'https://picsum.photos/seed/top1/400/700',
      '29/4',
      'Play à telemi goût c\'est le big like et republier...',
      'https://i.pravatar.cc/150?img=10',
      '😁LE.MEC.ST...',
      84,
      false,
    ),
    _VideoResult(
      'https://picsum.photos/seed/top2/400/700',
      '1/9/2023',
      '😱😱 #crab #big #crazy #alexfunfacts',
      'https://i.pravatar.cc/150?img=11',
      'alex.funfacts',
      3700000,
      false,
    ),
    _VideoResult(
      'https://picsum.photos/seed/top3/400/700',
      '14/3',
      'Big energy vibes check this out',
      'https://i.pravatar.cc/150?img=12',
      'energy_vibes',
      12400,
      false,
    ),
    _VideoResult(
      'https://picsum.photos/seed/top4/400/700',
      '5/6',
      'The big challenge everyone is doing 🔥',
      'https://i.pravatar.cc/150?img=13',
      'challenge_crew',
      290000,
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        // 2-column staggered grid
        _VideoGrid2Col(videos: _videos),
      ],
    );
  }
}

class _VideoGrid2Col extends StatelessWidget {
  const _VideoGrid2Col({required this.videos});
  final List<_VideoResult> videos;

  @override
  Widget build(BuildContext context) {
    final pairs = <List<_VideoResult>>[];
    for (var i = 0; i < videos.length; i += 2) {
      pairs.add(videos.sublist(i, i + 2 > videos.length ? videos.length : i + 2));
    }
    return Column(
      children: pairs.map((pair) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pair
              .map((v) => Expanded(child: _VideoCard(video: v)))
              .toList(),
        );
      }).toList(),
    );
  }
}

class _VideoResult {
  const _VideoResult(this.thumb, this.date, this.title, this.avatar,
      this.username, this.likes, this.isMostLiked);
  final String thumb, date, title, avatar, username;
  final int likes;
  final bool isMostLiked;
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});
  final _VideoResult video;

  String _fmtLikes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300),
                  ),
                  if (video.isMostLiked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Les plus aimées',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          video.date,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black)
                            ],
                          ),
                        ),
                        const Icon(Icons.volume_off_rounded,
                            color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              video.title,
              style: const TextStyle(
                  color: Colors.black, fontSize: 12, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Avatar + username + likes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundImage: NetworkImage(video.avatar),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    video.username,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.favorite_border_rounded,
                    size: 11, color: Color(0xFF8A8A8A)),
                const SizedBox(width: 2),
                Text(
                  _fmtLikes(video.likes),
                  style: const TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Videos tab ──────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.query});
  final String query;

  static final _videos = [
    _VideoResult(
      'https://picsum.photos/seed/vid1/400/700',
      '23/5',
      'Flex up, stretch out big bands! Her waterbend...',
      'https://i.pravatar.cc/150?img=20',
      'kasacx',
      162500,
      false,
    ),
    _VideoResult(
      'https://picsum.photos/seed/vid2/400/700',
      '19/6',
      'Oh, you stretch your big stretcher. New Spider-...',
      'https://i.pravatar.cc/150?img=21',
      'Kyro',
      289400,
      true,
    ),
    _VideoResult(
      'https://picsum.photos/seed/vid3/400/700',
      '3/4',
      'Bro standing on business 😂',
      'https://i.pravatar.cc/150?img=22',
      'big_vibes',
      45000,
      false,
    ),
    _VideoResult(
      'https://picsum.photos/seed/vid4/400/700',
      '12/5',
      'Un autre big moment incroyable à voir',
      'https://i.pravatar.cc/150?img=23',
      'moment_king',
      89000,
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        // "Suivis" separator if needed
        _VideoGrid2Col(videos: _videos),
      ],
    );
  }
}

// ─── Users tab ───────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.query});
  final String query;

  static final _users = [
    _UserResult('https://i.pravatar.cc/150?img=11', 'big_peeramon',
        'big', '349,0K abonnés · 761 vidéos', false),
    _UserResult('https://i.pravatar.cc/150?img=12', 'therealsemajlesley',
        'BIG', '362,9K abonnés · 212 vidéos', false),
    _UserResult('https://i.pravatar.cc/150?img=13', 'etie468',
        'BIG', '414,3K abonnés · 209 vidéos', false),
    _UserResult('https://i.pravatar.cc/150?img=14', 'bigbang_2xx6',
        'BIGBANG', '430,3K abonnés · 6 vidéos', true),
    _UserResult('https://i.pravatar.cc/150?img=15', 'acervosdabig',
        'Big', '26,5K abonnés · 109 vidéos', false),
    _UserResult('https://i.pravatar.cc/150?img=16', 'bipasa205',
        'big', '162,8K abonnés · 0 vidéo', false),
    _UserResult('https://i.pravatar.cc/150?img=17', 'drz013_',
        'Big!', '33,3K abonnés · 263 vidéos', false),
    _UserResult('https://i.pravatar.cc/150?img=18', 'big35_5',
        'BiG', '18,9K abonnés · 51 vidéos', false, isPrivate: true),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTokens.colorDividerLight),
      itemBuilder: (context, i) => _UserTile(user: _users[i]),
    );
  }
}

class _UserResult {
  const _UserResult(this.avatar, this.username, this.displayName,
      this.subtitle, this.verified,
      {this.isPrivate = false});
  final String avatar, username, displayName, subtitle;
  final bool verified, isPrivate;
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final _UserResult user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(user.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          color: AppTokens.colorVerified, size: 14),
                    ],
                    if (user.isPrivate) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '· Privé',
                        style: TextStyle(
                            color: Color(0xFF8A8A8A), fontSize: 13),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.displayName,
                  style: const TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 12),
                ),
                const SizedBox(height: 1),
                Text(
                  user.subtitle,
                  style: const TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFE2C55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Suivre',
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

// ─── Sounds tab ───────────────────────────────────────────────────────────────
class _SoundsTab extends StatelessWidget {
  const _SoundsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, i) => ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTokens.colorBgLightSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: const Icon(Icons.music_note_rounded,
              color: AppTokens.colorTextSecondaryDark),
        ),
        title: Text('Son tendance ${i + 1}',
            style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Artiste ${i + 1} · ${(i + 1) * 12}K vidéos',
            style: const TextStyle(
                color: Color(0xFF8A8A8A), fontSize: 12)),
        trailing: const Icon(Icons.play_circle_outline_rounded,
            color: Color(0xFF8A8A8A)),
      ),
    );
  }
}

// ─── LIVE tab ─────────────────────────────────────────────────────────────────
class _LiveTab extends StatelessWidget {
  const _LiveTab();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 9 / 14,
      ),
      itemCount: 6,
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: 'https://picsum.photos/seed/live$i/400/700',
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.colorLiveRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Text('${(i + 1) * 1200} spectateurs',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hashtags tab ─────────────────────────────────────────────────────────────
class _HashtagsTab extends StatelessWidget {
  const _HashtagsTab({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final tags = [
      '#$query', '#${query}dance', '#${query}food',
      '#${query}travel', '#${query}viral', '#${query}fyp',
    ];
    return ListView.separated(
      itemCount: tags.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTokens.colorDividerLight),
      itemBuilder: (context, i) => ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTokens.colorBgLightSurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('#',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        title: Text(tags[i],
            style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        trailing: Text('${(i + 1) * 89}M vues',
            style: const TextStyle(
                color: Color(0xFF8A8A8A), fontSize: 12)),
      ),
    );
  }
}
