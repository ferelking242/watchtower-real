import 'package:flutter/material.dart';
import 'package:watchtower_real/core/theme/tokens.dart';

class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.small = false});
  final bool small;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.small ? 6 : 8,
          vertical: widget.small ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: AppTokens.colorLiveRed,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Text(
          'LIVE',
          style: AppTokens.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: widget.small ? 9 : 11,
          ),
        ),
      ),
    );
  }
}
