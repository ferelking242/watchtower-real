import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reel/remote/remote_client.dart';

const _kBaseUrl         = 'wt_real_server_url';
const _kApiKey          = 'wt_real_api_key';
const _kSelectedSource  = 'wt_real_source_id';

/// URL par défaut : vide → l'app demande à l'utilisateur de configurer un serveur.
const kDefaultServerUrl = '';

/// ID RedGIFs par défaut — visible en mode vidéo sans config manuelle.
const kDefaultSourceId = '1920000001';

class RemoteConfig {
  const RemoteConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.selectedSourceId = kDefaultSourceId,
  });
  final String baseUrl;
  final String apiKey;
  final String selectedSourceId;
  bool get isConfigured => baseUrl.isNotEmpty;
}

class RemoteConfigNotifier extends AsyncNotifier<RemoteConfig> {
  @override
  Future<RemoteConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    return RemoteConfig(
      baseUrl:          prefs.getString(_kBaseUrl)        ?? kDefaultServerUrl,
      apiKey:           prefs.getString(_kApiKey)         ?? '',
      selectedSourceId: prefs.getString(_kSelectedSource) ?? kDefaultSourceId,
    );
  }

  Future<void> save({
    required String baseUrl,
    required String apiKey,
    String? selectedSourceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, baseUrl);
    await prefs.setString(_kApiKey,  apiKey);
    if (selectedSourceId != null) {
      await prefs.setString(_kSelectedSource, selectedSourceId);
    }
    state = AsyncData(RemoteConfig(
      baseUrl:          baseUrl,
      apiKey:           apiKey,
      selectedSourceId: selectedSourceId ??
          (state.asData?.value.selectedSourceId ?? kDefaultSourceId),
    ));
  }
}

final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfig>(
        RemoteConfigNotifier.new);

final remoteClientProvider = Provider<RemoteApiClient?>((ref) {
  final config = ref.watch(remoteConfigProvider).asData?.value;
  if (config == null || !config.isConfigured) return null;
  return RemoteApiClient(baseUrl: config.baseUrl, apiKey: config.apiKey);
});
