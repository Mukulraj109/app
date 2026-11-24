import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/welcome_tokens.dart';

/// Animated circular progress ring from Slide 3 (Learn).
/// 78x78px, radius 32, stroke-width 7.
/// Animates arc sweep and counts up number from 0 to 82% over 1100ms.
class AnimatedCircleProgress extends StatefulWidget {
  final int targetValue;
  final Duration duration;
  final Duration delay;

  const AnimatedCircleProgress({
    super.key,
    this.targetValue = 82,
    this.duration = const Duration(milliseconds: 1100),
    this.delay = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedCircleProgress> createState() => _AnimatedCircleProgressState();
}

class _AnimatedCircleProgressState extends State<AnimatedCircleProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: WelcomeCurves.easeOutCubic,
    );

    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final currentNumber = (_animation.value * widget.targetValue).round();
        return SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(78, 78),
                painter: _CircleProgressPainter(
                  progress: _animation.value * (widget.targetValue / 100.0),
                  trackColor: tokens.tealSoft,
                  valueColor: tokens.teal2,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentNumber',
                      style: TextStyle(
                        fontFamily: 'Geologica',
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontFamily: 'Geologica',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color valueColor;

  _CircleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 7.0) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Value Arc starting from 12 o'clock (-pi / 2)
    if (progress > 0) {
      final valuePaint = Paint()
        ..color = valueColor
        ..strokeWidth = 7.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.valueColor != valueColor;
}
