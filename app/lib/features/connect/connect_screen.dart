import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/remote/remote_client.dart';
import 'package:watchtower_real/remote/remote_config_provider.dart';

// ─── Source model ─────────────────────────────────────────────────────────────

class _SourceInfo {
  const _SourceInfo({
    required this.id,
    required this.name,
    required this.lang,
    required this.isNsfw,
    required this.type,
  });
  final String id, name, lang;
  final bool isNsfw;
  final int type;

  factory _SourceInfo.fromJson(Map<dynamic, dynamic> j) {
    final id   = (j['id']   ?? j['name'] ?? '').toString();
    final name = (j['name'] ?? j['id']   ?? '').toString();
    return _SourceInfo(
      id:     id,
      name:   name,
      lang:   (j['lang'] ?? j['language'] ?? '??').toString(),
      isNsfw: j['isNsfw'] == true,
      type:   (j['itemType'] ?? j['type'] ?? 0) as int,
    );
  }

  /// Human-readable type label.
  String get typeLabel => switch (type) {
        1 => 'Vidéo',
        2 => 'Manga',
        3 => 'Roman',
        _ => 'Contenu',
      };

  String get displayName => name.isNotEmpty ? name : id;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  // Step 1 — connection fields
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step 2 — source picker
  List<_SourceInfo> _sources = [];
  String? _selectedSourceId;

  bool _testing = false;
  bool _saving  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill from saved config
    ref.read(remoteConfigProvider.future).then((c) {
      if (!mounted) return;
      _urlCtrl.text = c.baseUrl;
      _keyCtrl.text = c.apiKey;
      _selectedSourceId = c.sourceId.isNotEmpty ? c.sourceId : null;
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  // ── Step 1 : test connection + load sources ─────────────────────────────────
  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _testing = true; _error = null; _sources = []; _selectedSourceId = null; });

