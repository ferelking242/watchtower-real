import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../data/mock_feed.dart';
import '../../../remote/remote_client.dart';
import '../../../remote/remote_config_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Index de la page active
// ─────────────────────────────────────────────────────────────────────────────
final currentFeedIndexProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Tab actif : 0 = "Pour toi", 1 = "Suivis"
// ─────────────────────────────────────────────────────────────────────────────
final feedTabProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Statut de connexion serveur (pour la bannière d'info)
// ─────────────────────────────────────────────────────────────────────────────
final serverStatusProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Feed items — utilise l'API Watchtower si configurée, sinon mock
// ─────────────────────────────────────────────────────────────────────────────
final feedItemsProvider =
    AsyncNotifierProvider<FeedNotifier, List<FeedItem>>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    final client = ref.watch(remoteClientProvider);

    if (client == null) {
      debugPrint('[FeedProvider] Pas de client configuré → données mock');
      ref.read(serverStatusProvider.notifier).state =
          'Aucun serveur configuré — données démo';
      return mockFeedItems;
    }

    debugPrint('[FeedProvider] Client configuré (${client.baseUrl}) → chargement réel');
    ref.read(serverStatusProvider.notifier).state = null;
    return _loadFromServer(client);
  }

  // ── Reload manuel ─────────────────────────────────────────────────────────
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // ── Chargement depuis le serveur ──────────────────────────────────────────
  Future<List<FeedItem>> _loadFromServer(RemoteApiClient client) async {
    // 1. Lister les sources
    debugPrint('[FeedProvider] GET /api/sources…');
    final List<dynamic> sources;
    try {
      sources = await client.sources().timeout(const Duration(seconds: 15));
      debugPrint('[FeedProvider] ${sources.length} sources reçues');
      for (var s in sources) {
        debugPrint(
            '  source: id=${s["id"]} name="${s["name"]}" lang=${s["lang"]} type=${s["itemType"]}');
      }
    } catch (e, st) {
      debugPrint('[FeedProvider] Erreur /api/sources: $e\n$st');
      throw Exception('Impossible de contacter le serveur : $e');
    }

    if (sources.isEmpty) {
      debugPrint('[FeedProvider] Aucune source disponible → mock');
      ref.read(serverStatusProvider.notifier).state =
          'Aucune source disponible sur le serveur';
      return mockFeedItems;
    }

    // 2. Choisir la meilleure source (préférer vidéo)
    final source = _pickSource(sources);
    final sourceId = _sourceId(source);
    final sourceName = source['name'] as String? ?? sourceId;
    debugPrint('[FeedProvider] Source choisie: "$sourceName" (id=$sourceId)');

    // 3. Charger popular, fallback latest sur toute erreur
    final List<dynamic> rawItems = await _fetchItems(client, sourceId);
    debugPrint('[FeedProvider] ${rawItems.length} items bruts reçus');

    if (rawItems.isEmpty) {
      debugPrint('[FeedProvider] Aucun item → mock');
      ref.read(serverStatusProvider.notifier).state =
          'Source "$sourceName" ne retourne aucun contenu';
      return mockFeedItems;
    }

    // 4. Résoudre les URLs vidéo pour les N premiers items
    const maxItems = 8;
    final toResolve = rawItems.take(maxItems).toList();
    debugPrint('[FeedProvider] Résolution des URLs vidéo pour ${toResolve.length} items…');

    final items = <FeedItem>[];
    for (var i = 0; i < toResolve.length; i++) {
      final raw = toResolve[i] as Map<String, dynamic>;
      final link = raw['link'] as String? ?? raw['url'] as String? ?? '';
      debugPrint('[FeedProvider] [$i] link="${link.substring(0, link.length.clamp(0, 80))}"');

      String videoUrl = '';
      if (link.isNotEmpty) {
        videoUrl = await _resolveVideoUrl(client, sourceId, link) ?? '';
      }

      if (videoUrl.isEmpty) {
        debugPrint('[FeedProvider] [$i] Pas de vidéo → ignoré');
        continue;
      }

      items.add(_toFeedItem(raw, source, videoUrl, i));
    }

    debugPrint('[FeedProvider] ${items.length} items avec vidéo résolue');

    if (items.isEmpty) {
      debugPrint('[FeedProvider] Aucune vidéo résolue → mock');
      ref.read(serverStatusProvider.notifier).state =
          'Impossible de résoudre les vidéos pour "$sourceName"';
      return mockFeedItems;
    }

    ref.read(serverStatusProvider.notifier).state =
        '✓ Connecté à "$sourceName" — ${items.length} vidéos';
    return items;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Choisit la meilleure source (préfère itemType=video/anime)
  Map<String, dynamic> _pickSource(List<dynamic> sources) {
    final videoTypes = {'video', 'anime', 'live', 'movie'};
    for (final s in sources.cast<Map<String, dynamic>>()) {
      final type = (s['itemType'] as String? ?? '').toLowerCase();
      if (videoTypes.any((t) => type.contains(t))) return s;
    }
    return sources.first as Map<String, dynamic>;
  }

  /// Extrait l'identifiant à utiliser dans les routes API
  String _sourceId(Map<String, dynamic> source) {
    // Préférer name (le serveur fait findSource par name aussi)
    final name = source['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return source['id']?.toString() ?? '1';
  }

  /// Charge popular, retombe sur latest sur TOUTE erreur (y compris 404)
  Future<List<dynamic>> _fetchItems(
      RemoteApiClient client, String sourceId) async {
    // Essai popular
    try {
      debugPrint('[FeedProvider] GET popular/$sourceId…');
      final data = await client
          .popular(sourceId)
          .timeout(const Duration(seconds: 20));
      final items = _extractItems(data);
      debugPrint('[FeedProvider] popular/$sourceId → ${items.length} items');
      if (items.isNotEmpty) return items;
      debugPrint('[FeedProvider] popular vide → essai latest');
    } catch (e) {
      debugPrint('[FeedProvider] popular/$sourceId erreur: $e → essai latest');
    }

    // Fallback latest
    try {
      debugPrint('[FeedProvider] GET latest/$sourceId…');
      final data = await client
          .latest(sourceId)
          .timeout(const Duration(seconds: 20));
      final items = _extractItems(data);
      debugPrint('[FeedProvider] latest/$sourceId → ${items.length} items');
      return items;
    } catch (e) {
      debugPrint('[FeedProvider] latest/$sourceId erreur: $e');
      throw Exception('popular + latest ont échoué pour $sourceId : $e');
    }
  }

  /// Extrait la liste d'items de la réponse API
  List<dynamic> _extractItems(Map<String, dynamic> data) =>
      data['mangas'] as List? ??
      data['items'] as List? ??
      data['data'] as List? ??
      data['results'] as List? ??
      data['videos'] as List? ??
      data['posts'] as List? ??
      data['content'] as List? ??
      [];

  /// Tente de résoudre une URL vidéo jouable depuis un lien d'item
  Future<String?> _resolveVideoUrl(
      RemoteApiClient client, String sourceId, String itemLink) async {
    // Étape 1 : videos directement sur le lien de l'item
    try {
      debugPrint('[FeedProvider] videos?url=${itemLink.substring(0, itemLink.length.clamp(0, 80))}');
      final data =
          await client.videos(sourceId, itemLink).timeout(const Duration(seconds: 20));
      final vids = data['videos'] as List? ?? [];
      debugPrint('[FeedProvider] ${vids.length} streams directs');
      for (var v in vids) {
        debugPrint('  stream: quality="${v["quality"]}" url="${(v["url"] as String? ?? "").substring(0, (v["url"] as String? ?? "").length.clamp(0, 80))}"');
      }
      final url = _bestVideoUrl(vids);
      if (url != null) return url;
    } catch (e) {
      debugPrint('[FeedProvider] videos direct échoué: $e');
    }

    // Étape 2 : detail → premier épisode → videos
    try {
      debugPrint('[FeedProvider] detail?url=${itemLink.substring(0, itemLink.length.clamp(0, 80))}');
      final detail = await client
          .detail(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));

      final chapters = detail['chapters'] as List? ??
          detail['episodes'] as List? ??
          detail['chapter_list'] as List? ??
          [];
      debugPrint('[FeedProvider] ${chapters.length} chapitres/épisodes dans detail');

      if (chapters.isEmpty) return null;

      // Prendre le dernier épisode (le plus récent) ou le premier si un seul
      final ep = chapters.length == 1 ? chapters.first : chapters.last;
      final epUrl = ep['url'] as String? ??
          ep['link'] as String? ??
          ep['chapterUrl'] as String? ??
          '';
      if (epUrl.isEmpty) {
        debugPrint('[FeedProvider] Épisode sans URL');
        return null;
      }
      debugPrint('[FeedProvider] Episode URL: ${epUrl.substring(0, epUrl.length.clamp(0, 80))}');

      final vidData = await client
          .videos(sourceId, epUrl)
          .timeout(const Duration(seconds: 20));
      final vids = vidData['videos'] as List? ?? [];
      debugPrint('[FeedProvider] ${vids.length} streams via detail');
      return _bestVideoUrl(vids);
    } catch (e) {
      debugPrint('[FeedProvider] detail flow échoué: $e');
    }

    return null;
  }

  /// Choisit la meilleure qualité vidéo disponible
  String? _bestVideoUrl(List<dynamic> videos) {
    if (videos.isEmpty) return null;
    // Préférer 720p ou 1080p, sinon prendre le premier
    for (final pref in ['1080', '720', '480']) {
      for (final v in videos) {
        final q = (v['quality'] as String? ?? '').toLowerCase();
        if (q.contains(pref)) {
          final url = v['url'] as String? ?? '';
          if (url.isNotEmpty) return url;
        }
      }
    }
    final url = videos.first['url'] as String? ?? '';
    return url.isNotEmpty ? url : null;
  }

  /// Convertit un item brut de l'API en FeedItem
  FeedItem _toFeedItem(
      Map<String, dynamic> raw, Map<String, dynamic> source, String videoUrl, int index) {
    final title = raw['name'] as String? ??
        raw['title'] as String? ??
        raw['chapter_name'] as String? ??
        'Sans titre';
    final thumbnail = raw['imageUrl'] as String? ??
        raw['cover'] as String? ??
        raw['thumbnail'] as String? ??
        raw['image'] as String? ??
        '';
    final author = raw['author'] as String? ??
        source['name'] as String? ??
        'Watchtower';
    final genreStr = raw['genre'] as String? ??
        raw['genres'] as String? ??
        raw['tags'] as String? ??
        '';
    final hashtags = _parseGenres(genreStr);

    // Stats décoratives (déterministiques selon le titre)
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
      hashtags: hashtags.take(4).toList(),
      soundName: '♪ ${title.split(' ').take(3).join(' ')} — Watchtower',
    );
  }

  List<String> _parseGenres(String genreStr) {
    if (genreStr.isEmpty) return ['watchtower'];
    return genreStr
        .split(RegExp(r'[,|/]'))
        .map((g) => g.trim().toLowerCase().replaceAll(' ', ''))
        .where((g) => g.isNotEmpty && g.length <= 20)
        .toList();
  }
}
