import 'package:flutter/material.dart';

import '../../../theme/home_tokens.dart';

class AvatarMark extends StatelessWidget {
  final String kind;
  final String pastelKey;
  final String initial;
  final double size;
  /// Auth0 / bootstrap picture URL when present (same as web ProfileHub).
  final String? pictureUrl;

  const AvatarMark({
    super.key,
    required this.kind,
    required this.pastelKey,
    required this.initial,
    this.size = 88,
    this.pictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = switch (pastelKey) {
      'sky' => t.sky,
      'mint' => t.mint,
      'pch' => t.peach,
      'but' => t.butter,
      _ => t.lavender,
    };
    final photo = pictureUrl?.trim() ?? '';
    final usePhoto = photo.isNotEmpty && Uri.tryParse(photo)?.hasScheme == true;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: usePhoto
          ? Image.network(
              photo,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(p),
            )
          : _fallback(p),
    );
  }

  Widget _fallback(Pastel p) {
    if (kind == 'init') {
      return Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: p.fg,
        ),
      );
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _PatternPainter(kind: kind, color: p.fg),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final String kind;
  final Color color;
  _PatternPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = color.withValues(alpha: 0.85);
    final c = Offset(size.width / 2, size.height / 2);
    switch (kind) {
      case 'dots':
        for (var y = 10.0; y < size.height; y += 12) {
          for (var x = 10.0; x < size.width; x += 12) {
            canvas.drawCircle(Offset(x, y), 2.2, fill);
          }
        }
      case 'stripes':
        for (var i = -size.width; i < size.width * 2; i += 8) {
          canvas.drawLine(
            Offset(i, 0),
            Offset(i + size.height, size.height),
            paint..strokeWidth = 2,
          );
        }
      case 'rings':
        for (var r = 8.0; r < size.width; r += 10) {
          canvas.drawCircle(c, r, paint);
        }
      case 'waves':
        final path = Path();
        for (var y = 12.0; y < size.height; y += 10) {
          path.moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 8) {
            path.lineTo(x, y + (x % 16 == 0 ? -4 : 4));
          }
        }
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) =>
      old.kind != kind || old.color != color;
}
