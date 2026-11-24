import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/home/home_store.dart';
import '../theme/home_tokens.dart';

/// Navy bar from 02-homev2.html. Inactive tabs are icon-only. The active
/// tab grows a pill sized to its label (320 ms, easeOutCubic).
class ExpandingPillNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ExpandingPillNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom > mq.padding.bottom
        ? mq.viewPadding.bottom
        : mq.padding.bottom;
    // Callers: focus_shell.dart ExpandingPillNav. UI-only. User:
    // "move the profile icon a little bit to the left and move the learn
    // icon a little bit to the right when they are non-active."
    return Positioned(
      left: 14,
      right: 14,
      // Clear the system gesture / 3-button nav, then a little breathing room.
      bottom: 14 + bottomInset,
      child: Container(
        height: 56,
        // Side inset keeps Learn / Profile off the pill corners when inactive.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: t.nav,
          borderRadius: BorderRadius.circular(28),
          border: dark ? Border.all(color: const Color(0xFF2A2A2E)) : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x47061E2C),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final tab in homeTabs)
              Expanded(
                // Selected slot grows so the full label (e.g. Applications) fits;
                // inactive slots stay compact. Icons stay centered so Learn /
                // Profile are not glued to the bar corners when inactive.
                flex: tab.index == selectedIndex ? 3 : 1,
                child: _PillNavItem(
                  tab: tab,
                  selected: tab.index == selectedIndex,
                  tokens: t,
                  onTap: tab.index == selectedIndex
                      ? () {}
                      : () {
                          HapticFeedback.selectionClick();
                          onSelected(tab.index);
                        },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  static const double _inactiveWidth = 28;

  final HomeTab tab;
  final bool selected;
  final HomeTokens tokens;
  final VoidCallback onTap;

  const _PillNavItem({
    required this.tab,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : tokens.navInk;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: HomeCurves.easeOutCubic,
            height: 40,
            // Both ends must be finite: AnimatedContainer cannot tween to infinity.
            width: selected ? constraints.maxWidth : _inactiveWidth,
            padding: EdgeInsets.symmetric(horizontal: selected ? 8 : 4),
            decoration: BoxDecoration(
              color: selected ? tokens.navOn : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (context, inner) {
                // The pill starts at icon width; add the label once it fits.
                final showLabel = selected && inner.maxWidth >= 20 + 5 + 12;
                return Row(
                  mainAxisSize: selected ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavGlyph(kind: tab.index, color: color),
                    if (showLabel) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: tab.label.length > 8 ? 11.5 : 12.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Stroke icons from 02-homev2.html (learn, apps, home, scoutx, profile).
class _NavGlyph extends StatelessWidget {
  final int kind;
  final Color color;

  const _NavGlyph({required this.kind, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _NavGlyphPainter(kind: kind, color: color),
    );
  }
}

class _NavGlyphPainter extends CustomPainter {
  final int kind;
  final Color color;

  _NavGlyphPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = kind == 3 ? 3.4 : 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = kind == 3 || kind == 4 ? StrokeCap.butt : StrokeCap.round;

    switch (kind) {
      case 0:
        canvas.drawPath(
          Path()
            ..moveTo(3, 5.5)
            ..cubicTo(5.6, 4.5, 8.6, 4.6, 12, 6.7)
            ..lineTo(12, 19.7)
            ..cubicTo(8.6, 17.6, 5.6, 17.5, 3, 18.5)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(21, 5.5)
            ..cubicTo(18.4, 4.5, 15.4, 4.6, 12, 6.7)
            ..lineTo(12, 19.7)
            ..cubicTo(15.4, 17.6, 18.4, 17.5, 21, 18.5)
            ..close(),
          paint,
        );
      case 1:
        canvas.drawPath(
          Path()
            ..moveTo(6, 2.8)
            ..lineTo(14, 2.8)
            ..lineTo(18.5, 7.3)
            ..lineTo(18.5, 20)
            ..arcToPoint(const Offset(17.3, 21.2),
                radius: const Radius.circular(1.2))
            ..lineTo(6, 21.2)
            ..arcToPoint(const Offset(4.8, 20),
                radius: const Radius.circular(1.2))
            ..lineTo(4.8, 4)
            ..arcToPoint(const Offset(6, 2.8),
                radius: const Radius.circular(1.2)),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(14, 2.8)
            ..lineTo(14, 7.5)
            ..lineTo(18.5, 7.5),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8.5, 14.2)
            ..lineTo(10.8, 16.5)
            ..lineTo(15.4, 11.9),
          paint,
        );
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 10.5)
            ..lineTo(12, 3.5)
            ..lineTo(20.5, 10.5)
            ..lineTo(20.5, 20)
            ..arcToPoint(const Offset(19.5, 21),
                radius: const Radius.circular(1))
            ..lineTo(14.5, 21)
            ..lineTo(14.5, 15)
            ..lineTo(9.5, 15)
            ..lineTo(9.5, 21)
            ..lineTo(4.5, 21)
            ..arcToPoint(const Offset(3.5, 20),
                radius: const Radius.circular(1))
            ..close(),
          paint,
        );
      case 3:
        paint.strokeCap = StrokeCap.butt;
        canvas.drawLine(const Offset(5, 3.6), const Offset(19.4, 20.6), paint);
        canvas.drawLine(
            const Offset(4.8, 20.6), const Offset(10.6, 13.8), paint);
        final rays = Paint()
          ..color = color.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.butt;
        canvas.drawLine(
            const Offset(12.6, 10.6), const Offset(18.2, 3.6), rays);
        canvas.drawLine(
            const Offset(13.6, 11.3), const Offset(19.4, 4.2), rays);
        canvas.drawLine(
            const Offset(14.5, 12.1), const Offset(20.2, 5.1), rays);
        canvas.drawLine(const Offset(12, 9.6), const Offset(16.8, 3.6), rays);
      case 4:
        canvas.drawCircle(const Offset(12, 8), 4, paint);
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 20.5)
            ..cubicTo(5.9, 16.9, 8.8, 15, 12, 15)
            ..cubicTo(15.2, 15, 18.1, 16.9, 19.5, 20.5),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _NavGlyphPainter old) =>
      old.kind != kind || old.color != color;
}
