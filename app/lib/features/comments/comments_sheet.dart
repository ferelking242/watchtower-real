import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';

// ─── Mock comment model ───────────────────────────────────────────────────────
class _Comment {
  const _Comment({
    required this.id,
    required this.avatar,
    required this.username,
    required this.text,
    required this.date,
    required this.likes,
    this.dislikes = 0,
    this.replies = const [],
  });
  final String id, avatar, username, text, date;
  final int likes, dislikes;
  final List<_Comment> replies;
}

// ─── Mock data ────────────────────────────────────────────────────────────────
List<_Comment> _mockComments(int count) => [
      const _Comment(
        id: '1',
        avatar: 'https://i.pravatar.cc/150?img=10',
        username: 'Abdou',
        text: '«Je suis complètement d\'accord avec toi sur ce point 🔥»',
        date: '06-18',
        likes: 1909,
        replies: [
          _Comment(
            id: '1r1',
            avatar: 'https://i.pravatar.cc/150?img=20',
            username: 'Idriss',
            text: 'Exactement ce que je pensais aussi 💯',
            date: '06-18',
            likes: 140,
          ),
        ],
      ),
      const _Comment(
        id: '2',
        avatar: 'https://i.pravatar.cc/150?img=30',
        username: 'lsv_Requiem🔱',
        text: 'T\'as vu la dernière ? Complètement incroyable bcp plus fort que prévu',
        date: '06-18',
        likes: 10,
        replies: [],
      ),
      const _Comment(
        id: '3',
        avatar: 'https://i.pravatar.cc/150?img=40',
        username: 'pedяo🇲🇦',
        text: 'Il arrive et il flop sa première saison complète. On attendait mieux 😅',
        date: '06-18',
        likes: 140,
        replies: [
          _Comment(
            id: '3r1',
            avatar: 'https://i.pravatar.cc/150?img=50',
            username: 'Samba_75',
            text: 'Bah il a quand même mis 18 buts hein 😂',
            date: '06-19',
            likes: 74,
          ),
        ],
      ),
      const _Comment(
        id: '4',
        avatar: 'https://i.pravatar.cc/150?img=60',
        username: 'Adamyousfi',
        text: 'Ça fait longtemps qu\'il a rattrapé, il a ralenti juste pour que l\'autre puisse le rattraper un peu',
        date: '06-18',
        likes: 45,
        replies: [],
      ),
      const _Comment(
        id: '5',
        avatar: 'https://i.pravatar.cc/150?img=15',
        username: 'Alexis_V',
        text: 'Mdrr ce commentaire section c\'est du délire 💀',
        date: '06-20',
        likes: 302,
        replies: [],
      ),
      const _Comment(
        id: '6',
        avatar: 'https://i.pravatar.cc/150?img=25',
        username: 'fatoumaD',
        text: 'J\'adore le contenu continue comme ça 🙏🏾❤️',
        date: '06-21',
        likes: 88,
        replies: [],
      ),
    ];

// ─── Public API ───────────────────────────────────────────────────────────────
void showCommentsSheet(BuildContext context, {int commentCount = 0}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (_) => _CommentsSheet(commentCount: commentCount),
  );
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.commentCount});
  final int commentCount;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late final List<_Comment> _comments;
  final _inputCtrl = TextEditingController();
  bool _showSort = false;
  String _sort = 'Pertinence';
  final Set<String> _expanded = {};
  final Set<String> _liked = {};
  final Set<String> _disliked = {};

  @override
  void initState() {
    super.initState();
    _comments = _mockComments(widget.commentCount);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}K';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showSort = !_showSort),
                    child: Row(
                      children: [
                        Text(
                          '${widget.commentCount} commentaires',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.sort_rounded,
                            size: 20, color: Colors.black54),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 24, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Sort popover ─────────────────────────────────────────
            if (_showSort)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    _SortItem(
                      label: 'Pertinence',
                      active: _sort == 'Pertinence',
                      onTap: () => setState(() { _sort = 'Pertinence'; _showSort = false; }),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SortItem(
                      label: 'Les plus récents',
                      active: _sort == 'Les plus récents',
                      onTap: () => setState(() { _sort = 'Les plus récents'; _showSort = false; }),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SortItem(
                      label: 'Avec média',
                      active: _sort == 'Avec média',
                      onTap: () => setState(() { _sort = 'Avec média'; _showSort = false; }),
                    ),
                  ],
                ),
              ),

            // ── Comment list ─────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _comments.length,
                itemBuilder: (_, i) => _buildComment(_comments[i], false),
              ),
            ),

            // ── Input bar ────────────────────────────────────────────
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 12, right: 12,
                top: 8,
                bottom: 8 + bottom,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=99'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _inputCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ajouter un commentaire…',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.photo_camera_outlined,
                        size: 22, color: Colors.black54),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.emoji_emotions_outlined,
                        size: 22, color: Colors.black54),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('@',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(_Comment c, bool isReply) {
    final isLiked = _liked.contains(c.id);
    final isDisliked = _disliked.contains(c.id);
    final expandedReplies = _expanded.contains(c.id);

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 56 : 16,
        right: 16,
        top: 10,
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundImage: NetworkImage(c.avatar),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(c.username,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                // Text
                Text(c.text,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.4)),
                const SizedBox(height: 6),
                // Meta row
                Row(
                  children: [
                    Text(c.date,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('Répondre',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                // Expand replies
                if (!isReply && c.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (expandedReplies) {
                        _expanded.remove(c.id);
                      } else {
                        _expanded.add(c.id);
                      }
                    }),
                    child: Text(
                      expandedReplies
                          ? 'Masquer les réponses ∧'
                          : 'Afficher ${c.replies.length} réponse${c.replies.length > 1 ? 's' : ''} ∨',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),
          // Like / dislike
          Column(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (isLiked) {
                    _liked.remove(c.id);
                  } else {
                    _liked.add(c.id);
                    _disliked.remove(c.id);
                  }
                }),
                child: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: isLiked ? const Color(0xFFFE2C55) : Colors.black38,
                ),
              ),
              if (c.likes > 0)
                Text(_fmt(c.likes + (isLiked ? 1 : 0)),
                    style: const TextStyle(fontSize: 10, color: Colors.black38)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() {
                  if (isDisliked) {
                    _disliked.remove(c.id);
                  } else {
                    _disliked.add(c.id);
                    _liked.remove(c.id);
                  }
                }),
                child: Icon(
                  isDisliked
                      ? Icons.thumb_down_rounded
                      : Icons.thumb_down_outlined,
                  size: 18,
                  color: isDisliked ? Colors.black87 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortItem extends StatelessWidget {
  const _SortItem(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400)),
            const Spacer(),
            if (active)
              const Icon(Icons.check_rounded, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
