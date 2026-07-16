import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/core/widgets/live_badge.dart';

class LiveMultiScreen extends StatefulWidget {
  const LiveMultiScreen({super.key, this.hostId});
  final String? hostId;

  @override
  State<LiveMultiScreen> createState() => _LiveMultiScreenState();
}

class _LiveMultiScreenState extends State<LiveMultiScreen> {
  final _chatCtrl = TextEditingController();

  static final _guests = [
    ('https://i.pravatar.cc/150?img=40', 'HôtePrincipal', true, 1240),
    ('https://i.pravatar.cc/150?img=41', 'Invité1', false, 340),
    ('https://i.pravatar.cc/150?img=42', 'Invité2', false, 210),
    ('https://i.pravatar.cc/150?img=43', 'Invité3', false, 98),
    ('https://i.pravatar.cc/150?img=44', 'Invité4', false, 76),
    ('https://i.pravatar.cc/150?img=45', 'Invité5', false, 45),
    ('https://i.pravatar.cc/150?img=46', 'Invité6', false, 22),
  ];

  static final _messages = [
    ('https://i.pravatar.cc/150?img=50', '@user1', '🔥 Incroyable !'),
    ('https://i.pravatar.cc/150?img=51', '@user2', 'Bonjour depuis Paris 👋'),
    ('https://i.pravatar.cc/150?img=52', '@user3', "T'es le meilleur !"),
    ('https://i.pravatar.cc/150?img=53', '@user4', '❤️❤️❤️'),
    ('https://i.pravatar.cc/150?img=54', '@user5', 'First time watching, love it'),
  ];

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _LiveHeader(),
            const SizedBox(height: AppTokens.space8),

            // Guest grid
            Expanded(
              flex: 5,
              child: _GuestGrid(guests: _guests),
            ),

            // Chat messages
            Expanded(
              flex: 3,
              child: _ChatMessages(messages: _messages),
            ),

            // Input bar
            _ChatBar(ctrl: _chatCtrl),
          ],
        ),
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12, vertical: AppTokens.space8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=40'),
          ),
          const SizedBox(width: AppTokens.space8),
          const LiveBadge(small: true),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HôtePrincipal',
                    style: AppTokens.labelM.copyWith(color: Colors.white)),
                Text('12.4K spectateurs',
                    style: AppTokens.caption.copyWith(
                        color: AppTokens.colorTextSecondary)),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          Text('4.2M', style: AppTokens.caption.copyWith(color: Colors.white)),
          const SizedBox(width: AppTokens.space12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestGrid extends StatelessWidget {
  const _GuestGrid({required this.guests});
  final List<(String, String, bool, int)> guests;

  @override
  Widget build(BuildContext context) {
    // Layout: 1 big (host) on left + 2x3 grid on right
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
      child: Row(
        children: [
          // Main host (large)
          Expanded(
            flex: 3,
            child: _GuestCell(
              avatar: guests[0].$1,
              name: guests[0].$2,
              isHost: true,
              score: guests[0].$4,
            ),
          ),
          const SizedBox(width: 4),
          // 6 small guests
          Expanded(
            flex: 2,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 6,
              itemBuilder: (context, i) => _GuestCell(
                avatar: guests[i + 1].$1,
                name: guests[i + 1].$2,
                isHost: false,
                score: guests[i + 1].$4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCell extends StatelessWidget {
  const _GuestCell({
    required this.avatar,
    required this.name,
    required this.isHost,
    required this.score,
  });
  final String avatar, name;
  final bool isHost;
  final int score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: avatar,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFF1A2040)),
          ),
          // Gradient bottom
          Positioned(
            bottom: 0, left: 0, right: 0, height: 50,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),
          if (isHost)
            Positioned(
              top: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.colorBrand,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Text('Hôte',
                    style: AppTokens.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          Positioned(
            bottom: 4, left: 4,
            child: Text(name,
                style: AppTokens.caption.copyWith(color: Colors.white)),
          ),
          Positioned(
            bottom: 4, right: 4,
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined,
                    size: 10, color: Colors.amber),
                const SizedBox(width: 2),
                Text('$score',
                    style: AppTokens.caption.copyWith(color: Colors.amber)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessages extends StatelessWidget {
  const _ChatMessages({required this.messages});
  final List<(String, String, String)> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12, vertical: AppTokens.space8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final (avatar, user, msg) = messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(avatar)),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: '$user ',
                          style: AppTokens.labelM.copyWith(
                              color: AppTokens.colorBrandCyan)),
                      TextSpan(
                          text: msg,
                          style: AppTokens.bodyS.copyWith(
                              color: Colors.white)),
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

class _ChatBar extends StatelessWidget {
  const _ChatBar({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.space12, AppTokens.space8, AppTokens.space12, AppTokens.space12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
              child: TextField(
                controller: ctrl,
                style: AppTokens.bodyS.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Commenter...',
                  hintStyle: AppTokens.bodyS.copyWith(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
          const SizedBox(width: AppTokens.space12),
          const Icon(Icons.people_outline, color: Colors.white, size: 24),
          const SizedBox(width: AppTokens.space12),
          const Icon(Icons.share, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
