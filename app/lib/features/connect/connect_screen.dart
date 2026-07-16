import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/remote/remote_client.dart';
import 'package:watchtower_real/remote/remote_config_provider.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _urlCtrl = TextEditingController(text: 'http://192.168.1.70:4567');
  final _keyCtrl = TextEditingController(text: 'GOAEgKfGI6mIBSuoDo5DNc6mOe29ot2u');
  final _formKey = GlobalKey<FormState>();
  bool _testing = false;
  String? _error;
  String? _successMsg;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _testing = true; _error = null; _successMsg = null; });
    try {
      final client = RemoteApiClient(
        baseUrl: _urlCtrl.text.trim(),
        apiKey: _keyCtrl.text.trim(),
      );
      final sources = await client.sources().timeout(const Duration(seconds: 8));
      final names = sources.map((s) => s['id'] ?? s['name'] ?? '?').join(', ');
      setState(() => _successMsg = '✅ Connecté ! Sources : $names');
    } catch (e) {
      setState(() => _error = 'Connexion échouée : $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(remoteConfigProvider.notifier).save(
      baseUrl: _urlCtrl.text.trim(),
      apiKey: _keyCtrl.text.trim(),
    );
    if (mounted) context.go('/');
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
                // Logo / title
                Row(
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
                ),
                const SizedBox(height: AppTokens.space32),

                // Info card
                Container(
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
                          'Active le Mode Distant dans Watchtower sur ton téléphone. '
                          'Utilise le lien local si tu es sur le même réseau Wi-Fi.',
                          style: AppTokens.bodyS.copyWith(color: AppTokens.colorTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space24),

                // URL field
                _FieldLabel('URL du serveur'),
                const SizedBox(height: AppTokens.space8),
                TextFormField(
                  controller: _urlCtrl,
                  style: AppTokens.bodyM.copyWith(color: Colors.white),
                  keyboardType: TextInputType.url,
                  decoration: _inputDecoration(
                    hint: 'http://192.168.x.x:4567',
                    icon: Icons.link,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'URL requise' : null,
                ),
                const SizedBox(height: AppTokens.space16),

                // API Key field
                _FieldLabel('Clé API'),
                const SizedBox(height: AppTokens.space8),
                TextFormField(
                  controller: _keyCtrl,
                  style: AppTokens.bodyM.copyWith(color: Colors.white),
                  decoration: _inputDecoration(
                    hint: 'Clé API Bearer',
                    icon: Icons.vpn_key_outlined,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Clé API requise' : null,
                ),
                const SizedBox(height: AppTokens.space24),

                // Error / success
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1A1A),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Text(_error!,
                        style: AppTokens.bodyS.copyWith(color: Colors.redAccent)),
                  ),
                if (_successMsg != null)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A1A),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Text(_successMsg!,
                        style: AppTokens.bodyS.copyWith(color: Colors.greenAccent)),
                  ),
                if (_error != null || _successMsg != null)
                  const SizedBox(height: AppTokens.space16),

                // Test button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _testing ? null : _test,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTokens.colorBrandCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
                    ),
                    child: _testing
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTokens.colorBrandCyan),
                          )
                        : Text('Tester la connexion',
                            style: AppTokens.bodyM.copyWith(
                                color: AppTokens.colorBrandCyan)),
                  ),
                ),
                const SizedBox(height: AppTokens.space12),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.colorBrand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
                    ),
                    child: Text('Se connecter',
                        style: AppTokens.bodyM.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: AppTokens.space16),

                // Skip (demo mode)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(remoteConfigProvider.notifier).save(
                        baseUrl: '',
                        apiKey: '',
                      );
                      if (mounted) context.go('/');
                    },
                    child: Text('Utiliser en mode démo (sans serveur)',
                        style: AppTokens.bodyS.copyWith(
                            color: AppTokens.colorTextSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _FieldLabel(String text) => Text(
        text,
        style: AppTokens.labelM.copyWith(color: AppTokens.colorTextSecondary),
      );

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
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
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: AppTokens.space16),
    );
  }
}
