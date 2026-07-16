import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';
import 'package:watchtower_real/features/feed/data/mock_feed.dart';
import 'package:watchtower_real/features/feed/providers/feed_provider.dart';

// ─── From mock FeedItem ───────────────────────────────────────────────────────
class FeedOverlayBottom extends StatelessWidget {
  const FeedOverlayBottom({super.key, required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return _OverlayContent(
      author: item.author,
      description: item.description,
      hashtags: item.hashtags,
      isPhoto: item.isPhoto,
      photoCount: item.photoUrls.length,
    );
  }
}

// ─── From API model ───────────────────────────────────────────────────────────
class FeedOverlayBottomFromModel extends StatelessWidget {
  const FeedOverlayBottomFromModel({super.key, required this.item});
  final FeedItemModel item;

  @override
  Widget build(BuildContext context) {
    return _OverlayContent(
      author: item.author,
      description: item.title,
      hashtags: item.hashtags,
      isPhoto: item.isPhoto,
      photoCount: item.photoCount,
    );
  }
}

// ─── Shared stateful implementation ──────────────────────────────────────────
class _OverlayContent extends StatefulWidget {
  const _OverlayContent({
    required this.author,
    required this.description,
    required this.hashtags,
    this.isPhoto = false,
    this.photoCount = 0,
  });
  final String author, description;
  final List<String> hashtags;
  final bool isPhoto;
  final int photoCount;

  @override
  State<_OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<_OverlayContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Build full text: description + hashtags
    final tags = widget.hashtags.isNotEmpty
        ? widget.hashtags.map((t) => t.startsWith('#') ? t : '#$t').join(' ')
        : '';
    final fullText =
        tags.isNotEmpty ? '${widget.description} $tags' : widget.description;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Username + photo badge ────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.author,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isPhoto) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera_rounded,
                        color: Colors.white, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      widget.photoCount > 1 ? 'Photos' : 'Photo',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // ── Description + hashtags + voir plus/moins ──────────────
        _ExpandableText(text: fullText),
      ],
    );
  }
}

// ─── Expandable description text ─────────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  static const _collapsedLines = 2;

  @override
  Widget build(BuildContext context) {
    // Split text into normal parts and hashtag parts
    final spans = _buildSpans(widget.text);

    if (_expanded) {
      // Expanded: full text + "voir moins" at end
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: spans),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: const Text(
              'voir moins',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    // Collapsed: 2 lines max + "...voir plus" inline
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          maxLines: _collapsedLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        if (!isOverflowing) {
          return Text.rich(
            TextSpan(children: spans),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          );
        }

        // Show truncated + voir plus
        return Text.rich(
          TextSpan(children: [
            ...spans,
            TextSpan(
              text: '  voir plus',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _expanded = true),
            ),
          ]),
          maxLines: _collapsedLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.4,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        );
      },
    );
  }

  /// Splits text into normal + hashtag colored spans
  List<InlineSpan> _buildSpans(String text) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(#\w+)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }
}
