import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/home_tokens.dart';
import '../home_store.dart';

/// 12 rounded pills along a semicircle, matching 02-homev2.html `arcSVG`.
/// Filled pills light from the left; the next empty pill breathes while applying.
class HeroArc extends StatefulWidget {
  final HeroSpec spec;
  final double size;

  const HeroArc({super.key, required this.spec, this.size = 320});

  @override
  State<HeroArc> createState() => _HeroArcState();
}

class _HeroArcState extends State<HeroArc> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _count;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1270),
    )..forward();
    _count = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.spec.status == HeroStatus.applying) {
      _breathe.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HeroArc old) {
    super.didUpdateWidget(old);
    // Restart entrance only when the visible progress actually changes —
    // HeroSpec has no ==, so identity changes on every parent rebuild.
    final meaningfulChange = old.spec.status != widget.spec.status ||
        old.spec.value != widget.spec.value ||
        old.spec.max != widget.spec.max ||
        old.spec.from != widget.spec.from ||
        old.spec.muted != widget.spec.muted;
    if (meaningfulChange) {
      _entrance.forward(from: 0);
      _count.forward(from: 0);
    }
    final applying = widget.spec.status == HeroStatus.applying;
    if (applying && !_breathe.isAnimating) {
      _breathe.repeat(reverse: true);
    } else if (!applying && _breathe.isAnimating) {
      _breathe.stop();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _count.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final spec = widget.spec;
    final reduce = MediaQuery.of(context).disableAnimations;
    final width = widget.size;
    final arcHeight = width * 214 / 320;
    final height = width * 248 / 320;
    final track = Theme.of(context).brightness == Brightness.dark
        ? t.tealSoft
        : const Color(0xFFEBEBE4);

    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: arcHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([_entrance, _breathe]),
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(width, arcHeight),
                    painter: _SegmentArcPainter(
                      reveal: reduce ? 1 : _entrance.value,
                      breathe: reduce ? 0.45 : _breathe.value,
                      filled: spec.filledSegments,
                      applying: spec.status == HeroStatus.applying,
                      muted: spec.muted,
                      trackColor: track,
                      valueColor: t.teal,
                      muteColor: t.mute,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: width * 96 / 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(spec: spec, track: track),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _count,
                    builder: (context, _) {
                      final n = reduce || _count.isCompleted
                          ? spec.value
                          : (spec.from + (spec.value - spec.from) * _count.value)
                              .round();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$n',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.2,
                              height: 1,
                              color: t.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (spec.unit != null)
                            Text(
                              spec.unit!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: t.mute,
                              ),
                            ),
                          if (spec.max != null)
                            Text(
                              ' / ${spec.max}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: t.mute,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.label,
                    style: TextStyle(fontSize: 13.5, color: t.mute),
                  ),
                  if (spec.companies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CompanyTicker(companies: spec.companies),
                    )
                  else if (spec.sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        spec.sub!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final HeroSpec spec;
  final Color track;

  const _StatusChip({required this.spec, required this.track});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    late final Color bg;
    late final Color fg;
    late final String label;
    Widget? leading;

    switch (spec.status) {
      case HeroStatus.applying:
        bg = t.tealSoft;
        fg = t.teal;
        label = 'Applying now';
        leading = Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
        );
      case HeroStatus.done:
        bg = t.okBg;
        fg = t.ok;
        label = 'Done for today';
        leading = Icon(Icons.check_rounded, size: 14, color: fg);
      case HeroStatus.rest:
        if (spec.statusText == null) return const SizedBox.shrink();
        bg = track;
        fg = t.mute;
        label = spec.statusText!;
    }

    // FittedBox absorbs tiny overruns (long weekend copy) without a yellow bar.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 7)],
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geometry copied from 02-homev2.html:
/// N=12, CX=160, CY=176, R=128, angles 192° → -12°, pill 30×38 r=10.
class _SegmentArcPainter extends CustomPainter {
  final double reveal;
  final double breathe;
  final int filled;
  final bool applying;
  final bool muted;
  final Color trackColor;
  final Color valueColor;
  final Color muteColor;

  _SegmentArcPainter({
    required this.reveal,
    required this.breathe,
    required this.filled,
    required this.applying,
    required this.muted,
    required this.trackColor,
    required this.valueColor,
    required this.muteColor,
  });

  static const _n = 12;
  static const _a0 = 192.0;
  static const _a1 = -12.0;

  double _segReveal(int i) {
    const total = 1270.0;
    final start = (150 + i * 70) / total;
    final end = (150 + i * 70 + 350) / total;
    if (reveal <= start) return 0;
    if (reveal >= end) return 1;
    return HomeCurves.easeOutCubic
        .transform((reveal - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 320;
    const step = (_a0 - _a1) / _n;
    final track = Paint()..color = trackColor;
    final onColor = muted ? muteColor : valueColor;
    final onAlpha = muted ? 0.35 : 1.0;

    for (var i = 0; i < _n; i++) {
      final th = _a0 - step * (i + 0.5);
      final rad = th * math.pi / 180;
      final x = (160 + 128 * math.cos(rad)) * s;
      final y = (176 - 128 * math.sin(rad)) * s;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((90 - th) * math.pi / 180);
      final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(-15 * s, -19 * s, 30 * s, 38 * s),
        Radius.circular(10 * s),
      );
      canvas.drawRRect(pill, track);

      if (i < filled) {
        final amount = _segReveal(i);
        if (amount > 0) {
          canvas.drawRRect(
            pill,
            Paint()..color = onColor.withValues(alpha: onAlpha * amount),
          );
        }
      } else if (applying && i == filled) {
        final opacity = 0.22 + (0.55 - 0.22) * breathe;
        canvas.drawRRect(
          pill,
          Paint()..color = valueColor.withValues(alpha: opacity),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentArcPainter old) =>
      old.reveal != reveal ||
      old.breathe != breathe ||
      old.filled != filled ||
      old.applying != applying ||
      old.muted != muted ||
      old.trackColor != trackColor ||
      old.valueColor != valueColor ||
      old.muteColor != muteColor;
}

/// Fades company names one at a time, every 2.6 s (looping).
class CompanyTicker extends StatefulWidget {
  final List<String> companies;

  const CompanyTicker({super.key, required this.companies});

  @override
  State<CompanyTicker> createState() => _CompanyTickerState();
}

class _CompanyTickerState extends State<CompanyTicker> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.companies.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % widget.companies.length);
    });
  }

  @override
  void didUpdateWidget(covariant CompanyTicker old) {
    super.didUpdateWidget(old);
    if (old.companies != widget.companies) _i = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final name = widget.companies[_i.clamp(0, widget.companies.length - 1)];
    return SizedBox(
      height: 20,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: HomeCurves.easeOutCubic,
        child: Text(
          'Latest: $name',
          key: ValueKey(name),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.ink,
          ),
        ),
      ),
    );
  }
}
