import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../../../remote/remote_client.dart';
import '../../../remote/remote_config_provider.dart';
import '../../../utils/log/app_file_logger.dart';

const _tag = 'FeedProvider';

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
// Feed items — utilise l'API Watchtower si configurée, sinon []
// ─────────────────────────────────────────────────────────────────────────────
final feedItemsProvider =
    AsyncNotifierProvider<FeedNotifier, List<FeedItem>>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    final client = ref.watch(remoteClientProvider);

    if (client == null) {
      logger.log(_tag, 'Pas de client configuré → liste vide');
      ref.read(serverStatusProvider.notifier).state =
          'Aucun serveur configuré — configure un serveur pour voir du contenu';
      return [];
    }

    logger.log(_tag, 'Client configuré (${client.baseUrl}) → chargement réel');
    ref.read(serverStatusProvider.notifier).state = null;

    // Récupérer l'ID de source sauvegardé (par défaut RedGIFs)
    final config = await ref.read(remoteConfigProvider.future);
    return _loadFromServer(client, config.selectedSourceId);
  }

  // ── Reload manuel ─────────────────────────────────────────────────────────
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  // ── Chargement depuis le serveur ──────────────────────────────────────────
  Future<List<FeedItem>> _loadFromServer(
      RemoteApiClient client, String sourceId) async {
    // 1. Vérifier que la source existe dans la liste
    logger.log(_tag, 'Source cible: $sourceId');
    String resolvedSourceId = sourceId;
    String resolvedSourceName = sourceId;

    try {
      final sources = await client.sources().timeout(const Duration(seconds: 15));
      logger.log(_tag, '${sources.length} sources reçues');
      if (sources.isNotEmpty) {
        // Chercher la source par ID
        final match = sources.cast<Map<String, dynamic>>().where((s) {
          return s['id']?.toString() == sourceId ||
              s['name']?.toString() == sourceId;
        }).firstOrNull;

        if (match != null) {
          resolvedSourceId   = match['id']?.toString() ?? sourceId;
          resolvedSourceName = match['name'] as String? ?? resolvedSourceId;
          logger.log(_tag, 'Source trouvée: "$resolvedSourceName" (id=$resolvedSourceId)');
        } else {
          // Source pas trouvée → prendre la première disponible
          final first = sources.cast<Map<String, dynamic>>().first;
          resolvedSourceId   = first['id']?.toString() ?? sourceId;
          resolvedSourceName = first['name'] as String? ?? resolvedSourceId;
          logger.log(_tag, 'Source $sourceId introuvable → fallback: "$resolvedSourceName"');
        }
      }
    } catch (e) {
      logger.log(_tag, 'Impossible de lister les sources: $e — on essaie quand même avec $sourceId');
    }

    // 2. Charger popular, fallback latest sur toute erreur
    final List<dynamic> rawItems =
        await _fetchItems(client, resolvedSourceId);
    logger.log(_tag, '${rawItems.length} items bruts reçus');

    if (rawItems.isEmpty) {
      logger.log(_tag, 'Aucun item reçu');
      throw Exception('La source "$resolvedSourceName" ne retourne aucun contenu');
    }

    // 3. Résoudre les URLs vidéo pour les N premiers items
    const maxItems = 8;
    final toResolve = rawItems.take(maxItems).toList();
    logger.log(_tag,
        'Résolution des URLs vidéo pour ${toResolve.length} items…');

    final items = <FeedItem>[];
    for (var i = 0; i < toResolve.length; i++) {
      final raw = toResolve[i] as Map<String, dynamic>;
      final link = raw['link'] as String? ?? raw['url'] as String? ?? '';
      logger.log(_tag,
          '[$i] link="${link.substring(0, link.length.clamp(0, 80))}"');

      // Essai 1 : extraire URL vidéo directement depuis le champ link (JSON embarqué)
      String? videoUrl = _tryExtractVideoFromLink(link);

      // Essai 2 : appel API /videos si pas de vidéo dans le link
      if (videoUrl == null && link.isNotEmpty) {
        videoUrl = await _resolveVideoUrl(client, resolvedSourceId, link) ?? '';
      }

      if (videoUrl == null || videoUrl.isEmpty) {
        logger.log(_tag, '[$i] Pas de vidéo → ignoré');
        continue;
      }

      items.add(_toFeedItem(raw, resolvedSourceName, videoUrl, i));
    }

    logger.log(_tag, '${items.length} items avec vidéo résolue');

    if (items.isEmpty) {
      logger.log(_tag, 'Aucune vidéo résolue');
      throw Exception(
          'Aucune vidéo jouable trouvée pour "$resolvedSourceName"');
    }

    ref.read(serverStatusProvider.notifier).state =
        '✓ Connecté à "$resolvedSourceName" — ${items.length} vidéos';
    return items;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Pour les sources qui embarquent les URLs vidéo directement dans le champ
  /// "link" sous forme de JSON (ex: RedGIFs), extrait hd > sd > url sans appel réseau.
  String? _tryExtractVideoFromLink(String link) {
    if (link.isEmpty || !link.startsWith('{')) return null;
    try {
      final Map<String, dynamic> parsed = json.decode(link) as Map<String, dynamic>;
      final hd  = parsed['hd']  as String?;
      final sd  = parsed['sd']  as String?;
      final url = parsed['url'] as String?;
      if (hd != null && hd.isNotEmpty)  return hd;
      if (sd != null && sd.isNotEmpty)  return sd;
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  /// Charge popular, retombe sur latest sur TOUTE erreur (y compris 404)
  Future<List<dynamic>> _fetchItems(
      RemoteApiClient client, String sourceId) async {
    // Essai popular
    try {
      logger.log(_tag, 'GET popular/$sourceId…');
      final data = await client
          .popular(sourceId)
          .timeout(const Duration(seconds: 20));
      final items = _extractItems(data);
      logger.log(_tag, 'popular/$sourceId → ${items.length} items');
      if (items.isNotEmpty) return items;
      logger.log(_tag, 'popular vide → essai latest');
    } catch (e) {
      logger.log(_tag, 'popular/$sourceId erreur: $e → essai latest');
    }

    // Fallback latest
    try {
      logger.log(_tag, 'GET latest/$sourceId…');
      final data = await client
          .latest(sourceId)
          .timeout(const Duration(seconds: 20));
      final items = _extractItems(data);
      logger.log(_tag, 'latest/$sourceId → ${items.length} items');
      return items;
    } catch (e) {
      logger.error(_tag, 'latest/$sourceId erreur: $e');
      throw Exception('popular + latest ont échoué pour $sourceId : $e');
    }
  }

  /// Extrait la liste d'items de la réponse API.
  /// Supporte les enveloppes courantes : list, mangas, items, data, results…
  List<dynamic> _extractItems(Map<String, dynamic> data) =>
      data['list']    as List? ??
      data['mangas']  as List? ??
      data['items']   as List? ??
      data['data']    as List? ??
      data['results'] as List? ??
      data['videos']  as List? ??
      data['posts']   as List? ??
      data['content'] as List? ??
      [];

  /// Tente de résoudre une URL vidéo jouable depuis un lien d'item
  Future<String?> _resolveVideoUrl(
      RemoteApiClient client, String sourceId, String itemLink) async {
    // Étape 1 : videos directement sur le lien de l'item
    try {
      logger.log(_tag,
          'videos?url=${itemLink.substring(0, itemLink.length.clamp(0, 80))}');
      final data = await client
          .videos(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));
      final vids = data['videos'] as List? ?? [];
      logger.log(_tag, '${vids.length} streams directs');
      final url = _bestVideoUrl(vids);
      if (url != null) return url;
    } catch (e) {
      logger.log(_tag, 'videos direct échoué: $e');
    }

    // Étape 2 : detail → premier épisode → videos
    try {
      logger.log(_tag,
          'detail?url=${itemLink.substring(0, itemLink.length.clamp(0, 80))}');
      final detail = await client
          .detail(sourceId, itemLink)
          .timeout(const Duration(seconds: 20));

      final chapters = detail['chapters'] as List? ??
          detail['episodes']     as List? ??
          detail['chapter_list'] as List? ??
          [];
      logger.log(_tag, '${chapters.length} chapitres/épisodes dans detail');
      if (chapters.isEmpty) return null;

      final ep    = chapters.length == 1 ? chapters.first : chapters.last;
      final epUrl = ep['url']        as String? ??
                    ep['link']       as String? ??
                    ep['chapterUrl'] as String? ?? '';
      if (epUrl.isEmpty) return null;

      final vidData = await client
          .videos(sourceId, epUrl)
          .timeout(const Duration(seconds: 20));
      final vids = vidData['videos'] as List? ?? [];
      logger.log(_tag, '${vids.length} streams via detail');
      return _bestVideoUrl(vids);
    } catch (e) {
      logger.log(_tag, 'detail flow échoué: $e');
    }

    return null;
  }

  /// Choisit la meilleure qualité vidéo disponible
  String? _bestVideoUrl(List<dynamic> videos) {
    if (videos.isEmpty) return null;
    for (final pref in ['1080', '720', '480']) {
      for (final v in videos) {
        final q   = (v['quality'] as String? ?? '').toLowerCase();
        final url = v['url'] as String? ?? '';
        if (q.contains(pref) && url.isNotEmpty) return url;
      }
    }
    final url = videos.first['url'] as String? ?? '';
    return url.isNotEmpty ? url : null;
  }

  /// Convertit un item brut de l'API en FeedItem
  FeedItem _toFeedItem(
      Map<String, dynamic> raw,
      String sourceName,
      String videoUrl,
      int index) {
    // Thumbnail : préférer poster embarqué dans le JSON du link
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
          raw['cover']      as String? ??
          raw['thumbnail']  as String? ??
          raw['image']      as String? ?? '';
    }

    final title  = raw['name']         as String? ??
                   raw['title']        as String? ??
                   raw['chapter_name'] as String? ?? 'Sans titre';
    final author = raw['author']       as String? ??
                   raw['creator']      as String? ??
                   sourceName;
    final genreStr = raw['genre']  as String? ??
                     raw['genres'] as String? ??
                     raw['tags']   as String? ??
                     (raw['description'] as String? ?? '');
    final hashtags = _parseGenres(genreStr);

    // Stats décoratives (déterministiques selon le titre)
    final seed = title.hashCode.abs();
    final rng  = Random(seed + index);

    return FeedItem(
      id: raw['link']  as String? ?? raw['url'] as String? ?? 'item_$index',
      videoUrl: videoUrl,
      thumbnailUrl: thumbnail,
      title: title,
      authorUsername: '@${author.toLowerCase().replaceAll(' ', '_')}',
      authorAvatar: thumbnail,
      likes:     1000  + rng.nextInt(499000),
      comments:  100   + rng.nextInt(9900),
      shares:    200   + rng.nextInt(19800),
      bookmarks: 50    + rng.nextInt(4950),
      hashtags: hashtags.take(4).toList(),
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
