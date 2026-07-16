import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Minimal HTTP client for the Watchtower remote API server.
/// Configure [baseUrl] and [apiKey] before use.
class RemoteApiClient {
  RemoteApiClient({required this.baseUrl, this.apiKey});

  final String baseUrl;
  final String? apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

  Future<Map<String, dynamic>> ping() => _get('/api/ping');

  Future<List<dynamic>> sources() async =>
      (await _get('/api/sources'))['sources'] as List<dynamic>? ?? [];

  Future<Map<String, dynamic>> popular(String sourceId, {int page = 1}) =>
      _get('/api/sources/$sourceId/popular?page=$page');

  Future<Map<String, dynamic>> latest(String sourceId, {int page = 1}) =>
      _get('/api/sources/$sourceId/latest?page=$page');

  Future<Map<String, dynamic>> search(String sourceId, String query, {int page = 1}) =>
      _get('/api/sources/$sourceId/search?q=${Uri.encodeComponent(query)}&page=$page');

  Future<Map<String, dynamic>> detail(String sourceId, String itemUrl) =>
      _get('/api/sources/$sourceId/detail?url=${Uri.encodeComponent(itemUrl)}');

  Future<Map<String, dynamic>> videos(String sourceId, String episodeUrl) =>
      _get('/api/sources/$sourceId/videos?url=${Uri.encodeComponent(episodeUrl)}');

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[RemoteClient] GET $uri');
    final t0 = DateTime.now();

    final http.Response res;
    try {
      res = await http.get(uri, headers: _headers);
    } catch (e) {
      debugPrint('[RemoteClient] NETWORK ERROR: $e');
      rethrow;
    }

    final ms = DateTime.now().difference(t0).inMilliseconds;
    debugPrint('[RemoteClient] ${res.statusCode} $path (${ms}ms) — ${res.body.length} bytes');

    if (res.statusCode == 429) {
      debugPrint('[RemoteClient] Rate limited (429)');
      throw Exception('Rate limited (429) — attends un moment');
    }
    if (res.statusCode == 401) {
      debugPrint('[RemoteClient] Unauthorized (401) — vérifie la clé API');
      throw Exception('Unauthorized (401) — clé API incorrecte');
    }
    if (res.statusCode != 200) {
      debugPrint('[RemoteClient] HTTP Error ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 500))}');
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    try {
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      debugPrint('[RemoteClient] JSON parse error: $e\nBody: ${res.body.substring(0, res.body.length.clamp(0, 200))}');
      throw Exception('Réponse JSON invalide: $e');
    }
  }
}
