import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../../../core/theme/tokens.dart';
import '../models/feed_item.dart';

class FeedOverlayBottom extends StatelessWidget {
  const FeedOverlayBottom({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Username
        Row(
          children: [
            Text(
              item.authorUsername,
              style: const TextStyle(
                color: colorTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                ],
              ),
            ),
            if (item.isFollowing) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: colorTextPrimary, width: 1),
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
                child: const Text(
                  'Suivi(e)',
                  style: TextStyle(
                    color: colorTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // Description + hashtags
        _ExpandableDescription(item: item),
        const SizedBox(height: 10),

        // Son (marquee)
        _SoundTicker(soundName: item.soundName),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description avec hashtags en couleur
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.item});
  final FeedItem item;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[
      TextSpan(
        text: widget.item.title,
        style: const TextStyle(
          color: colorTextPrimary,
          fontSize: 13,
          height: 1.4,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
          ],
        ),
      ),
      const TextSpan(text: ' '),
      ...widget.item.hashtags.map(
        (tag) => TextSpan(
          text: '#$tag ',
          style: const TextStyle(
            color: Color(0xFFE8E8E8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ),
      ),
    ];

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: RichText(
        maxLines: _expanded ? null : 2,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        text: TextSpan(children: spans),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticker (marquee) pour le nom du son
// ─────────────────────────────────────────────────────────────────────────────
class _SoundTicker extends StatelessWidget {
  const _SoundTicker({required this.soundName});
  final String soundName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.music_note_rounded,
            color: colorTextPrimary, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 18,
            child: Marquee(
              text: soundName,
              style: const TextStyle(
                color: colorTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
              scrollAxis: Axis.horizontal,
              velocity: 40,
              blankSpace: 80,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 0,
            ),
          ),
        ),
      ],
    );
  }
}