    try {
      final client = RemoteApiClient(
        baseUrl: _urlCtrl.text.trim(),
        apiKey:  _keyCtrl.text.trim(),
      );

      // Fetch all sources including NSFW so the user can see them all
      final raw = await client.sources(nsfw: true).timeout(const Duration(seconds: 10));
      final sources = raw
          .whereType<Map>()
          .map((m) => _SourceInfo.fromJson(m))
          .toList()
        ..sort((a, b) {
          // Video sources first, then sort by name
          if (a.type != b.type) return a.type.compareTo(b.type);
          return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        });

      if (sources.isEmpty) throw Exception('Aucune source retournée par le serveur');

      // Auto-select: prefer the saved source, else prefer video+nsfw (RedGIFs-style)
      final savedId  = ref.read(remoteConfigProvider).value?.sourceId ?? '';
      String? autoId = sources.any((s) => s.id == savedId) ? savedId : null;
      autoId ??= sources
          .where((s) => s.isNsfw && s.type == 1)
          .map((s) => s.id)
          .firstOrNull;
      autoId ??= sources
          .where((s) => s.type == 1)
          .map((s) => s.id)
          .firstOrNull;
      autoId ??= sources.first.id;

      setState(() {
        _sources          = sources;
        _selectedSourceId = autoId;
      });
    } catch (e) {
      setState(() => _error = 'Connexion échouée : $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  // ── Step 2 : save config ────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_sources.isEmpty) {
      // Haven't tested yet — run test first
      await _test();
      if (_sources.isEmpty) return;
    }
    if (_selectedSourceId == null) {
      setState(() => _error = 'Sélectionne une source');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(remoteConfigProvider.notifier).save(
        baseUrl:  _urlCtrl.text.trim(),
        apiKey:   _keyCtrl.text.trim(),
        sourceId: _selectedSourceId!,
      );
      if (mounted) context.go('/feed');
    } catch (e) {
      setState(() => _error = 'Erreur lors de la sauvegarde : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.colorBgSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTokens.space32),
                _buildHeader(),
                const SizedBox(height: AppTokens.space32),
                _buildInfoCard(),
                const SizedBox(height: AppTokens.space24),
                _buildUrlField(),
                const SizedBox(height: AppTokens.space16),
                _buildKeyField(),
                const SizedBox(height: AppTokens.space24),
                if (_error != null) ...[
                  _buildError(_error!),
                  const SizedBox(height: AppTokens.space16),
                ],
                // Source picker — shown after successful test
                if (_sources.isNotEmpty) ...[
                  _buildSourcePicker(),
                  const SizedBox(height: AppTokens.space24),
                ],
                _buildTestButton(),
                const SizedBox(height: AppTokens.space12),
                _buildSaveButton(),
                const SizedBox(height: AppTokens.space16),
                _buildSkipButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildHeader() => Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTokens.colorBrand,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: const Icon(Icons.wifi_tethering, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppTokens.space16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Watchtower Real',
                  style: AppTokens.titleL.copyWith(color: Colors.white)),
              Text('Connexion au serveur distant',
                  style: AppTokens.bodyS.copyWith(
                      color: AppTokens.colorTextSecondary)),
            ],
          ),
        ],
      );

  Widget _buildInfoCard() => Container(
        padding: const EdgeInsets.all(AppTokens.space16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: const Color(0xFF2A4A6A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF4A9FD4), size: 18),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                'Entre l\'URL de ton serveur Watchtower et ta clé API, '
                'puis sélectionne la source de contenu à utiliser.',
                style: AppTokens.bodyS.copyWith(
                    color: AppTokens.colorTextSecondary),
              ),
            ),
          ],
        ),
      );

  Widget _buildUrlField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('URL du serveur'),
          const SizedBox(height: AppTokens.space8),
          TextFormField(
            controller: _urlCtrl,
            style: AppTokens.bodyM.copyWith(color: Colors.white),
            keyboardType: TextInputType.url,
            decoration: _inputDeco(
              hint: 'https://my-server.example.com',
              icon: Icons.link,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'URL requise' : null,
          ),
        ],
      );

  Widget _buildKeyField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Clé API (optionnel)'),
          const SizedBox(height: AppTokens.space8),
          TextFormField(
            controller: _keyCtrl,
            style: AppTokens.bodyM.copyWith(color: Colors.white),
            obscureText: true,
            decoration: _inputDeco(
              hint: 'Laisse vide si pas de clé',
              icon: Icons.vpn_key_outlined,
            ),
          ),
        ],
      );

  Widget _buildSourcePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.layers_rounded,
                color: AppTokens.colorBrandCyan, size: 18),
            const SizedBox(width: 6),
            Text('Source de contenu',
                style: AppTokens.labelM.copyWith(
                    color: AppTokens.colorTextSecondary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTokens.colorBrand.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                    color: AppTokens.colorBrand.withOpacity(0.4)),
              ),
              child: Text('${_sources.length} disponible${_sources.length > 1 ? "s" : ""}',
                  style: AppTokens.caption.copyWith(
                      color: AppTokens.colorBrand)),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        ..._sources.map((s) => _SourceTile(
              source: s,
              isSelected: _selectedSourceId == s.id,
              onTap: () => setState(() => _selectedSourceId = s.id),
            )),
      ],
    );
  }

  Widget _buildError(String msg) => Container(
        padding: const EdgeInsets.all(AppTokens.space12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1A1A),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Text(msg,
            style: AppTokens.bodyS.copyWith(color: Colors.redAccent)),
      );

  Widget _buildTestButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: (_testing || _saving) ? null : _test,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTokens.colorBrandCyan),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          ),
          icon: _testing
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTokens.colorBrandCyan))
              : const Icon(Icons.bolt_rounded,
                  color: AppTokens.colorBrandCyan, size: 18),
          label: Text(
            _testing ? 'Test en cours…' : 'Tester et charger les sources',
            style: AppTokens.bodyM.copyWith(color: AppTokens.colorBrandCyan),
          ),
        ),
      );

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_testing || _saving) ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTokens.colorBrand,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Se connecter',
                  style: AppTokens.bodyM.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
        ),
      );

  Widget _buildSkipButton() => Center(
        child: TextButton(
          onPressed: () async {
            await ref.read(remoteConfigProvider.notifier).save(
              baseUrl:  '',
              apiKey:   '',
              sourceId: '',
            );
            if (mounted) context.go('/feed');
          },
          child: Text('Utiliser en mode démo (sans serveur)',
              style: AppTokens.bodyS.copyWith(
                  color: AppTokens.colorTextSecondary)),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: AppTokens.labelM.copyWith(color: AppTokens.colorTextSecondary),
      );

  InputDecoration _inputDeco({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTokens.bodyM.copyWith(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: AppTokens.colorBgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppTokens.colorBrand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: AppTokens.space16),
      );
}

// ─── Source tile ──────────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.isSelected,
    required this.onTap,
  });
  final _SourceInfo source;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: AppTokens.space8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.colorBrand.withOpacity(0.15)
              : AppTokens.colorBgCard,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppTokens.colorBrand
                : const Color(0xFF2A3A4A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTokens.colorBrand
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTokens.colorBrand
                      : Colors.white30,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: AppTokens.space12),

            // Source info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          source.displayName,
                          style: AppTokens.bodyM.copyWith(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (source.isNsfw)
                        _Badge('18+', const Color(0xFFFE2C55)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _Badge(source.typeLabel, AppTokens.colorBrandCyan),
                      const SizedBox(width: 6),
                      _Badge(source.lang.toUpperCase(),
                          Colors.white24),
                    ],
                  ),
                ],
              ),
            ),

            // ID chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
              child: Text(
                source.id,
                style: AppTokens.caption.copyWith(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTokens.caption.copyWith(
            color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
