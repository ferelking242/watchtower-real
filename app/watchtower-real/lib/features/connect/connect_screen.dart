import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../remote/remote_client.dart';
import '../../remote/remote_config_provider.dart';
import '../feed/providers/feed_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;

  bool _testing = false;
  bool _saving = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(remoteConfigProvider).valueOrNull;
    _urlCtrl = TextEditingController(
        text: config?.baseUrl ?? 'http://192.168.1.70:4567');
    _keyCtrl = TextEditingController(text: config?.apiKey ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _testing = true; _testResult = null; });

    try {
      final client = RemoteApiClient(baseUrl: url, apiKey: _keyCtrl.text.trim());
      final result = await client.ping().timeout(const Duration(seconds: 10));
      setState(() {
        _testOk = true;
        _testResult = '✓ Serveur OK — version ${result["version"] ?? "?"}';
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = '✗ Erreur : $e';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(remoteConfigProvider.notifier).save(
            baseUrl: url,
            apiKey: _keyCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBgBase,
      appBar: AppBar(
        backgroundColor: colorBgCard,
        title: const Text(
          'Connecter un serveur',
          style: TextStyle(color: colorTextPrimary, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: colorTextPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(space24),
        children: [
          // ── Info ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(space16),
            decoration: BoxDecoration(
              color: colorBgCard,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: const Text(
              'Configure l\'URL de ton serveur Watchtower et la clé API. '
              'Sans serveur, l\'app utilise des données de démonstration.',
              style: TextStyle(color: colorTextSecondary, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: space24),

          // ── URL ───────────────────────────────────────────────────────────
          const _Label('URL du serveur'),
          const SizedBox(height: space8),
          _TextField(
            controller: _urlCtrl,
            hint: 'http://192.168.1.70:4567',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: space16),

          // ── Clé API ───────────────────────────────────────────────────────
          const _Label('Clé API (optionnel)'),
          const SizedBox(height: space8),
          _TextField(
            controller: _keyCtrl,
            hint: 'Laisse vide si pas de clé configurée',
            obscure: true,
          ),
          const SizedBox(height: space24),

          // ── Résultat test ─────────────────────────────────────────────────
          if (_testResult != null) ...[
            Container(
              padding: const EdgeInsets.all(space12),
              decoration: BoxDecoration(
                color: _testOk
                    ? const Color(0xFF1A3A2A)
                    : const Color(0xFF3A1A1A),
                borderRadius: BorderRadius.circular(radiusSm),
                border: Border.all(
                  color: _testOk
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFE74C3C),
                  width: 1,
                ),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color:
                      _testOk ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: space16),
          ],

          // ── Boutons ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_rounded),
                  label: Text(_testing ? 'Test…' : 'Tester'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorTextPrimary,
                    side: const BorderSide(color: colorTextSecondary),
                    padding: const EdgeInsets.symmetric(vertical: space12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusSm)),
                  ),
                ),
              ),
              const SizedBox(width: space12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Sauvegarde…' : 'Sauvegarder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorBrand,
                    foregroundColor: colorTextPrimary,
                    padding: const EdgeInsets.symmetric(vertical: space12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusSm)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: space32),

          // ── Section debug ─────────────────────────────────────────────────
          const _Label('Debug'),
          const SizedBox(height: space8),
          const _ServerStatusWidget(),
          const SizedBox(height: space12),
          Consumer(
            builder: (context, ref, _) {
              return OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(remoteConfigProvider.notifier).save(
                      baseUrl: '', apiKey: '');
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Effacer la config (retour mock)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorTextSecondary,
                  side: const BorderSide(color: Color(0xFF444444)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusSm)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets helpers
// ─────────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: colorTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: colorTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: colorTextSecondary, fontSize: 13),
        filled: true,
        fillColor: colorBgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: colorBrand, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
      ),
    );
  }
}

class _ServerStatusWidget extends ConsumerWidget {
  const _ServerStatusWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverStatusProvider);
    final config = ref.watch(remoteConfigProvider).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(space12),
      decoration: BoxDecoration(
        color: colorBgCard,
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'URL: ${config?.baseUrl.isEmpty == true ? "(aucune)" : config?.baseUrl ?? "?"}',
            style: const TextStyle(color: colorTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Clé: ${config?.apiKey.isEmpty == true ? "(aucune)" : "••••••••"}',
            style: const TextStyle(color: colorTextSecondary, fontSize: 12),
          ),
          if (status != null) ...[
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                color: status.startsWith('✓')
                    ? const Color(0xFF2ECC71)
                    : colorTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
