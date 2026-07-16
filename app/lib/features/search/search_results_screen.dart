import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/core/widgets/follow_button.dart';
import 'package:watchtower_real/core/widgets/video_thumbnail.dart';
import 'package:watchtower_real/features/feed/data/mock_feed.dart';
import 'package:watchtower_real/features/search/search_filters_sheet.dart';

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
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: Colors.black,
                  unselectedLabelColor: AppTokens.colorTextSecondaryDark,
                  indicatorColor: Colors.black,
                  indicatorWeight: 2,
                  labelStyle: AppTokens.labelM,
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
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.black),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTokens.radiusLg)),
                  ),
                  builder: (_) => const SearchFiltersSheet(),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        Text('Résultats pour "$query"',
            style: AppTokens.titleM.copyWith(color: Colors.black)),
        const SizedBox(height: AppTokens.space16),
        // User preview card
        _UserCard(
          avatar: 'https://i.pravatar.cc/150?img=10',
          username: '@${query.replaceAll(' ', '_')}',
          followers: '1.2M',
          videos: '234',
        ),
        const SizedBox(height: AppTokens.space16),
        // Video grid preview
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 9 / 16,
          ),
          itemCount: 6,
          itemBuilder: (context, i) => VideoThumbnail(
            url: 'https://picsum.photos/seed/search$i/400/700',
            views: '${(i + 1) * 12}K',
          ),
        ),
      ],
    );
  }
}

// ─── Videos tab ──────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 10,
      itemBuilder: (context, i) => VideoThumbnail(
        url: 'https://picsum.photos/seed/vid$i$query/400/700',
        views: '${(i + 1) * 8}K',
      ),
    );
  }
}

// ─── Users tab ───────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.query});
  final String query;

  static final _users = [
    ('https://i.pravatar.cc/150?img=11', '@${_clean("user_one")}', '2.3M', '89'),
    ('https://i.pravatar.cc/150?img=12', '@${_clean("user_two")}', '450K', '120'),
    ('https://i.pravatar.cc/150?img=13', '@${_clean("user_three")}', '87K', '44'),
    ('https://i.pravatar.cc/150?img=14', '@${_clean("user_four")}', '1.1M', '200'),
    ('https://i.pravatar.cc/150?img=15', '@${_clean("user_five")}', '23K', '15'),
  ];

  static String _clean(String s) => s;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTokens.colorDividerLight),
      itemBuilder: (context, i) {
        final (avatar, username, followers, videos) = _users[i];
        return _UserCard(
          avatar: avatar,
          username: username,
          followers: followers,
          videos: videos,
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.avatar,
    required this.username,
    required this.followers,
    required this.videos,
  });
  final String avatar, username, followers, videos;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16, vertical: AppTokens.space8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatar),
      ),
      title: Row(
        children: [
          Text(username,
              style: AppTokens.bodyM.copyWith(
                  color: Colors.black, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.verified, color: AppTokens.colorVerified, size: 14),
        ],
      ),
      subtitle: Text('$followers followers · $videos vidéos',
          style: AppTokens.labelS.copyWith(
              color: AppTokens.colorTextSecondaryDark)),
      trailing: const FollowButton(mini: true),
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
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTokens.colorBgLightSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: const Icon(Icons.music_note, color: AppTokens.colorTextSecondaryDark),
        ),
        title: Text('Son tendance ${i + 1}',
            style: AppTokens.bodyM.copyWith(color: Colors.black)),
        subtitle: Text('Artiste ${i + 1} · ${(i + 1) * 12}K vidéos',
            style: AppTokens.labelS.copyWith(color: AppTokens.colorTextSecondaryDark)),
        trailing: const Icon(Icons.play_circle_outline, color: AppTokens.colorTextSecondaryDark),
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
      padding: const EdgeInsets.all(AppTokens.space8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTokens.space8,
        mainAxisSpacing: AppTokens.space8,
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
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.colorLiveRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('LIVE',
                    style: AppTokens.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
            Positioned(
              bottom: 8, left: 8,
              child: Text('${(i + 1) * 1200} spectateurs',
                  style: AppTokens.caption.copyWith(color: Colors.white)),
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
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTokens.colorBgLightSurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('#',
                style: AppTokens.titleM.copyWith(color: Colors.black)),
          ),
        ),
        title: Text(tags[i],
            style: AppTokens.bodyM.copyWith(
                color: Colors.black, fontWeight: FontWeight.w700)),
        trailing: Text('${(i + 1) * 89}M vues',
            style: AppTokens.labelS.copyWith(
                color: AppTokens.colorTextSecondaryDark)),
      ),
    );
  }
}
