import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:reel/core/theme/tokens.dart';

class LiveMultiScreen extends StatefulWidget {
  const LiveMultiScreen({super.key, this.hostId});
  final String? hostId;

  @override
  State<LiveMultiScreen> createState() => _LiveMultiScreenState();
}

class _LiveMultiScreenState extends State<LiveMultiScreen> {
  final _chatCtrl = TextEditingController();

  static final _guests = [
    _Guest('https://i.pravatar.cc/150?img=40', 'Michel Lewe', true, 6),
    _Guest('https://i.pravatar.cc/150?img=41', 'Chef d\'œuvr...', false, 15),
    _Guest('https://i.pravatar.cc/150?img=42', 'fofana100', false, 12),
    _Guest('https://i.pravatar.cc/150?img=43', 'Juslain Meya...', false, 10),
    _Guest('https://i.pravatar.cc/150?img=44', 'darelboyabé', false, 14),
    _Guest('https://i.pravatar.cc/150?img=45', 'Chic stone', false, 4),
    _Guest('https://i.pravatar.cc/150?img=46', 'Munoko poub...', false, 4),
    _Guest('https://i.pravatar.cc/150?img=47', 'Bernard Impo...', false, 6),
  ];

  static final _messages = [
    _ChatMsg('https://i.pravatar.cc/150?img=50', 'jolesjuisondemo', 'alia alia'),
    _ChatMsg('', 'SUCCESSFUL', 'a rejoint', isSystem: true),
  ];

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _LiveHeader(onClose: () => Navigator.pop(context)),

            // ── Ranking label ────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 4),
                    Text(
                      'Classement quotidien',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Sponsor banner ───────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Match Mania',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text('M', style: TextStyle(
                      color: Color(0xFFE040FB),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Guest grid ───────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _GuestGrid(guests: _guests),
            ),

            // ── Chat messages ────────────────────────────────────────
            Expanded(
              flex: 3,
              child: _ChatMessages(messages: _messages),
            ),

            // ── Input bar ────────────────────────────────────────────
            _ChatBar(ctrl: _chatCtrl),
          ],
        ),
      ),
    );
  }
}

// ─── Guest data ───────────────────────────────────────────────────────────────
class _Guest {
  const _Guest(this.avatar, this.name, this.isHost, this.score);
  final String avatar, name;
  final bool isHost;
  final int score;
}

// ─── Chat message data ────────────────────────────────────────────────────────
class _ChatMsg {
  const _ChatMsg(this.avatar, this.username, this.message,
      {this.isSystem = false});
  final String avatar, username, message;
  final bool isSystem;
}

// ─── Live header ──────────────────────────────────────────────────────────────
class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          // Host avatar
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=40'),
          ),
          const SizedBox(width: 8),

          // Host info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MC FILS G...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '4.8K j\'aime',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // + Suivre button
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFE2C55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 14),
                SizedBox(width: 2),
                Text(
                  'Suivre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Seat icons
          const Icon(Icons.chair_outlined, color: Colors.white60, size: 20),
          const SizedBox(width: 6),
          const Icon(Icons.chair_outlined, color: Colors.white60, size: 20),
          const SizedBox(width: 8),

          // Viewer count
          const Row(
            children: [
              Icon(Icons.group_outlined, color: Colors.white60, size: 16),
              SizedBox(width: 3),
              Text('31',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 10),

          // Close
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest grid ───────────────────────────────────────────────────────────────
class _GuestGrid extends StatelessWidget {
  const _GuestGrid({required this.guests});
  final List<_Guest> guests;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Host (large left)
          Expanded(
            flex: 3,
            child: _GuestCell(guest: guests[0]),
          ),
          const SizedBox(width: 4),
          // 6 small guests (2×3 grid)
          Expanded(
            flex: 2,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: 6,
              itemBuilder: (_, i) => _GuestCell(guest: guests[i + 1]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest cell ───────────────────────────────────────────────────────────────
class _GuestCell extends StatelessWidget {
  const _GuestCell({required this.guest});
  final _Guest guest;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: guest.avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A2040)),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xBB000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // Host badge
          if (guest.isHost)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3897F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '👤 Hôte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // Score top-left (non-host)
          if (!guest.isHost)
            Positioned(
              top: 4,
              left: 4,
              child: Row(
                children: [
                  const Icon(Icons.lens_blur_rounded,
                      size: 10, color: Color(0xFF69C9D0)),
                  const SizedBox(width: 2),
                  Text(
                    '${guest.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          // Name bottom
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              guest.name,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat messages ────────────────────────────────────────────────────────────
class _ChatMessages extends StatelessWidget {
  const _ChatMessages({required this.messages});
  final List<_ChatMsg> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        if (m.isSystem) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.waving_hand_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${m.username} ${m.message}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundImage:
                    m.avatar.isNotEmpty ? NetworkImage(m.avatar) : null,
                backgroundColor: Colors.white24,
                child: m.avatar.isEmpty
                    ? Text(m.username[0],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11))
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${m.username} ',
                        style: AppTokens.labelM
                            .copyWith(color: AppTokens.colorBrandCyan),
                      ),
                      TextSpan(
                        text: m.message,
                        style: AppTokens.bodyS.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Chat bar ─────────────────────────────────────────────────────────────────
class _ChatBar extends StatelessWidget {
  const _ChatBar({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // Input
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: ctrl,
                style: AppTokens.bodyS.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ajouter un comme...',
                  hintStyle: AppTokens.bodyS.copyWith(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Invités icon
          _BarBtn(
            icon: Icons.people_outline_rounded,
            label: 'Invités...',
          ),
          const SizedBox(width: 12),

          // Rose gift
          _BarBtn(
            icon: Icons.local_florist_outlined,
            label: 'Rose',
            color: const Color(0xFFFE2C55),
          ),
          const SizedBox(width: 12),

          // Cadeau
          _BarBtn(
            icon: Icons.card_giftcard_rounded,
            label: 'Cadeau',
          ),
          const SizedBox(width: 12),

          // Share count
          GestureDetector(
            onTap: () {},
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.reply_rounded,
                    color: Colors.white,
                    size: 22,
                    textDirection: TextDirection.rtl),
                Text('11',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  const _BarBtn({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.white, size: 22),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
