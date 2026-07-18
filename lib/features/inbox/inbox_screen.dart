import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBgBase,
      appBar: AppBar(
        backgroundColor: colorBgBase,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Boîte de réception',
          style: TextStyle(
            color: colorTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: colorTextPrimary),
            tooltip: 'Tout marquer comme lu',
            onPressed: () {},
          ),
        ],
      ),

      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // ── Tabs ──────────────────────────────────────────────────────
            const TabBar(
              indicatorColor: colorBrand,
              indicatorWeight: 2,
              labelColor: colorTextPrimary,
              unselectedLabelColor: colorTextSecondary,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 13),
              tabs: [
                Tab(text: 'Tout'),
                Tab(text: 'Mentions'),
                Tab(text: 'Activité'),
              ],
            ),
            const Divider(color: colorDivider, height: 1),

            Expanded(
              child: TabBarView(
                children: [
                  _AllNotifications(),
                  _EmptyTab(
                    icon: Icons.alternate_email_rounded,
                    title: 'Aucune mention',
                    subtitle: 'Quand quelqu\'un te mentionne, c\'est ici.',
                  ),
                  _EmptyTab(
                    icon: Icons.favorite_border_rounded,
                    title: 'Aucune activité',
                    subtitle: 'Tes likes et commentaires apparaîtront ici.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toutes les notifs (placeholder)
// ─────────────────────────────────────────────────────────────────────────────
class _AllNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _NotifGroup(title: 'Aujourd\'hui', items: const [
          _NotifItem(
            icon: Icons.favorite_rounded,
            iconColor: Color(0xFFEE1D52),
            text: 'Nouvelle activité sur tes vidéos.',
            time: 'Il y a 2 min',
            unread: true,
          ),
          _NotifItem(
            icon: Icons.person_add_rounded,
            iconColor: Color(0xFF69C9D0),
            text: 'Quelqu\'un s\'est abonné à ton compte.',
            time: 'Il y a 1 h',
            unread: true,
          ),
        ]),
        _NotifGroup(title: 'Cette semaine', items: const [
          _NotifItem(
            icon: Icons.comment_rounded,
            iconColor: Color(0xFFFFFFFF),
            text: 'Un commentaire sur l\'une de tes vidéos.',
            time: 'Lundi',
            unread: false,
          ),
          _NotifItem(
            icon: Icons.share_rounded,
            iconColor: Color(0xFF69C9D0),
            text: 'Ta vidéo a été partagée.',
            time: 'Dimanche',
            unread: false,
          ),
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Groupe de notifs
// ─────────────────────────────────────────────────────────────────────────────
class _NotifGroup extends StatelessWidget {
  const _NotifGroup({required this.title, required this.items});
  final String title;
  final List<_NotifItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: colorTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        ...items,
        const Divider(color: colorDivider, height: 1),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item de notification
// ─────────────────────────────────────────────────────────────────────────────
class _NotifItem extends StatelessWidget {
  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.time,
    required this.unread,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        color: unread ? const Color(0x0AFFFFFF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icône
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBgCard,
                border: Border.all(color: colorDivider),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: colorTextPrimary,
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(time,
                      style: const TextStyle(
                        color: colorTextSecondary, fontSize: 11,
                      )),
                ],
              ),
            ),

            // Point non lu
            if (unread)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorBrand,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab vide
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colorTextSecondary),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                  color: colorTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                  color: colorTextSecondary, fontSize: 13,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
