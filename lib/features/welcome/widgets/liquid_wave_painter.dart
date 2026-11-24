import 'package:flutter/material.dart';
import '../../../theme/welcome_tokens.dart';

/// Exact liquid wave header from 01-welcome-and-sign-in.html.
/// Uses 24 bezier points mapped across 4 cubic curves.
///
/// Features:
/// 1. Pour-in animation on entrance (flat top -> overshoot -> settle).
/// 2. Subtle breathing animation (4.2s easeInOutCubic cycle).
/// 3. Theme-aware:
///    - Light mode: solid white wave fill.
///    - Dark mode: white fill dissolves, leaving a glowing teal gradient line
///      along the contour (#2F8090 -> #6CC3CF -> #A9E4EA).
class LiquidWaveWidget extends StatefulWidget {
  final double height;
  const LiquidWaveWidget({super.key, this.height = 360});

  @override
  State<LiquidWaveWidget> createState() => _LiquidWaveWidgetState();
}

class _LiquidWaveWidgetState extends State<LiquidWaveWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _breatheController;

  // 24 control points from the spec:
  // Base A (resting state with DROP = 40 applied to y-indices)
  // Y-indices: [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23]
  static const List<double> _baseA = [
    254.0, 340.0, 266.0, 318.0, 302.0, 280.0, 308.0, 236.0, 316.0, 214.0,
    272.0, 168.0, 298.0, 120.0, 326.0, 92.0, 370.0, 46.0, 358.0, 24.0,
    352.0, 10.0, 342.0, 336.0,
  ];

  // Base B (breathing secondary state with DROP = 40 applied)
  static const List<double> _baseB = [
    262.0, 338.0, 254.0, 316.0, 292.0, 282.0, 298.0, 240.0, 306.0, 210.0,
    286.0, 166.0, 306.0, 122.0, 328.0, 90.0, 358.0, 46.0, 352.0, 24.0,
    348.0, 10.0, 340.0, 342.0,
  ];

  // Base Flat (initial state at y=0)
  static final List<double> _baseFlat = List.generate(24, (i) {
    const yIndices = {0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23};
    return yIndices.contains(i) ? 0.0 : _baseA[i];
  });

  // Base Overshoot (1.09x on y values)
  static final List<double> _baseOvershoot = List.generate(24, (i) {
    const yIndices = {0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23};
    return yIndices.contains(i) ? _baseA[i] * 1.09 : _baseA[i];
  });

  @override
  void initState() {
    super.initState();

    // Entrance animation: 700ms pour + 520ms settle
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1220),
    );

    // Breathe animation: ~2.8s per direction (slightly quicker)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _entranceController.forward().then((_) {
      if (mounted) {
        _breatheController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  List<double> _computeCurrentPoints(bool reduceMotion) {
    if (reduceMotion) return _baseA;

    final tEnt = _entranceController.value;
    if (tEnt < 1.0) {
      // 700ms out of 1220ms = ~0.574
      const pourSplit = 700.0 / 1220.0;
      if (tEnt <= pourSplit) {
        final p = WelcomeCurves.easeOutCubic.transform(tEnt / pourSplit);
        return List.generate(24, (i) =>
            _baseFlat[i] + (_baseOvershoot[i] - _baseFlat[i]) * p);
      } else {
        final p = WelcomeCurves.easeInOutCubic.transform(
            (tEnt - pourSplit) / (1.0 - pourSplit));
        return List.generate(24, (i) =>
            _baseOvershoot[i] + (_baseA[i] - _baseOvershoot[i]) * p);
      }
    }

    // Breathing loop
    final pBreathe = WelcomeCurves.easeInOutCubic.transform(_breatheController.value);
    return List.generate(24, (i) =>
        _baseA[i] + (_baseB[i] - _baseA[i]) * pBreathe);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _breatheController]),
      builder: (context, _) {
        final points = _computeCurrentPoints(reduceMotion);
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _LiquidWavePainter(
              points: points,
              topColor: tokens.lgTop,
              lineOpacity: tokens.lineOpacity,
            ),
          ),
        );
      },
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  final List<double> points;
  final Color topColor;
  final double lineOpacity;

  _LiquidWavePainter({
    required this.points,
    required this.topColor,
    required this.lineOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 375.0;
    // Scale y coordinates relative to reference canvas height 420
    final sy = size.height / 420.0;

    double x(double val) => val * sx;
    double y(double val) => val * sy;

    // Draw the fill
    if (topColor.a > 0.01) {
      final fillPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, y(points[0]))
        ..cubicTo(
          x(points[1]), y(points[2]),
          x(points[3]), y(points[4]),
          x(points[5]), y(points[6]),
        )
        ..cubicTo(
          x(points[7]), y(points[8]),
          x(points[9]), y(points[10]),
          x(points[11]), y(points[12]),
        )
        ..cubicTo(
          x(points[13]), y(points[14]),
          x(points[15]), y(points[16]),
          x(points[17]), y(points[18]),
        )
        ..cubicTo(
          x(points[19]), y(points[20]),
          x(points[21]), y(points[22]),
          0, y(points[23]),
        )
        ..close();

      final fillPaint = Paint()
        ..color = topColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw the glowing gradient line (prominent in dark mode)
    if (lineOpacity > 0.01) {
      final linePath = Path()
        ..moveTo(size.width, y(points[0]))
        ..cubicTo(
          x(points[1]), y(points[2]),
          x(points[3]), y(points[4]),
          x(points[5]), y(points[6]),
        )
        ..cubicTo(
          x(points[7]), y(points[8]),
          x(points[9]), y(points[10]),
          x(points[11]), y(points[12]),
        )
        ..cubicTo(
          x(points[13]), y(points[14]),
          x(points[15]), y(points[16]),
          x(points[17]), y(points[18]),
        )
        ..cubicTo(
          x(points[19]), y(points[20]),
          x(points[21]), y(points[22]),
          0, y(points[23]),
        );

      final lineShader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF2F8090),
          Color(0xFF6CC3CF),
          Color(0xFFA9E4EA),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final linePaint = Paint()
        ..shader = lineShader
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: lineOpacity);

      canvas.drawPath(linePath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) => true;
}
