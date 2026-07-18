import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _dotsCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _dot1Bounce;
  late final Animation<double> _dot2Bounce;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _dot1Bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeInOut),
    );
    _dot2Bounce = Tween<double>(begin: -8, end: 0).animate(
      CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/feed');
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131824),
      body: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TikTok-style music note logo with dual shadow
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cyan shadow
                    Transform.translate(
                      offset: const Offset(-3, 3),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 90,
                        color: Color(0x8069C9D0),
                      ),
                    ),
                    // Red shadow
                    Transform.translate(
                      offset: const Offset(3, -3),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 90,
                        color: Color(0x80FE2C55),
                      ),
                    ),
                    // Main white icon
                    const Icon(
                      Icons.music_note_rounded,
                      size: 90,
                      color: Color(0xFF1A2035),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Bouncing dots
              AnimatedBuilder(
                animation: _dotsCtrl,
                builder: (_, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _dot1Bounce.value),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69C9D0),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.translate(
                        offset: Offset(0, _dot2Bounce.value),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFE2C55),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
