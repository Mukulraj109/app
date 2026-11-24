import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/welcome_tokens.dart';
import '../widgets/firststep_logo.dart';

/// Animated Splash Screen matching 01-welcome-and-sign-in.html:
/// - Triangle glides from left (-150px, -10°), settles, then hops forward (+19px, lifts 9px) and lands.
/// - 5 echo copies follow with 55ms stagger and fade out.
/// - Wordmark fades in and rises 12px at 1000ms.
/// - After ~1.85s, calls onFinish() to transition to the next screen.
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _triangleController;
  late final AnimationController _wordmarkController;
  Timer? _wordmarkTimer;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();

    // Triangle animation: 1350ms
    _triangleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    // Wordmark animation: 500ms, starts at 1000ms
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _triangleController.forward();

    _wordmarkTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) _wordmarkController.forward();
    });

    // Total splash time ~1850ms, then cross-fade to next screen
    _finishTimer = Timer(const Duration(milliseconds: 1850), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _wordmarkTimer?.cancel();
    _finishTimer?.cancel();
    _triangleController.dispose();
    _wordmarkController.dispose();
    super.dispose();
  }

  // Calculate position & rotation of the main triangle based on triStep keyframes
  _TriangleTransform _calcMainTriangle(double t) {
    if (t <= 0.0) {
      return const _TriangleTransform(
        dx: -150.0,
        dy: 0.0,
        angle: -10.0 * (math.pi / 180.0),
        opacity: 0.0,
      );
    }
    if (t <= 0.50) {
      // 0 -> 50%: glide from -150px to -14px, rotate -10° to 0°, opacity 0 to 1
      final p = WelcomeCurves.easeOutCubic.transform((t / 0.50).clamp(0.0, 1.0));
      return _TriangleTransform(
        dx: -150.0 + (136.0 * p),
        dy: 0.0,
        angle: (-10.0 + (10.0 * p)) * (math.pi / 180.0),
        opacity: p,
      );
    } else if (t <= 0.68) {
      // 50% -> 68%: pause at (-14px, 0)
      return const _TriangleTransform(
        dx: -14.0,
        dy: 0.0,
        angle: 0.0,
        opacity: 1.0,
      );
    } else if (t <= 0.84) {
      // 68% -> 84%: step up and forward (-14 to +5, 0 to -9)
      final p = WelcomeCurves.easeOutCubic.transform(((t - 0.68) / 0.16).clamp(0.0, 1.0));
      return _TriangleTransform(
        dx: -14.0 + (19.0 * p),
        dy: -9.0 * p,
        angle: 0.0,
        opacity: 1.0,
      );
    } else {
      // 84% -> 100%: land (+5 to 0, -9 to 0)
      final p = WelcomeCurves.easeOutCubic.transform(((t - 0.84) / 0.16).clamp(0.0, 1.0));
      return _TriangleTransform(
        dx: 5.0 - (5.0 * p),
        dy: -9.0 + (9.0 * p),
        angle: 0.0,
        opacity: 1.0,
      );
    }
  }

  // Calculate echo trail copy i (i = 1..5)
  _TriangleTransform _calcEcho(int i, double t) {
    // Each copy is staggered by i * 55ms out of 1350ms = i * 0.0407
    final delayFraction = (i * 55.0) / 1350.0;
    final delayedT = (t - delayFraction).clamp(0.0, 1.0);

    final base = _calcMainTriangle(delayedT);

    // Echo opacity curve: peak at ~0.3 (0.34 - i * 0.055), fade out to 0 at 100%
    double opacity = 0.0;
    if (delayedT > 0.0 && delayedT < 1.0) {
      final peak = 0.34 - (i * 0.055);
      if (delayedT <= 0.30) {
        opacity = peak * (delayedT / 0.30);
      } else if (delayedT <= 0.60) {
        opacity = peak - ((delayedT - 0.30) / 0.30) * 0.08;
      } else {
        opacity = (peak - 0.08) * (1.0 - ((delayedT - 0.60) / 0.40));
      }
    }

    return _TriangleTransform(
      dx: base.dx - (i * 2.0),
      dy: base.dy,
      angle: base.angle,
      opacity: opacity.clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.16),
            radius: 0.7,
            colors: [
              tokens.glow,
              tokens.bg.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_triangleController, _wordmarkController]),
            builder: (context, _) {
              final tTri = reduceMotion ? 1.0 : _triangleController.value;
              final tWord = reduceMotion ? 1.0 : _wordmarkController.value;

              final mainTf = _calcMainTriangle(tTri);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Triangle with 5 echo copies
                  SizedBox(
                    width: 86,
                    height: 86 / (1246.0 / 971.0),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (!reduceMotion)
                          for (int i = 5; i >= 1; i--) ...[
                            Builder(
                              builder: (_) {
                                final echoTf = _calcEcho(i, tTri);
                                if (echoTf.opacity <= 0.01) return const SizedBox.shrink();
                                return Transform.translate(
                                  offset: Offset(echoTf.dx, echoTf.dy),
                                  child: Transform.rotate(
                                    angle: echoTf.angle,
                                    child: Opacity(
                                      opacity: echoTf.opacity,
                                      child: FirstStepTriangle(
                                        width: 86,
                                        color: tokens.triColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        // Main triangle
                        Transform.translate(
                          offset: Offset(mainTf.dx, mainTf.dy),
                          child: Transform.rotate(
                            angle: mainTf.angle,
                            child: Opacity(
                              opacity: mainTf.opacity,
                              child: FirstStepTriangle(
                                width: 86,
                                color: tokens.triColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Wordmark fade in & rise 12px
                  Transform.translate(
                    offset: Offset(0, 12.0 * (1.0 - tWord)),
                    child: Opacity(
                      opacity: tWord,
                      child: FirstStepWordmark(
                        width: 210,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TriangleTransform {
  final double dx;
  final double dy;
  final double angle;
  final double opacity;

  const _TriangleTransform({
    required this.dx,
    required this.dy,
    required this.angle,
    required this.opacity,
  });
}
