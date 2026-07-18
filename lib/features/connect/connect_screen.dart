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

  bool _testing  = false;
  bool _saving   = false;
  String? _testResult;
  bool    _testOk = false;

  /// Sources récupérées après un test réussi
  List<Map<String, dynamic>> _sources = [];
  String? _selectedSourceId;

  @override
  void initState() {
    super.initState();
    final config = ref.read(remoteConfigProvider).asData?.value;
    _urlCtrl = TextEditingController(
        text: config?.baseUrl ?? 'http://192.168.1.70:4567');
    _keyCtrl = TextEditingController(text: config?.apiKey ?? '');
    _selectedSourceId = config?.selectedSourceId ?? kDefaultSourceId;
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
    setState(() {
      _testing = true;
      _testResult = null;
      _sources = [];
    });

    try {
      final client = RemoteApiClient(baseUrl: url, apiKey: _keyCtrl.text.trim());

      // Ping
      final result = await client.ping().timeout(const Duration(seconds: 10));

      // Charger les sources disponibles
      final rawSources = await client.sources().timeout(const Duration(seconds: 10));
      final sources = rawSources
          .whereType<Map<String, dynamic>>()
          .where((s) => s['available'] == true)
          .toList();

      setState(() {
        _testOk     = true;
        _testResult = '✓ Serveur OK — ${sources.length} sources disponibles'
            ' (version ${result["version"] ?? "?"})';
        _sources    = sources;
        // Garder la sélection si elle existe, sinon RedGIFs, sinon première
        final savedId = _selectedSourceId ?? kDefaultSourceId;
        final exists  = sources.any((s) => s['id']?.toString() == savedId);
        if (!exists && sources.isNotEmpty) {
          // Chercher RedGIFs en priorité
          final redgifs = sources.firstWhere(
            (s) => (s['name'] as String? ?? '').toLowerCase().contains('redgif'),
            orElse: () => sources.first,
          );
          _selectedSourceId = redgifs['id']?.toString();
        }
      });
    } catch (e) {
      setState(() {
        _testOk     = false;
        _testResult = '✗ Erreur : $e';
        _sources    = [];
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
            baseUrl:          url,
            apiKey:           _keyCtrl.text.trim(),
            selectedSourceId: _selectedSourceId ?? kDefaultSourceId,
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
          style: TextStyle(
              color: colorTextPrimary, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: colorTextPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(space24),
        children: [
          // ── Info ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(space16),
            decoration: BoxDecoration(
              color: colorBgCard,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: const Text(
              'Configure l\'URL de ton serveur Watchtower et la clé API. '
              'Teste la connexion pour choisir quelle source afficher par défaut.',
              style: TextStyle(
                  color: colorTextSecondary, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: space24),

          // ── URL ─────────────────────────────────────────────────────────
          const _Label('URL du serveur'),
          const SizedBox(height: space8),
          _TextField(
            controller: _urlCtrl,
            hint: 'http://192.168.1.70:4567',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: space16),

          // ── Clé API ─────────────────────────────────────────────────────
          const _Label('Clé API (optionnel)'),
          const SizedBox(height: space8),
          _TextField(
            controller: _keyCtrl,
            hint: 'Laisse vide si pas de clé configurée',
            obscure: true,
          ),
          const SizedBox(height: space24),

          // ── Résultat test ────────────────────────────────────────────────
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
                  color: _testOk
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFE74C3C),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: space16),
          ],

          // ── Picker de source (visible après test réussi) ─────────────────
          if (_testOk && _sources.isNotEmpty) ...[
            const _Label('SOURCE PAR DÉFAUT'),
            const SizedBox(height: space8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: colorBgCard,
                borderRadius: BorderRadius.circular(radiusMd),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radiusMd),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _sources.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFF222222)),
                  itemBuilder: (context, index) {
                    final s   = _sources[index];
                    final id  = s['id']?.toString() ?? '';
                    final name = s['name'] as String? ?? id;
                    final lang = s['lang'] as String? ?? '';
                    final nsfw = s['isNsfw'] == true;
                    final selected = id == _selectedSourceId;

                    return InkWell(
                      onTap: () => setState(() => _selectedSourceId = id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: space16, vertical: 12),
                        child: Row(
                          children: [
                            // Indicateur sélection
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? colorBrand
                                      : const Color(0xFF555555),
                                  width: selected ? 5 : 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: selected
                                              ? colorTextPrimary
                                              : colorTextSecondary,
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      if (nsfw) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: colorBrand.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: const Text('18+',
                                              style: TextStyle(
                                                  color: colorBrand,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (lang.isNotEmpty)
                                    Text(lang,
                                        style: const TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: space24),
          ],

          // ── Boutons ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_rounded),
                  label: Text(_testing ? 'Test…' : 'Tester'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorTextPrimary,
                    side: const BorderSide(color: colorTextSecondary),
                    padding:
                        const EdgeInsets.symmetric(vertical: space12),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: space12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusSm)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: space32),

          // ── Section debug ────────────────────────────────────────────────
          const _Label('Debug'),
          const SizedBox(height: space8),
          const _ServerStatusWidget(),
          const SizedBox(height: space12),
          Consumer(
            builder: (context, ref, _) {
              return OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(remoteConfigProvider.notifier)
                      .save(baseUrl: '', apiKey: '');
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
      style:
          const TextStyle(color: colorTextPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: colorTextSecondary, fontSize: 13),
        filled: true,
        fillColor: colorBgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide:
              const BorderSide(color: colorBrand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: space16, vertical: space12),
      ),
    );
  }
}

class _ServerStatusWidget extends ConsumerWidget {
  const _ServerStatusWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverStatusProvider);
    final config = ref.watch(remoteConfigProvider).asData?.value;

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
            style: const TextStyle(
                color: colorTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Clé: ${config?.apiKey.isEmpty == true ? "(aucune)" : "••••••••"}',
            style: const TextStyle(
                color: colorTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Source: ${config?.selectedSourceId ?? kDefaultSourceId}',
            style: const TextStyle(
                color: colorTextSecondary, fontSize: 12),
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
