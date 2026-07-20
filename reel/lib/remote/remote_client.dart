import 'package:watchtower_client/watchtower_client.dart';
import 'package:reel/utils/log/app_file_logger.dart';
import 'package:reel/remote/app_version.dart';

/// Adaptateur mince sur [WatchtowerClient] (SDK officiel Watchtower).
///
/// Conserve exactement l'interface de l'ancien [RemoteApiClient] afin que
/// [FeedNotifier] et le reste du code n'aient pas à changer.
///
/// Bénéfices obtenus via le SDK :
/// - Retry exponentiel automatique (300 ms → 600 ms → 1200 ms, max 3 tentatives)
/// - Injection automatique du header auth (`X-Api-Key`)
/// - Timeout configurable par requête
/// - Exceptions typées ([WatchtowerNetworkException], [WatchtowerApiException])
class RemoteApiClient {
  RemoteApiClient({required this.baseUrl, this.apiKey})
      : _client = WatchtowerClient(
          url: baseUrl,
          apiKey: apiKey,
          timeout: const Duration(seconds: 20),
          maxRetries: 3,
        );

  final String baseUrl;
  final String? apiKey;
  final WatchtowerClient _client;

  static const _tag = 'RemoteClient';

  // ── Health check ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> ping() async {
    logger.log(_tag, 'GET /api/ping [v${AppVersion.headerValue}]');
    try {
      // getRaw conserve tous les champs (status, version, …)
      return await _client.getRaw('/api/ping');
    } catch (_) {
      return {'status': 'error'};
    }
  }

  // ── Sources ─────────────────────────────────────────────────────────────────

  /// Retourne la liste brute des sources (List de Map).
  ///
  /// Délègue à [WatchtowerClient.sources.list()] (typé) et reconvertit en
  /// [List<Map<String,dynamic>>] pour ne pas casser [FeedNotifier._resolveSource].
  Future<List<dynamic>> sources() async {
    logger.log(_tag, 'GET /api/sources');
    final list = await _client.sources.list();
    return list.map((s) => s.toJson()).toList();
  }

  // ── Contenu — via getRaw (conserve TOUS les champs de la réponse) ────────────
  //
  // On passe par client.getRaw() plutôt que par les endpoints typés afin que
  // FeedNotifier._extractItems puisse chercher n'importe quelle clé retournée
  // par le serveur (list, mangas, items, data, results, videos, posts, content…).

  Future<Map<String, dynamic>> popular(String sourceId, {int page = 1}) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/popular?page=$page');
    return _client.getRaw(
      '/api/sources/$sourceId/popular',
      queryParams: {'page': page.toString()},
    );
  }

  Future<Map<String, dynamic>> latest(String sourceId, {int page = 1}) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/latest?page=$page');
    return _client.getRaw(
      '/api/sources/$sourceId/latest',
      queryParams: {'page': page.toString()},
    );
  }

  Future<Map<String, dynamic>> search(
      String sourceId, String query, {int page = 1}) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/search?q=$query&page=$page');
    return _client.getRaw(
      '/api/sources/$sourceId/search',
      queryParams: {'q': query, 'page': page.toString()},
    );
  }

  Future<Map<String, dynamic>> detail(
      String sourceId, String itemUrl) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/detail');
    return _client.getRaw(
      '/api/sources/$sourceId/detail',
      queryParams: {'url': itemUrl},
    );
  }

  Future<Map<String, dynamic>> videos(
      String sourceId, String episodeUrl) async {
    logger.log(_tag, 'GET /api/sources/$sourceId/videos');
    return _client.getRaw(
      '/api/sources/$sourceId/videos',
      queryParams: {'url': episodeUrl},
    );
  }

  /// Libère les ressources du client HTTP sous-jacent.
  void dispose() => _client.close();
}
