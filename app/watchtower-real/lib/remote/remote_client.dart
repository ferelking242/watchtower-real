import 'dart:convert';
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
  Future<List<dynamic>> sources() async => (await _get('/api/sources'))['sources'] ?? [];
  Future<Map<String, dynamic>> popular(String sourceId, {int page = 1}) =>
      _get('/api/sources/$sourceId/popular?page=$page');
  Future<Map<String, dynamic>> latest(String sourceId, {int page = 1}) =>
      _get('/api/sources/$sourceId/latest?page=$page');
  Future<Map<String, dynamic>> search(String sourceId, String query, {int page = 1}) =>
      _get('/api/sources/$sourceId/search?query=${Uri.encodeComponent(query)}&page=$page');
  Future<Map<String, dynamic>> detail(String sourceId, String itemUrl) =>
      _get('/api/sources/$sourceId/detail?url=${Uri.encodeComponent(itemUrl)}');
  Future<Map<String, dynamic>> videos(String sourceId, String episodeUrl) =>
      _get('/api/sources/$sourceId/videos?url=${Uri.encodeComponent(episodeUrl)}');

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 429) throw Exception('Rate limited (429)');
    if (res.statusCode == 401) throw Exception('Unauthorized (401) — check API key');
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}: ${res.body}');
    return json.decode(res.body) as Map<String, dynamic>;
  }
}
