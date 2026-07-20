import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:reel/core/theme/tokens.dart';

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.url,
    this.views,
    this.duration,
    this.aspectRatio = 9 / 16,
  });

  final String url;
  final String? views;
  final String? duration;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: AppTokens.colorBgCard,
                child: const Icon(Icons.play_circle_outline,
                    color: Colors.white54, size: 32),
              ),
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x99000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            if (views != null)
              Positioned(
                bottom: 4, left: 4,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(views!, style: AppTokens.caption.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            if (duration != null)
              Positioned(
                bottom: 4, right: 4,
                child: Text(duration!, style: AppTokens.caption.copyWith(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
