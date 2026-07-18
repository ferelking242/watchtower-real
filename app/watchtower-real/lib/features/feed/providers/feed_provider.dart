import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../../../remote/remote_client.dart';
import '../../../remote/remote_config_provider.dart';
import '../../../utils/log/app_file_logger.dart';
import '../../../remote/ntfy_logger.dart';

const _tag = 'FeedProvider';

// ─────────────────────────────────────────────────────────────────────────────
// Index de la page active (Riverpod 3.x : Notifier au lieu de StateProvider)
// ─────────────────────────────────────────────────────────────────────────────
class _CurrentFeedIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void update(int value) => state = value;
}

final currentFeedIndexProvider =
    NotifierProvider<_CurrentFeedIndexNotifier, int>(
        _CurrentFeedIndexNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Tab actif : 0 = "Pour toi", 1 = "Suivis"
// ─────────────────────────────────────────────────────────────────────────────
class _FeedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void update(int value) => state = value;
}

final feedTabProvider =
    NotifierProvider<_FeedTabNotifier, int>(_FeedTabNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Statut de connexion serveur
// ─────────────────────────────────────────────────────────────────────────────
class _ServerStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void update(String? value) => state = value;
}

final serverStatusProvider =
    NotifierProvider<_ServerStatusNotifier, String?>(
        _ServerStatusNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Indicateur "chargement de plus" (pour afficher un spinner en bas du feed)
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

final loadingMoreProvider =
    NotifierProvider<_LoadingMoreNotifier, bool>(_LoadingMoreNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Feed items — avec pagination infinie
// ─────────────────────────────────────────────────────────────────────────────
final feedItemsProvider =
    AsyncNotifierProvider<FeedNotifier, List<FeedItem>>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<List<FeedItem>> {
  // État de pagination — réinitialisé à chaque build()
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _resolvedSourceId = '';
  String _resolvedSourceName = '';
  RemoteApiClient? _client;

  @override
  Future<List<FeedItem>> build() async {
    // Réinitialise la pagination à chaque rebuild (changement de config)
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _resolvedSourceId = '';
    _resolvedSourceName = '';
    _client = null;

    final client = ref.watch(remoteClientProvider);

    if (client == null) {
      logger.log(_tag, 'Pas de client configuré → liste vide');
      NtfyLogger.info('App lancée sans serveur configuré');
      ref.read(serverStatusProvider.notifier).update(
          'Aucun serveur configuré — configure un serveur pour voir du contenu');
      return [];
    }

    logger.log(_tag, 'Client configuré (${client.baseUrl}) → chargement réel');
    NtfyLogger.info('Connexion: ${client.baseUrl}');
    ref.read(serverStatusProvider.notifier).update(null);

    final config = await ref.read(remoteConfigProvider.future);
    return _loadPage(client, config.selectedSourceId, page: 1);
  }

  // ── Charge une page et résout les vidéos ──────────────────────────────────
  Future<List<FeedItem>> _loadPage(
    RemoteApiClient client,
    String sourceId, {
    required int page,
  }) async {
    logger.log(_tag, 'Chargement page $page pour source $sourceId');

    // Résolution du sourceId (une seule fois, on garde le résultat)
    if (_resolvedSourceId.isEmpty) {
      await _resolveSource(client, sourceId);
    }

    final List<dynamic> rawItems =
        await _fetchItems(client, _resolvedSourceId, page: page);
    logger.log(_tag, '${rawItems.length} items bruts reçus (page $page)');

    if (rawItems.isEmpty) {
      if (page == 1) {
        throw Exception(
            'La source "$_resolvedSourceName" ne retourne aucun contenu');
      }
      _hasMore = false;
      return [];
    }

    const maxItemsPerPage = 8;
    final toResolve = rawItems.take(maxItemsPerPage).toList();

    final items = <FeedItem>[];
    final baseIndex = (page - 1) * maxItemsPerPage;
    for (var i = 0; i < toResolve.length; i++) {
      final raw = toResolve[i] as Map<String, dynamic>;
      final link = raw['link'] as String? ?? raw['url'] as String? ?? '';

      String? videoUrl = _tryExtractVideoFromLink(link);
      if (videoUrl == null && link.isNotEmpty) {
        videoUrl =
            await _resolveVideoUrl(client, _resolvedSourceId, link) ?? '';
      }
      if (videoUrl == null || videoUrl.isEmpty) continue;

      items.add(_toFeedItem(raw, _resolvedSourceName, videoUrl, baseIndex + i));
    }

    logger.log(_tag,
        '${items.length} items avec vidéo résolue (page $page)');

    // Si la page a retourné moins d'items que le max → plus de pages
    if (rawItems.length < maxItemsPerPage) {
      _hasMore = false;
    }

    if (page == 1) {
      if (items.isEmpty) {
        throw Exception(
            'Aucune vidéo jouable trouvée pour "$_resolvedSourceName"');
      }
      ref.read(serverStatusProvider.notifier).update(
          '✓ Connecté à "$_resolvedSourceName" — ${items.length} vidéos');
    }

    return items;
  }

  // ── Résout l'ID de source (match par id ou name, fallback première) ───────
  Future<void> _resolveSource(
      RemoteApiClient client, String sourceId) async {
    String resolved = sourceId;
    String name = sourceId;

    try {
      final sources =
          await client.sources().timeout(const Duration(seconds: 15));
      logger.log(_tag, '${sources.length} sources reçues');
      if (sources.isNotEmpty) {
        final match = sources.cast<Map<String, dynamic>>().where((s) {
          return s['id']?.toString() == sourceId ||
              s['name']?.toString() == sourceId;
        }).firstOrNull;

        if (match != null) {
          resolved = match['id']?.toString() ?? sourceId;
          name = match['name'] as String? ?? resolved;
        } else {
          final first = sources.cast<Map<String, dynamic>>().first;
          resolved = first['id']?.toString() ?? sourceId;
          name = first['name'] as String? ?? resolved;
        }
      }
    } catch (e) {
      logger.log(_tag, 'Impossible de lister les sources: $e');
    }

    _resolvedSourceId = resolved;
    _resolvedSourceName = name;
  }

  // ── loadMore : appelé par le feed quand l'index approche de la fin ────────
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _resolvedSourceId.isEmpty) return;
    final client = _client ?? ref.read(remoteClientProvider);
    if (client == null) return;
    _client = client;

    _isLoadingMore = true;
    ref.read(loadingMoreProvider.notifier).update(true);

    try {
      _page++;
      logger.log(_tag, 'loadMore → page $_page');
      final newItems =
          await _loadPage(client, _resolvedSourceId, page: _page);
      if (newItems.isEmpty) return; // _hasMore déjà mis à false

      final current = state.requireValue;
      state = AsyncData([...current, ...newItems]);
      logger.log(_tag,
          'Feed étendu : ${current.length} + ${newItems.length} = ${current.length + newItems.length}');
    } catch (e, st) {
      logger.error(_tag, 'loadMore erreur page $_page: $e', st);
      NtfyLogger.warn('loadMore page $_page échoué: $e');
      _page--; // rollback pour pouvoir retenter
    } finally {
      _isLoadingMore = false;
      ref.read(loadingMoreProvider.notifier).update(false);
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _tryExtractVideoFromLink(String link) {
    if (link.isEmpty || !link.startsWith('{')) return null;
    try {
      final parsed = json.decode(link) as Map<String, dynamic>;
      final hd = parsed['hd'] as String?;
      final sd = parsed['sd'] as String?;
      final url = parsed['url'] as String?;
      if (hd != null && hd.isNotEmpty) return hd;
      if (sd != null && sd.isNotEmpty) return sd;
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> _fetchItems(
      RemoteApiClient client, String sourceId, {int page = 1}) async {
    try {
      final data = await client
          .popular(sourceId, page: page)
          .timeout(const Duration(seconds: 20));
      final items = _extractItems(data);
      if (items.isNotEmpty) return items;
    } catch (_) {}

    try {
      final data = await client
          .latest(sourceId, page: page)
          .timeout(const Duration(seconds: 20));
      return _extractItems(data);
    } catch (e) {
      throw Exception('popular + latest ont échoué pour $sourceId : $e');
    }
  }

  List<dynamic> _extractItems(Map<String, dynamic> data) =>
      data['list'] as List? ??
      data['mangas'] as List? ??
      data['items'] as List? ??
      data['data'] as List? ??
      data['results'] as List? ??
      data['videos'] as List? ??
      data['posts'] as List? ??
      data['content'] as List? ??
      [];

  Future<String?> _resolveVideoUrl(
      RemoteApiClient client, String sourceId, String itemLink) async {
    try {
      final data = await client
          .videos(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));
      final vids = data['videos'] as List? ?? [];
      final url = _bestVideoUrl(vids);
      if (url != null) return url;
    } catch (_) {}

    try {
      final detail = await client
          .detail(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));
      final chapters = detail['chapters'] as List? ??
          detail['episodes'] as List? ??
          detail['chapter_list'] as List? ??
          [];
      if (chapters.isEmpty) return null;

      final ep = chapters.length == 1 ? chapters.first : chapters.last;
      final epUrl = ep['url'] as String? ??
          ep['link'] as String? ??
          ep['chapterUrl'] as String? ??
          '';
      if (epUrl.isEmpty) return null;

      final vidData = await client
          .videos(sourceId, epUrl)
          .timeout(const Duration(seconds: 20));
      return _bestVideoUrl(vidData['videos'] as List? ?? []);
    } catch (_) {}

    return null;
  }

  String? _bestVideoUrl(List<dynamic> videos) {
    if (videos.isEmpty) return null;
    for (final pref in ['1080', '720', '480']) {
      for (final v in videos) {
        final q = (v['quality'] as String? ?? '').toLowerCase();
        final url = v['url'] as String? ?? '';
        if (q.contains(pref) && url.isNotEmpty) return url;
      }
    }
    final url = videos.first['url'] as String? ?? '';
    return url.isNotEmpty ? url : null;
  }

  FeedItem _toFeedItem(
    Map<String, dynamic> raw,
    String sourceName,
    String videoUrl,
    int index,
  ) {
    String thumbnail = '';
    final link = raw['link'] as String? ?? '';
    if (link.startsWith('{')) {
      try {
        final parsed = json.decode(link) as Map<String, dynamic>;
        thumbnail = parsed['poster'] as String? ?? '';
      } catch (_) {}
    }
    if (thumbnail.isEmpty) {
      thumbnail = raw['imageUrl'] as String? ??
          raw['cover'] as String? ??
          raw['thumbnail'] as String? ??
          raw['image'] as String? ??
          '';
    }

    final title = raw['name'] as String? ??
        raw['title'] as String? ??
        raw['chapter_name'] as String? ??
        'Sans titre';
    final author = raw['author'] as String? ??
        raw['creator'] as String? ??
        sourceName;
    final genreStr = raw['genre'] as String? ??
        raw['genres'] as String? ??
        raw['tags'] as String? ??
        (raw['description'] as String? ?? '');

    final seed = title.hashCode.abs();
    final rng = Random(seed + index);

    return FeedItem(
      id: raw['link'] as String? ?? raw['url'] as String? ?? 'item_$index',
      videoUrl: videoUrl,
      thumbnailUrl: thumbnail,
      title: title,
      authorUsername: '@${author.toLowerCase().replaceAll(' ', '_')}',
      authorAvatar: thumbnail,
      likes: 1000 + rng.nextInt(499000),
      comments: 100 + rng.nextInt(9900),
      shares: 200 + rng.nextInt(19800),
      bookmarks: 50 + rng.nextInt(4950),
      hashtags: _parseGenres(genreStr).take(4).toList(),
      soundName: '♪ ${title.split(' ').take(3).join(' ')} — Watchtower',
    );
  }

  List<String> _parseGenres(String genreStr) {
    if (genreStr.isEmpty) return ['watchtower'];
    return genreStr
        .split(RegExp(r'[,|/·]'))
        .map((g) => g.trim().toLowerCase().replaceAll(' ', ''))
        .where((g) => g.isNotEmpty && g.length <= 20)
        .toList();
  }
}
