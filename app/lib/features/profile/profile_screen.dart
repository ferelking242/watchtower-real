import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/core/widgets/follow_button.dart';
import 'package:watchtower_real/core/widgets/video_thumbnail.dart';
import 'package:watchtower_real/features/feed/providers/feed_provider.dart';
import 'package:watchtower_real/remote/remote_config_provider.dart';
import 'package:watchtower_real/remote/remote_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _avatar = 'https://i.pravatar.cc/150?img=20';
  final _username = '@watchtower_user';
  final _bio = '📱 Watchtower Real · Flutter dev · 🌍 Paris';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = widget.userId == null;
    final configAsync = ref.watch(remoteConfigProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isOwn
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _username,
          style: AppTokens.titleM.copyWith(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          if (isOwn) ...[
            // Indicateur de mode (vert = remote, gris = mock)
            configAsync.when(
              data: (cfg) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: cfg.isConfigured ? 'Mode distant actif' : 'Mode démo (mock)',
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: cfg.isConfigured ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Bouton 3 barres — config serveur
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              tooltip: 'Configuration serveur',
              onPressed: () => _showConfigSheet(context),
            ),
          ],
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              avatar: _avatar,
              username: _username,
              bio: _bio,
              isOwn: isOwn,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                labelColor: Colors.black,
                unselectedLabelColor: AppTokens.colorTextSecondaryDark,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on, size: 20)),
                  Tab(icon: Icon(Icons.lock_outline, size: 20)),
                  Tab(icon: Icon(Icons.repeat, size: 20)),
                  Tab(icon: Icon(Icons.bookmark_border, size: 20)),
                  Tab(icon: Icon(Icons.favorite_border, size: 20)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _VideoGrid(seed: 'profile_main'),
            _PrivateGrid(),
            _VideoGrid(seed: 'profile_repost'),
            _VideoGrid(seed: 'profile_saved'),
            _VideoGrid(seed: 'profile_liked'),
          ],
        ),
      ),
    );
  }

  void _showConfigSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfigSheet(
        onSaved: () {
          ref.invalidate(feedProvider);
        },
      ),
    );
  }
}

// ─── Config Sheet ─────────────────────────────────────────────────────────────

class _ConfigSheet extends ConsumerStatefulWidget {
  const _ConfigSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends ConsumerState<_ConfigSheet> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _TestStatus _status = _TestStatus.idle;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill from current config
    final cfg = ref.read(remoteConfigProvider).value;
    if (cfg != null) {
      _urlCtrl.text = cfg.baseUrl;
      _keyCtrl.text = cfg.apiKey;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _status = _TestStatus.loading;
      _statusMsg = 'Test en cours…';
    });
    try {
      final client = RemoteApiClient(
        baseUrl: _urlCtrl.text.trim(),
        apiKey: _keyCtrl.text.trim(),
      );
      final result = await client.ping().timeout(const Duration(seconds: 8));
      setState(() {
        _status = _TestStatus.ok;
        _statusMsg = '✅ Connexion OK — ${result['status'] ?? result['message'] ?? 'pong'}';
      });
    } catch (e) {
      setState(() {
        _status = _TestStatus.error;
        _statusMsg = '❌ Échec : $e';
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(remoteConfigProvider.notifier).save(
          baseUrl: _urlCtrl.text.trim(),
          apiKey: _keyCtrl.text.trim(),
        );
    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Config sauvegardée — feed rechargé en mode distant'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _reset() async {
    await ref.read(remoteConfigProvider.notifier).save(baseUrl: '', apiKey: '');
    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config effacée — retour en mode démo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.dns_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Configuration serveur', style: AppTokens.titleM.copyWith(color: Colors.black)),
                const Spacer(),
                // Status dot
                if (_status != _TestStatus.idle)
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: _status == _TestStatus.ok
                        ? Colors.green
                        : _status == _TestStatus.loading
                            ? Colors.orange
                            : Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ton serveur Watchtower (ex: http://192.168.1.10:8080)',
              style: AppTokens.bodyS.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // URL field
            TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'URL du serveur',
                hintText: 'http://192.168.1.10:8080',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL requise';
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasScheme) return 'URL invalide (http://…)';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // API Key field
            TextFormField(
              controller: _keyCtrl,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Clé API (optionnelle)',
                hintText: 'Laisse vide si pas d\'auth',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (_statusMsg.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _status == _TestStatus.ok
                      ? Colors.green.shade50
                      : _status == _TestStatus.error
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(
                    color: _status == _TestStatus.ok
                        ? Colors.green.shade200
                        : _status == _TestStatus.error
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                  ),
                ),
                child: Text(
                  _statusMsg,
                  style: AppTokens.bodyS.copyWith(
                    color: _status == _TestStatus.ok
                        ? Colors.green.shade800
                        : _status == _TestStatus.error
                            ? Colors.red.shade800
                            : Colors.orange.shade800,
                  ),
                ),
              ),
            if (_statusMsg.isNotEmpty) const SizedBox(height: 16),

            // Buttons row
            Row(
              children: [
                // Reset
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Effacer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Test
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _status == _TestStatus.loading ? null : _test,
                    icon: _status == _TestStatus.loading
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering, size: 16),
                    label: const Text('Tester'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black54),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Save
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Sauvegarder'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _TestStatus { idle, loading, ok, error }

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatar,
    required this.username,
    required this.bio,
    required this.isOwn,
  });
  final String avatar, username, bio;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CachedNetworkImage(
            imageUrl: avatar,
            imageBuilder: (_, img) => CircleAvatar(radius: 44, backgroundImage: img),
            placeholder: (_, __) => const CircleAvatar(radius: 44, backgroundColor: Colors.black12),
            errorWidget: (_, __, ___) => const CircleAvatar(radius: 44, backgroundColor: Colors.black12),
          ),
          const SizedBox(height: 12),

          // Username
          Text(username, style: AppTokens.titleM.copyWith(color: Colors.black, fontSize: 18)),
          const SizedBox(height: 4),

          // Bio
          Text(bio,
              style: AppTokens.bodyS.copyWith(color: AppTokens.colorTextSecondaryDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(label: 'Abonnements', value: '142'),
              const SizedBox(width: 24),
              _Stat(label: 'Abonnés', value: '8 412'),
              const SizedBox(width: 24),
              _Stat(label: 'J\'aime', value: '52 K'),
            ],
          ),
          const SizedBox(height: 16),

          // Follow / Edit button
          if (isOwn)
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                minimumSize: const Size(double.infinity, 38),
              ),
              child: Text('Modifier le profil',
                  style: AppTokens.bodyM.copyWith(fontWeight: FontWeight.w600, color: Colors.black)),
            )
          else
            const FollowButton(),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTokens.titleM.copyWith(color: Colors.black, fontSize: 18)),
        Text(label, style: AppTokens.bodyS.copyWith(color: AppTokens.colorTextSecondaryDark)),
      ],
    );
  }
}

// ─── Grids ────────────────────────────────────────────────────────────────────

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 18,
      itemBuilder: (_, i) => VideoThumbnail(
        url: 'https://picsum.photos/seed/${seed}_$i/200/356',
      ),
    );
  }
}

class _PrivateGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text('Contenu privé', style: AppTokens.bodyM.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}

// ─── Tab bar delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, color: AppTokens.colorDividerLight),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
