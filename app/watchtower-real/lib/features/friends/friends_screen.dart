import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBgBase,
      appBar: AppBar(
        backgroundColor: colorBgBase,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Amis',
          style: TextStyle(
            color: colorTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: colorTextPrimary),
            tooltip: 'Ajouter un ami',
            onPressed: () {},
          ),
        ],
      ),

      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ── Tabs ──────────────────────────────────────────────────────
            const TabBar(
              indicatorColor: colorBrand,
              indicatorWeight: 2,
              labelColor: colorTextPrimary,
              unselectedLabelColor: colorTextSecondary,
              labelStyle: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: 'Suggérés'),
                Tab(text: 'Abonnements'),
              ],
            ),
            const Divider(color: colorDivider, height: 1),

            // ── Contenu ───────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _SuggestedList(),
                  _FollowingList(),
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
// Liste suggestions (placeholder)
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: List.generate(8, (i) => _FriendTile(index: i)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Liste abonnements (placeholder vide)
// ─────────────────────────────────────────────────────────────────────────────
class _FollowingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.group_outlined, size: 52, color: colorTextSecondary),
          SizedBox(height: 16),
          Text(
            'Aucun abonnement',
            style: TextStyle(
              color: colorTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les comptes que tu suis apparaîtront ici.',
            style: TextStyle(color: colorTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile utilisateur
// ─────────────────────────────────────────────────────────────────────────────
class _FriendTile extends StatefulWidget {
  const _FriendTile({required this.index});
  final int index;

  @override
  State<_FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends State<_FriendTile> {
  bool _following = false;

  static const _names = [
    'alice_media', 'bob_streams', 'celeste_v', 'dan_reel',
    'eva_content', 'fox_studio', 'grace_watch', 'hiro_film',
  ];
  static const _followers = [
    '12,4K', '8,1K', '245K', '3,2K',
    '89,5K', '1,2M', '45,3K', '678K',
  ];

  @override
  Widget build(BuildContext context) {
    final name = _names[widget.index % _names.length];
    final followers = _followers[widget.index % _followers.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorBgCard,
              border: Border.all(color: colorDivider),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: colorTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nom + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$name',
                    style: const TextStyle(
                      color: colorTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text('$followers abonnés',
                    style: const TextStyle(
                      color: colorTextSecondary, fontSize: 12,
                    )),
              ],
            ),
          ),

          // Bouton follow
          GestureDetector(
            onTap: () => setState(() => _following = !_following),
            child: AnimatedContainer(
              duration: durationNormal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: _following ? Colors.transparent : colorBrand,
                border: Border.all(
                  color: _following ? colorTextSecondary : colorBrand,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _following ? 'Abonné' : 'S\'abonner',
                style: TextStyle(
                  color: _following ? colorTextSecondary : colorTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
