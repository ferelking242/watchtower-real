import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchtower_real/remote/remote_client.dart';

const _kBaseUrl = 'wt_real_server_url';
const _kApiKey  = 'wt_real_api_key';

class RemoteConfig {
  const RemoteConfig({this.baseUrl = '', this.apiKey = ''});
  final String baseUrl;
  final String apiKey;
  bool get isConfigured => baseUrl.isNotEmpty;
}

class RemoteConfigNotifier extends AsyncNotifier<RemoteConfig> {
  @override
  Future<RemoteConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    return RemoteConfig(
      baseUrl: prefs.getString(_kBaseUrl) ?? '',
      apiKey:  prefs.getString(_kApiKey)  ?? '',
    );
  }

  Future<void> save({required String baseUrl, required String apiKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl);
    await prefs.setString(_kApiKey,  apiKey);
    state = AsyncData(RemoteConfig(baseUrl: baseUrl, apiKey: apiKey));
  }
}

final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfig>(RemoteConfigNotifier.new);

final remoteClientProvider = Provider<RemoteApiClient?>((ref) {
  final config = ref.watch(remoteConfigProvider).valueOrNull;
  if (config == null || !config.isConfigured) return null;
  return RemoteApiClient(baseUrl: config.baseUrl, apiKey: config.apiKey);
});
