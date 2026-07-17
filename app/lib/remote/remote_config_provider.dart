import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchtower_real/remote/remote_client.dart';

const _kBaseUrl  = 'wt_real_server_url';
const _kApiKey   = 'wt_real_api_key';
const _kSourceId = 'wt_real_source_id';

class RemoteConfig {
  const RemoteConfig({
    this.baseUrl  = '',
    this.apiKey   = '',
    this.sourceId = '',
  });
  final String baseUrl;
  final String apiKey;
  /// The source ID chosen by the user (e.g. "redgift", "miraculum").
  /// Empty means "auto-pick" (first source returned by the server).
  final String sourceId;

  bool get isConfigured => baseUrl.isNotEmpty;

  RemoteConfig copyWith({String? baseUrl, String? apiKey, String? sourceId}) =>
      RemoteConfig(
        baseUrl:  baseUrl  ?? this.baseUrl,
        apiKey:   apiKey   ?? this.apiKey,
        sourceId: sourceId ?? this.sourceId,
      );
}

class RemoteConfigNotifier extends AsyncNotifier<RemoteConfig> {
  @override
  Future<RemoteConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    return RemoteConfig(
      baseUrl:  prefs.getString(_kBaseUrl)  ?? '',
      apiKey:   prefs.getString(_kApiKey)   ?? '',
      sourceId: prefs.getString(_kSourceId) ?? '',
    );
  }

  Future<void> save({
    required String baseUrl,
    required String apiKey,
    String sourceId = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl,  baseUrl);
    await prefs.setString(_kApiKey,   apiKey);
    await prefs.setString(_kSourceId, sourceId);
    state = AsyncData(RemoteConfig(
      baseUrl:  baseUrl,
      apiKey:   apiKey,
      sourceId: sourceId,
    ));
  }
}

final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfig>(
        RemoteConfigNotifier.new);

final remoteClientProvider = Provider<RemoteApiClient?>((ref) {
  final config = ref.watch(remoteConfigProvider).value;
  if (config == null || !config.isConfigured) return null;
  return RemoteApiClient(baseUrl: config.baseUrl, apiKey: config.apiKey);
});
