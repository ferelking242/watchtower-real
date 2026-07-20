import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../remote/remote_config_provider.dart';
import '../feed/providers/feed_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config    = ref.watch(remoteConfigProvider).asData?.value;
    final isConnected = config != null && config.baseUrl.isNotEmpty;
    final status    = ref.watch(serverStatusProvider);

    return Scaffold(
      backgroundColor: colorBgBase,
      // ── AppBar ──────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: colorBgBase,
        foregroundColor: colorTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: colorTextPrimary),
        title: const Text(
          'Compte',
          style: TextStyle(
            color: colorTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        // 3 barres → ouvre les paramètres serveur
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: colorTextPrimary),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/connect'),
          ),
        ],
      ),

      body: ListView(
        children: [
          // ── Bloc avatar + nom ──────────────────────────────────────────────
          _ProfileHeader(isConnected: isConnected),

          const SizedBox(height: 24),

          // ── Stats ──────────────────────────────────────────────────────────
          const _StatsRow(),

          const SizedBox(height: 8),
          const Divider(color: colorDivider, height: 1),

          // ── Statut serveur ─────────────────────────────────────────────────
          _ServerStatusTile(
            isConnected: isConnected,
            url: config?.baseUrl,
            status: status,
            onTap: () => context.push('/connect'),
          ),

          const Divider(color: colorDivider, height: 1),

          // ── Sections paramètres ────────────────────────────────────────────
          const _SectionHeader('CONTENU'),
          _SettingsTile(
            icon: Icons.source_rounded,
            label: 'Source active',
            value: config?.selectedSourceId.isNotEmpty == true
                ? config!.selectedSourceId
                : 'Non configurée',
            onTap: () => context.push('/connect'),
          ),

          const Divider(color: colorDivider, height: 1),
          const _SectionHeader('COMPTE'),
          _SettingsTile(
            icon: Icons.dns_rounded,
            label: 'Serveur Watchtower',
            value: isConnected ? 'Connecté' : 'Non configuré',
            valueColor: isConnected
                ? const Color(0xFF2ECC71)
                : colorTextSecondary,
            onTap: () => context.push('/connect'),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'À propos de Reel',
            value: 'v1.0.0',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorBgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Reel', style: TextStyle(
              color: colorTextPrimary, fontSize: 20, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            const Text(
              'UI TikTok-style pour Watchtower\nv1.0.0',
              style: TextStyle(color: colorTextSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header profil
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isConnected});
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorBgCard,
                  border: Border.all(
                    color: colorDivider, width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: colorTextSecondary,
                ),
              ),
              // Badge connecté
              if (isConnected)
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorBgBase, width: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '@utilisateur',
            style: TextStyle(
              color: colorTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Watchtower Reel',
            style: TextStyle(color: colorTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats (following / followers / likes)
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _StatItem(value: '0', label: 'Abonnements'),
          _StatDivider(),
          _StatItem(value: '0', label: 'Abonnés'),
          _StatDivider(),
          _StatItem(value: '0', label: 'Likes'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(
          color: colorTextPrimary, fontSize: 18, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          color: colorTextSecondary, fontSize: 12,
        )),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: colorDivider);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile statut serveur
// ─────────────────────────────────────────────────────────────────────────────
class _ServerStatusTile extends StatelessWidget {
  const _ServerStatusTile({
    required this.isConnected,
    required this.onTap,
    this.url,
    this.status,
  });
  final bool isConnected;
  final String? url;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFF555555),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Serveur connecté' : 'Aucun serveur configuré',
                    style: TextStyle(
                      color: isConnected ? colorTextPrimary : colorTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      status!,
                      style: const TextStyle(
                        color: colorTextSecondary, fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (url != null && url!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      url!,
                      style: const TextStyle(
                        color: colorTextSecondary, fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: colorTextSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: colorTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile paramètre générique
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colorTextSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: colorTextPrimary, fontSize: 14),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  color: valueColor ?? colorTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: colorTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
