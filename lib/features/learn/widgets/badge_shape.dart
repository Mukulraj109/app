import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Glossy badge shapes from 05-learn.html (notch, orb, chevron, split).
class BadgeShape extends StatelessWidget {
  final String shape;
  final String colorKey;
  final String glyph;
  final double size;
  final bool locked;

  const BadgeShape({
    super.key,
    required this.shape,
    required this.colorKey,
    this.glyph = '',
    this.size = 54,
    this.locked = false,
  });

  static const _palette = {
    'lav': [Color(0xFFF1EDFF), Color(0xFF9C8CF0), Color(0xFF6F5BD6)],
    'mint': [Color(0xFFE6F8EC), Color(0xFF73C892), Color(0xFF3E9E62)],
    'but': [Color(0xFFFFF4D2), Color(0xFFEDBD52), Color(0xFFC08A1C)],
    'sky': [Color(0xFFE4F3FC), Color(0xFF78B9DE), Color(0xFF3F86B2)],
    'pch': [Color(0xFFFFEAE0), Color(0xFFF0A27F), Color(0xFFC9653F)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _palette[colorKey] ?? _palette['lav']!;
    return Opacity(
      opacity: locked ? 0.4 : 1,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BadgePainter(
          shape: shape,
          top: colors[0],
          mid: colors[1],
          stroke: colors[2],
          glyph: glyph,
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final String shape;
  final Color top;
  final Color mid;
  final Color stroke;
  final String glyph;

  _BadgePainter({
    required this.shape,
    required this.top,
    required this.mid,
    required this.stroke,
    required this.glyph,
  });

  Path _path(Size size) {
    final s = size.width / 60;
    final p = Path();
    switch (shape) {
      case 'orb':
        p.addOval(Rect.fromCircle(
          center: Offset(30 * s, 30 * s),
          radius: 25 * s,
        ));
      case 'chevron':
        p.moveTo(30 * s, 6 * s);
        p.lineTo(54 * s, 24 * s);
        p.lineTo(54 * s, 38 * s);
        p.lineTo(30 * s, 22 * s);
        p.lineTo(6 * s, 38 * s);
        p.lineTo(6 * s, 24 * s);
        p.close();
        p.moveTo(30 * s, 32 * s);
        p.lineTo(54 * s, 48 * s);
        p.lineTo(54 * s, 56 * s);
        p.lineTo(30 * s, 42 * s);
        p.lineTo(6 * s, 56 * s);
        p.lineTo(6 * s, 48 * s);
        p.close();
      case 'split':
        p.moveTo(9 * s, 8 * s);
        p.cubicTo(16 * s, 5 * s, 23 * s, 4 * s, 30 * s, 9 * s);
        p.cubicTo(37 * s, 4 * s, 44 * s, 5 * s, 51 * s, 8 * s);
        p.lineTo(51 * s, 34 * s);
        p.lineTo(41 * s, 54 * s);
        p.lineTo(36 * s, 43 * s);
        p.lineTo(30 * s, 49 * s);
        p.lineTo(24 * s, 43 * s);
        p.lineTo(19 * s, 54 * s);
        p.lineTo(9 * s, 34 * s);
        p.close();
      default: // notch
        p.moveTo(8 * s, 10 * s);
        p.lineTo(22 * s, 6 * s);
        p.lineTo(30 * s, 12 * s);
        p.lineTo(38 * s, 6 * s);
        p.lineTo(52 * s, 10 * s);
        p.lineTo(50 * s, 34 * s);
        p.cubicTo(48 * s, 44 * s, 40 * s, 51 * s, 30 * s, 56 * s);
        p.cubicTo(20 * s, 51 * s, 12 * s, 44 * s, 10 * s, 34 * s);
        p.close();
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final gradient = ui.Gradient.linear(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      [top, mid],
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    if (shape == 'orb') {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.33),
          width: size.width * 0.5,
          height: size.height * 0.27,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
    }
    if (glyph.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: size.width * 0.2,
            fontWeight: FontWeight.w700,
            color: stroke,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (size.width - tp.width) / 2,
          (size.height - tp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.shape != shape ||
      old.top != top ||
      old.mid != mid ||
      old.stroke != stroke ||
      old.glyph != glyph;
}
