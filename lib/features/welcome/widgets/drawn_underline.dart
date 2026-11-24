import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/welcome_tokens.dart';

/// Hand-drawn curved underline matching the HTML spec:
/// SVG: M2 8.5 C 18 4.5, 38 5.5, 55 6.5 S 86 6, 98 3.5
/// Animated with cubic-bezier(.6,.05,.3,1) over 650ms.
class DrawnUnderlineText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color underlineColor;
  final Duration delay;
  final Duration duration;

  const DrawnUnderlineText({
    super.key,
    required this.text,
    required this.style,
    required this.underlineColor,
    this.delay = const Duration(milliseconds: 500),
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<DrawnUnderlineText> createState() => _DrawnUnderlineTextState();
}

class _DrawnUnderlineTextState extends State<DrawnUnderlineText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: WelcomeCurves.easeDraw,
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    }

    return CustomPaint(
      foregroundPainter: _UnderlinePainter(
        progress: _progress,
        color: widget.underlineColor,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;

  _UnderlinePainter({required this.progress, required this.color})
      : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value <= 0.0) return;

    final w = size.width;
    final h = size.height;
    final sx = w / 100.0;
    const sy = 1.0;

    // Base path: M2 8.5 C 18 4.5, 38 5.5, 55 6.5 S 86 6, 98 3.5
    // Anchored at bottom of text
    final yBase = h - 4.0;

    final fullPath = Path()
      ..moveTo(2 * sx, yBase + 1.5 * sy)
      ..cubicTo(
        18 * sx, yBase - 2.5 * sy,
        38 * sx, yBase - 1.5 * sy,
        55 * sx, yBase - 0.5 * sy,
      )
      ..cubicTo(
        72 * sx, yBase + 0.5 * sy,
        86 * sx, yBase - 1.0 * sy,
        98 * sx, yBase - 3.5 * sy,
      );

    final pathMetrics = fullPath.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final length = metric.length * progress.value.clamp(0.0, 1.0);
    final extractPath = metric.extractPath(0, length);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
