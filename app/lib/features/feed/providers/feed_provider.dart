import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchtower_real/features/feed/data/mock_feed.dart';
import 'package:watchtower_real/remote/ntfy_logger.dart';
import 'package:watchtower_real/remote/remote_config_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class FeedItemModel {
  const FeedItemModel({
    required this.id,
    required this.pageUrl,
    required this.title,
    required this.thumbnailUrl,
    required this.author,
    required this.authorAvatar,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.bookmarks,
    required this.song,
    required this.hashtags,
    this.videoUrl,
    this.isLive = false,
    this.isFromApi = false,
    this.isPhoto = false,
    this.photoUrls = const [],
  });

  final String id;
  final String pageUrl;
  final String title;
  final String thumbnailUrl;
  final String author;
  final String authorAvatar;
  final int likes;
  final int comments;
  final int shares;
  final int bookmarks;
  final String song;
  final List<String> hashtags;
  final String? videoUrl;
  final bool isLive;
  final bool isFromApi;
  final bool isPhoto;
  final List<String> photoUrls;

  int get photoCount => photoUrls.length;

  FeedItemModel copyWith({String? videoUrl}) => FeedItemModel(
        id: id, pageUrl: pageUrl, title: title,
        thumbnailUrl: thumbnailUrl, author: author,
        authorAvatar: authorAvatar, likes: likes,
        comments: comments, shares: shares, bookmarks: bookmarks,
        song: song, hashtags: hashtags,
        videoUrl: videoUrl ?? this.videoUrl,
        isLive: isLive, isFromApi: isFromApi,
        isPhoto: isPhoto, photoUrls: photoUrls,
      );

  factory FeedItemModel.fromMock(FeedItem item) => FeedItemModel(
        id: item.id, pageUrl: item.videoUrl, title: item.description,
        thumbnailUrl: item.thumbnailUrl, author: item.author,
        authorAvatar: item.authorAvatar, likes: item.likes,
        comments: item.comments, shares: item.shares,
        bookmarks: item.bookmarks, song: item.song,
        hashtags: item.hashtags,
        videoUrl: item.isPhoto ? null : item.videoUrl,
        isLive: item.isLive, isFromApi: false,
        isPhoto: item.isPhoto, photoUrls: item.photoUrls,
      );

  factory FeedItemModel.fromApi(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final title = (json['title'] as String? ?? json['name'] as String? ??
            json['description'] as String? ?? '').trim();
    final thumb = json['thumbnail'] as String? ??
        json['thumbnailUrl'] as String? ?? json['poster'] as String? ?? '';
    final author = json['author'] as String? ?? json['channel'] as String? ??
        json['username'] as String? ?? json['uploader'] as String? ?? '';
    final authorAvatar = json['authorAvatar'] as String? ??
        json['avatar'] as String? ?? json['channelAvatar'] as String? ??
        'https://i.pravatar.cc/150?u=${Uri.encodeComponent(author)}';
    final likes = (json['likes'] as num?)?.toInt() ??
        (json['likeCount'] as num?)?.toInt() ?? 0;
    final views = (json['views'] as num?)?.toInt() ??
        (json['viewCount'] as num?)?.toInt() ?? 0;

    final tagRegex = RegExp(r'#\w+');
    final hashtags = tagRegex.allMatches(title).map((m) => m.group(0)!).take(4).toList();

    final rawPhotos = json['photos'] as List<dynamic>? ??
        json['images'] as List<dynamic>? ?? [];
    final photoUrls = rawPhotos.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    final isPhoto = photoUrls.isNotEmpty ||
        json['type'] == 'image' || json['type'] == 'photo';

    return FeedItemModel(
      id: url, pageUrl: url, title: title, thumbnailUrl: thumb,
      author: author.startsWith('@') ? author : '@$author',
      authorAvatar: authorAvatar, likes: likes,
      comments: 0, shares: 0, bookmarks: views ~/ 10,
      song: '♪ ${author.isNotEmpty ? author : "Artiste"}',
      hashtags: hashtags.isEmpty ? ['#watchtower', '#live'] : hashtags,
      videoUrl: isPhoto ? null :
          (json['videoUrl'] as String? ?? json['streamUrl'] as String?),
      isFromApi: true, isPhoto: isPhoto, photoUrls: photoUrls,
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class FeedState {
  const FeedState({
    required this.items,
    this.isLoadingMore = false,
    this.error,
    this.sourceId,
  });
  final List<FeedItemModel> items;
  final bool isLoadingMore;
  final String? error;
  final String? sourceId; // which source is active

  static FeedState initial() => const FeedState(items: []);

  FeedState copyWith({
    List<FeedItemModel>? items,
    bool? isLoadingMore,
    String? error,
    String? sourceId,
  }) => FeedState(
        items: items ?? this.items,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        sourceId: sourceId ?? this.sourceId,
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Extract the usable route slug from a source object.
/// Servers typically route by string slug (e.g. "redgift"), NOT by numeric id.
/// Priority: non-empty String id > name > slug > key > id.toString()
String _pickSourceId(Map<dynamic, dynamic> m) {
  final id   = m['id'];
  final name = m['name'] ?? m['slug'] ?? m['key'];
  if (id is String && id.isNotEmpty) return id;
  if (name != null && name.toString().isNotEmpty) return name.toString();
  if (id != null) return id.toString();
  return m.toString();
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class FeedNotifier extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    // Watch so the feed rebuilds when config changes (e.g. after saving in config sheet).
    // .future ensures we wait for SharedPreferences to finish loading before deciding.
    final config = await ref.watch(remoteConfigProvider.future);
    return _load(FeedState.initial(), config);
  }

  /// Dynamically discover which source ID to use, then fetch its popular items.
  Future<FeedState> _load(FeedState current, RemoteConfig config) async {
    if (!config.isConfigured) {
      NtfyLogger.info('Feed: aucune config serveur → mode démo');
      return FeedState(items: kMockFeed.map(FeedItemModel.fromMock).toList());
    }

    try {
      final client = ref.read(remoteClientProvider);
      if (client == null) throw Exception('remoteClientProvider retourne null (config vide?)');

      // ── Étape 1 : lister les sources disponibles ─────────────────────────
      late final String sourceId;
      try {
        final sources = await client.sources().timeout(const Duration(seconds: 10));
        if (sources.isEmpty) {
          throw Exception('Le serveur ne retourne aucune source (/api/sources vide)');
        }
        // Prend l'ID de la première source (peu importe son nom)
        final first = sources.first;
        sourceId = (first is Map)
            ? _pickSourceId(first as Map)
            : first.toString();
        NtfyLogger.info('Sources disponibles: ${sources.map((s) => s is Map ? s["id"] ?? s["name"] : s).toList()}\nSource active: $sourceId');
      } catch (e) {
        throw Exception('Impossible de lister les sources: $e');
      }

      // ── Étape 2 : charger les items populaires ────────────────────────────
      List<dynamic> raw;
      try {
        final data = await client.popular(sourceId).timeout(const Duration(seconds: 15));
        raw = data['items'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            data['results'] as List<dynamic>? ??
            data['videos'] as List<dynamic>? ??
            data['posts'] as List<dynamic>? ??
            data['content'] as List<dynamic>? ?? [];
        if (raw.isEmpty) {
          // Essaie latest si popular est vide
          NtfyLogger.warn('popular/$sourceId vide → essai latest');
          final fallback = await client.latest(sourceId).timeout(const Duration(seconds: 15));
          raw = fallback['items'] as List<dynamic>? ??
              fallback['data'] as List<dynamic>? ??
              fallback['results'] as List<dynamic>? ?? [];
        }
      } catch (e) {
        throw Exception('Erreur popular/$sourceId: $e');
      }

      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(FeedItemModel.fromApi)
          .toList();

      NtfyLogger.ok('Feed chargé: ${items.length} items depuis $sourceId');
      return FeedState(
        items: [...current.items, ...items],
        sourceId: sourceId,
      );
    } catch (e) {
      final errMsg = e.toString();
      NtfyLogger.error('Feed error: $errMsg\nServeur: ${config.baseUrl}');

      if (current.items.isEmpty) {
        return FeedState(
          items: kMockFeed.map(FeedItemModel.fromMock).toList(),
          error: errMsg.length > 120 ? '${errMsg.substring(0, 120)}…' : errMsg,
        );
      }
      return current.copyWith(error: 'Erreur: $errMsg');
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final config = await ref.read(remoteConfigProvider.future);
    final next = await _load(current, config);
    state = AsyncData(next.copyWith(isLoadingMore: false));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final config = await ref.read(remoteConfigProvider.future);
    state = AsyncData(await _load(FeedState.initial(), config));
  }

  Future<String?> resolveVideoUrl(FeedItemModel item) async {
    if (item.videoUrl != null) return item.videoUrl;
    if (item.isPhoto) return null;
    try {
      final client = ref.read(remoteClientProvider);
      if (client == null) return null;
      final sourceId = state.value?.sourceId ?? 'default';
      final data = await client.videos(sourceId, item.pageUrl)
          .timeout(const Duration(seconds: 15));
      final url = data['url'] as String? ??
          data['streamUrl'] as String? ?? data['videoUrl'] as String?;
      if (url != null) _updateItemUrl(item.id, url);
      return url;
    } catch (e) {
      NtfyLogger.warn('resolveVideoUrl error: $e');
      return null;
    }
  }

  void _updateItemUrl(String id, String url) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      items: current.items
          .map((i) => i.id == id ? i.copyWith(videoUrl: url) : i)
          .toList(),
    ));
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
