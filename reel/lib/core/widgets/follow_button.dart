import 'package:flutter/material.dart';
import 'package:reel/core/theme/tokens.dart';

class FollowButton extends StatefulWidget {
  const FollowButton({super.key, this.mini = false});
  final bool mini;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _following = !_following),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.mini ? 12 : 16,
          vertical: widget.mini ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: _following ? Colors.transparent : AppTokens.colorFollowBtn,
          border: _following
              ? Border.all(color: AppTokens.colorDivider)
              : null,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
        child: Text(
          _following ? 'Suivi' : 'Suivre',
          style: AppTokens.labelM.copyWith(
            color: AppTokens.colorTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
