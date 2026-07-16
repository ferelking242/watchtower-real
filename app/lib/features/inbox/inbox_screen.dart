import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Boîte de réception',
            style: AppTokens.titleM.copyWith(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: AppTokens.colorTextSecondaryDark,
          labelStyle: AppTokens.labelM,
          tabs: const [
            Tab(text: 'Tout'),
            Tab(text: 'Non lu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _NotificationList(showAll: true),
          _NotificationList(showAll: false),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.showAll});
  final bool showAll;

  static final _items = [
    _NotifItem(
      avatar: 'https://i.pravatar.cc/150?img=30',
      text: '**@urban_explorer** a aimé ta vidéo',
      time: '2h',
      type: _NotifType.like,
      unread: true,
    ),
    _NotifItem(
      avatar: 'https://i.pravatar.cc/150?img=31',
      text: '**@nature_vibes** te suit maintenant',
      time: '4h',
      type: _NotifType.follow,
      unread: true,
    ),
    _NotifItem(
      avatar: 'https://i.pravatar.cc/150?img=32',
      text: '**@food_art** a commenté : « Magnifique ! »',
      time: '6h',
      type: _NotifType.comment,
      unread: false,
    ),
    _NotifItem(
      avatar: 'https://i.pravatar.cc/150?img=33',
      text: '**@dance_crew** a mentionné dans une vidéo',
      time: '12h',
      type: _NotifType.mention,
      unread: false,
    ),
    _NotifItem(
      avatar: 'https://i.pravatar.cc/150?img=34',
      text: '**@tech_tips** et 23 autres ont aimé ta vidéo',
      time: '1j',
      type: _NotifType.like,
      unread: false,
    ),
    _NotifItem(
      avatar: 'https://i.pravatar.cc/150?img=35',
      text: '**@travel_with_me** a partagé ta vidéo',
      time: '2j',
      type: _NotifType.share,
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = showAll ? _items : _items.where((i) => i.unread).toList();
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none,
                size: 64, color: AppTokens.colorTextSecondaryDark),
            const SizedBox(height: AppTokens.space16),
            Text('Aucune notification non lue',
                style: AppTokens.bodyM.copyWith(
                    color: AppTokens.colorTextSecondaryDark)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTokens.colorDividerLight),
      itemBuilder: (context, i) => _NotifTile(item: items[i]),
    );
  }
}

enum _NotifType { like, follow, comment, mention, share }

class _NotifItem {
  const _NotifItem({
    required this.avatar,
    required this.text,
    required this.time,
    required this.type,
    required this.unread,
  });
  final String avatar, text, time;
  final _NotifType type;
  final bool unread;
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});
  final _NotifItem item;

  IconData get _icon {
    switch (item.type) {
      case _NotifType.like:
        return Icons.favorite;
      case _NotifType.follow:
        return Icons.person_add;
      case _NotifType.comment:
        return Icons.chat_bubble;
      case _NotifType.mention:
        return Icons.alternate_email;
      case _NotifType.share:
        return Icons.reply;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case _NotifType.like:
        return AppTokens.colorLike;
      case _NotifType.follow:
        return AppTokens.colorBrand;
      case _NotifType.comment:
        return Colors.blue;
      case _NotifType.mention:
        return Colors.orange;
      case _NotifType.share:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.unread ? const Color(0xFFFFF0F3) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16, vertical: AppTokens.space8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(item.avatar),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: _iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(_icon, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        title: _RichText(item.text),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.time,
                style: AppTokens.labelS.copyWith(
                    color: AppTokens.colorTextSecondaryDark)),
            if (item.unread) ...[
              const SizedBox(height: 4),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppTokens.colorBrand,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  const _RichText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    // Parse **bold** markdown
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        parts.add(TextSpan(
          text: text.substring(last, m.start),
          style: AppTokens.bodyS.copyWith(color: Colors.black),
        ));
      }
      parts.add(TextSpan(
        text: m.group(1),
        style: AppTokens.bodyS.copyWith(
            color: Colors.black, fontWeight: FontWeight.w700),
      ));
      last = m.end;
    }
    if (last < text.length) {
      parts.add(TextSpan(
        text: text.substring(last),
        style: AppTokens.bodyS.copyWith(color: Colors.black),
      ));
    }
    return RichText(text: TextSpan(children: parts));
  }
}
