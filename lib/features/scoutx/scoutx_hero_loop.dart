import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_svg/flutter_svg.dart';

import 'scoutx_scraper_assets.dart';
import 'scoutx_tokens.dart';

const _feedFly = 0.7;

String _fmtCount(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

List<ScoutXClusterBin> _computeBins(double t) {
  final land = ScoutXScraperK.exE +
      ScoutXScraper.feedN * ScoutXScraper.step +
      _feedFly * 0.85;
  final bins = scoutXScraperBinDefs
      .map(
        (d) => ScoutXClusterBin(
          name: d.$1,
          base: d.$2,
          x: d.$3,
          y: d.$4,
          w: d.$5,
          h: d.$6,
        ),
      )
      .toList();
  final slots = scoutxScraperSlots;
  for (var i = 0; i < slots.length; i++) {
    final cmax = math.min(
      ((t - i * ScoutXScraper.step - land) / ScoutXScraper.loop).floor(),
      400,
    );
    for (var c = math.max(0, cmax - 400); c <= cmax; c++) {
      if (c < 0) continue;
      final ci = sxCompanyAt(
        i,
        c * ScoutXScraper.loop + i * ScoutXScraper.step + land,
      );
      bins[sxBinOf(ci)].count += 1;
    }
    if (cmax >= 0) {
      final since =
          t - (i * ScoutXScraper.step + land) - cmax * ScoutXScraper.loop;
      final ci = sxCompanyAt(
        i,
        cmax * ScoutXScraper.loop + i * ScoutXScraper.step + land,
      );
      final b = bins[sxBinOf(ci)];
      b.pulse = math.max(b.pulse, 1 - sxCl(since / 0.9, 0, 1));
    }
  }
  return bins;
}

/// Web ScoutXScraperHeroLoop compact layout (design 1440×960, scaled to width).
class ScoutXHeroLoop extends StatefulWidget {
  final Color accent;

  const ScoutXHeroLoop({super.key, this.accent = ScoutXTokens.teal});

  @override
  State<ScoutXHeroLoop> createState() => _ScoutXHeroLoopState();
}

class _ScoutXHeroLoopState extends State<ScoutXHeroLoop>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _animTime = ScoutXScraper.off;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    // createTicker (not a raw Ticker) respects shell TickerMode off-tab.
    // Cap near 30fps — marketing still feels live without 60 setStates/sec.
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (elapsed - _lastTick < const Duration(milliseconds: 33)) return;
      _lastTick = elapsed;
      setState(
        () => _animTime = ScoutXScraper.off + elapsed.inMicroseconds / 1e6,
      );
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.clamp(0.0, 420.0);
        final scale = w / ScoutXScraper.cw;
        final h = ScoutXScraper.ch * scale;
        return SizedBox(
          width: w,
          height: h,
          child: RepaintBoundary(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: ScoutXScraper.cw,
                maxWidth: ScoutXScraper.cw,
                minHeight: ScoutXScraper.ch,
                maxHeight: ScoutXScraper.ch,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: _ScraperCanvas(t: _animTime, accent: widget.accent),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScraperCanvas extends StatelessWidget {
  final double t;
  final Color accent;

  const _ScraperCanvas({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final slots = scoutxScraperSlots;
    final bins = _computeBins(t);

    return SizedBox(
      width: ScoutXScraper.cw,
      height: ScoutXScraper.ch,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: const Size(ScoutXScraper.cw, ScoutXScraper.ch),
            painter: _DotRingPainter(t: t),
          ),
          _RackVisual(t: t, accent: accent),
          Positioned(
            left: ScoutXScraper.fx - 14,
            top: ScoutXScraper.fy - 70,
            width: ScoutXScraper.fwc + 28,
            height: 70 + ScoutXScraper.feedN * ScoutXScraper.rh + 4,
            child: _LiveFeedShell(accent: accent, t: t),
          ),
          Positioned(
            left: ScoutXScraper.fx - 14,
            top: 704,
            width: ScoutXScraper.fwc + 28,
            height: 184,
            child: _ClusterShell(accent: accent, t: t),
          ),
          for (final b in bins) _ClusterBin(bin: b, accent: accent),
          ..._feedJobCards(t, accent, bins),
          for (var i = 0; i < slots.length; i++) ...[
            _FiringSlot(i: i, t: t, accent: accent),
            ..._flightCards(i: i, t: t, accent: accent),
          ],
        ],
      ),
    );
  }
}

List<Widget> _feedJobCards(
  double t,
  Color accent,
  List<ScoutXClusterBin> bins,
) {
  final out = <Widget>[];
  for (var i = 0; i < scoutxScraperSlots.length; i++) {
    final age = sxMod(t - (i * ScoutXScraper.step + ScoutXScraperK.exE), ScoutXScraper.loop);
    final k = (age / ScoutXScraper.step).floor();
    final s = k == 0
        ? 0.0
        : k - 1 + sxEnter((age - k * ScoutXScraper.step) / 0.35);

    if (k >= ScoutXScraper.feedN) {
      final u = (age - ScoutXScraper.feedN * ScoutXScraper.step) / _feedFly;
      if (u >= 1) continue;
      final absT = t - age;
      final ci = sxCompanyAt(i, absT);
      final b = bins[sxBinOf(ci)];
      final e = sxDraw(sxCl(u, 0, 1));
      final x0 = ScoutXScraper.fx + ScoutXScraper.fwc / 2;
      final y0 =
          ScoutXScraper.fy + (ScoutXScraper.feedN - 1) * ScoutXScraper.rh +
              ScoutXScraper.fh / 2;
      final x1 = b.x + b.w / 2;
      final y1 = b.y + b.h / 2;
      out.add(
        _JobCard(
          slot: i,
          cx: sxLerp(x0, x1, e),
          cy: sxLerp(y0, y1, e) - math.sin(math.pi * e) * 18,
          scale: 1 - 0.62 * e,
          opacity: u > 0.75 ? (1 - u) / 0.25 : 1,
          highlight: 1,
          accent: accent,
          absT: absT,
        ),
      );
      continue;
    }

    if (s >= ScoutXScraper.feedN) continue;
    final op = s > ScoutXScraper.feedN - 1
        ? sxCl(1 - (s - (ScoutXScraper.feedN - 1)) / 0.35, 0, 1)
        : 1.0;
    if (op <= 0) continue;
    out.add(
      _JobCard(
        slot: i,
        cx: ScoutXScraper.fx + ScoutXScraper.fwc / 2,
        cy: ScoutXScraper.fy + s * ScoutXScraper.rh + ScoutXScraper.fh / 2,
        scale: 1,
        opacity: op,
        highlight: 1 - sxCl(age / 0.9, 0, 1),
        accent: accent,
        absT: t - age,
      ),
    );
  }
  return out;
}

List<Widget> _flightCards({
  required int i,
  required double t,
  required Color accent,
}) {
  final slotT = sxMod(t - i * ScoutXScraper.step, ScoutXScraper.loop);
  final pos = scoutxScraperSlots[i];
  final sx = pos.dx;
  final sy = pos.dy;
  const mx = ScoutXScraper.muzzleX;
  const my = ScoutXScraper.muzzleY;
  final out = <Widget>[];

  if (slotT >= ScoutXScraperK.inS && slotT < ScoutXScraperK.inE) {
    final u = sxDraw(sxSeg(slotT, ScoutXScraperK.inS, ScoutXScraperK.inE));
    final op = math.min(
      sxCl(u * 8, 0, 1),
      u > 0.85 ? (1 - u) / 0.15 : 1.0,
    ).toDouble();
    out.add(
      _JobCard(
        slot: i,
        cx: sxLerp(sx, mx, u),
        cy: sxLerp(sy, my - 4, u) - math.sin(math.pi * u) * 50,
        scale: 0.5 - 0.4 * u,
        opacity: op,
        highlight: 1,
        accent: accent,
        absT: t - slotT,
      ),
    );
  }

  if (slotT >= ScoutXScraperK.exS && slotT < ScoutXScraperK.exE) {
    final u = sxEnter(sxSeg(slotT, ScoutXScraperK.exS, ScoutXScraperK.exE));
    out.add(
      _JobCard(
        slot: i,
        cx: sxLerp(ScoutXScraper.rx0 + ScoutXScraper.rw - 10, ScoutXScraper.fx + ScoutXScraper.fwc / 2, u),
        cy: sxLerp(ScoutXScraper.ry + 110, ScoutXScraper.fy + ScoutXScraper.fh / 2, u) -
            math.sin(math.pi * u) * 70,
        scale: 0.3 + 0.7 * u,
        opacity: sxCl(u * 5, 0, 1),
        highlight: 1,
        accent: accent,
        absT: t - slotT,
      ),
    );
  }

  return out;
}

class _DotRingPainter extends CustomPainter {
  final double t;
  _DotRingPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (var y = 0.0; y < size.height; y += 28) {
      for (var x = 0.0; x < size.width; x += 28) {
        canvas.drawCircle(
          Offset(x + 14, y + 14),
          1.3,
          Paint()..color = ScoutXScraper.ink.withValues(alpha: 0.09),
        );
      }
    }
  final m = Offset(ScoutXScraper.muzzleX, ScoutXScraper.ry + 150);
  for (var k = 0; k < 3; k++) {
    final p = sxMod(t / 2 - k / 3, 1);
    canvas.drawCircle(
      m,
      160 + p * 760,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ScoutXScraper.ink.withValues(alpha: 0.07 * (1 - p)),
    );
  }
  }

  @override
  bool shouldRepaint(covariant _DotRingPainter old) => old.t != t;
}

class _RackVisual extends StatelessWidget {
  final double t;
  final Color accent;
  const _RackVisual({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    var kick = 0.0;
    var flash = 0.0;
    for (var i = 0; i < scoutxScraperSlots.length; i++) {
      final slotT = sxMod(t - i * ScoutXScraper.step, ScoutXScraper.loop);
      final p = sxSeg(slotT, ScoutXScraperK.fire, ScoutXScraperK.fire + 0.2);
      if (p > 0 && p < 1) {
        kick = math.max(kick, math.sin(math.pi * p));
        flash = math.max(flash, 1 - p);
      }
    }
    final live = 0.5 + 0.5 * math.cos((t / 1.5) * math.pi * 2);
    final prog = sxEnter(sxMod(t - 1.3, ScoutXScraper.step) / ScoutXScraper.step);

    return Positioned(
      left: ScoutXScraper.rx0,
      top: ScoutXScraper.ry,
      width: ScoutXScraper.rw,
      child: Transform.translate(
        offset: Offset(0, kick * 4),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 14,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: ScoutXScraper.ink,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: accent.withValues(alpha: 0.35 + 0.65 * flash),
                  boxShadow: [BoxShadow(color: accent, blurRadius: 12)],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScoutXScraper.rackBody,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4714161B),
                    blurRadius: 60,
                    offset: Offset(0, 28),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _rackUnit('SX-01', 'CRAWL', accent, flash, child: _vents()),
                  const SizedBox(height: 8),
                  _rackUnit(
                    'SX-02',
                    'PARSE',
                    accent,
                    0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prog,
                        minHeight: 8,
                        backgroundColor: ScoutXScraper.rackVent,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _rackUnit('SX-03', 'RANK', accent, 0, child: _vents()),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ScoutX',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          fontFamily: 'Geologica',
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF35C47C),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x3335C47C),
                                  blurRadius: 2 + 3 * live,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ONLINE',
                            style: TextStyle(
                              color: Color(0xFF8E939E),
                              fontSize: 11,
                              fontFamily: 'Geologica',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vents() {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: ScoutXScraper.rackVent,
      ),
    );
  }

  Widget _rackUnit(
    String name,
    String role,
    Color accent,
    double flash, {
    required Widget child,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ScoutXScraper.rackUnit,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(child: child),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFC9CDD6),
                  fontFamily: 'Geologica',
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7D828E),
                  fontFamily: 'Geologica',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveFeedShell extends StatelessWidget {
  final Color accent;
  final double t;
  const _LiveFeedShell({required this.accent, required this.t});

  @override
  Widget build(BuildContext context) {
    final live = 0.5 + 0.5 * math.cos((t / 1.5) * math.pi * 2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScoutXScraper.feedBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F14161B),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE FEED',
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 12,
                  letterSpacing: 1.4,
                  color: ScoutXScraper.muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.4 + 0.6 * live),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontFamily: 'Geologica',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final int slot;
  final double cx;
  final double cy;
  final double scale;
  final double opacity;
  final double highlight;
  final Color accent;
  final double absT;

  const _JobCard({
    required this.slot,
    required this.cx,
    required this.cy,
    this.scale = 1,
    this.opacity = 1,
    this.highlight = 0,
    required this.accent,
    required this.absT,
  });

  @override
  Widget build(BuildContext context) {
    final li = sxCompanyAt(slot, absT);
    final title = scoutXScraperTitles[slot % scoutXScraperTitles.length];
    final company = scoutXScraperCompanies[li];
    final loc = scoutXScraperLocs[slot % scoutXScraperLocs.length];
    final hi = highlight;
    final borderColor = hi > 0.4 ? accent : ScoutXScraper.cardBorder;

    return Positioned(
      left: cx - ScoutXScraper.fwc / 2,
      top: cy - ScoutXScraper.fh / 2,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: ScoutXScraper.fwc,
            height: ScoutXScraper.fh,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: ScoutXScraper.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12 * hi),
                  blurRadius: 5,
                  spreadRadius: 5 * hi,
                ),
                const BoxShadow(
                  color: Color(0x1414161B),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ScoutXScraper.logoChip,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: _Logo(li),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Geologica',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: ScoutXScraper.ink,
                        ),
                      ),
                      Text(
                        '$company · $loc',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Geologica',
                          fontSize: 12.5,
                          color: ScoutXScraper.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Apply ↗',
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterShell extends StatelessWidget {
  final Color accent;
  final double t;
  const _ClusterShell({required this.accent, required this.t});

  @override
  Widget build(BuildContext context) {
    final live = 0.5 + 0.5 * math.cos((t / 1.5) * math.pi * 2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScoutXScraper.feedBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F14161B),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SORTED INTO CLUSTERS',
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 12,
                  letterSpacing: 1.4,
                  color: ScoutXScraper.muted,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.4 + 0.6 * live),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClusterBin extends StatelessWidget {
  final ScoutXClusterBin bin;
  final Color accent;
  const _ClusterBin({required this.bin, required this.accent});

  @override
  Widget build(BuildContext context) {
    final pulse = bin.pulse;
    final borderColor =
        pulse > 0.3 ? accent : ScoutXScraper.cardBorder;
    final scale = 1 + 0.04 * math.sin(math.pi * pulse);

    return Positioned(
      left: bin.x,
      top: bin.y,
      width: bin.w,
      height: bin.h,
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ScoutXScraper.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12 * pulse),
                blurRadius: 5,
                spreadRadius: 5 * pulse,
              ),
              const BoxShadow(
                color: Color(0x0D14161B),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bin.name,
                  style: const TextStyle(
                    fontFamily: 'Geologica',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ScoutXScraper.ink,
                  ),
                ),
                Text(
                  '${_fmtCount(bin.count)} roles',
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: pulse > 0.3 ? accent : ScoutXScraper.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FiringSlot extends StatelessWidget {
  final int i;
  final double t;
  final Color accent;

  const _FiringSlot({required this.i, required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final slotT = sxMod(t - i * ScoutXScraper.step, ScoutXScraper.loop);
    if (slotT > ScoutXScraperK.end) return const SizedBox.shrink();

    final companyIdx = sxCompanyAt(i, t - slotT);
    final pos = scoutxScraperSlots[i];
    const mx = ScoutXScraper.muzzleX;
    const my = ScoutXScraper.muzzleY;
    final vx = mx - pos.dx;
    final vy = my - pos.dy;
    final f = math.max(
      vx.abs() / (ScoutXScraper.tw / 2 + 6),
      vy.abs() / (ScoutXScraper.th / 2 + 6),
    );
    final ex = pos.dx + vx / f;
    final ey = pos.dy + vy / f;
    final fade = 1 - sxEnter(sxSeg(slotT, ScoutXScraperK.out, ScoutXScraperK.end));
    final appear = sxPop(sxSeg(slotT, 0, 0.3));
    final cardScale =
        (0.7 + 0.3 * appear) *
        (1 + 0.08 * sxBumpAt(slotT, ScoutXScraperK.hit, ScoutXScraperK.hit + 0.3));
    final drawT = sxEnter(sxSeg(slotT, ScoutXScraperK.fire, ScoutXScraperK.fire + 0.14));
    final u = sxDraw(sxSeg(slotT, ScoutXScraperK.fire, ScoutXScraperK.hit));
    final flying = slotT >= ScoutXScraperK.fire && slotT < ScoutXScraperK.hit;
    final hx = sxLerp(mx, ex, u);
    final hy = sxLerp(my, ey, u);
    final hit = slotT >= ScoutXScraperK.hit;
    final lineOp = (hit
            ? 0.5 -
                0.36 * sxEnter(sxSeg(slotT, ScoutXScraperK.hit, ScoutXScraperK.hit + 0.5))
            : 0.16) *
        fade;
    final ring = sxSeg(slotT, ScoutXScraperK.hit, ScoutXScraperK.hit + 0.55);
    final badgePop = sxPop(sxSeg(slotT, ScoutXScraperK.badge, ScoutXScraperK.badge + 0.3));
    final lit = hit && slotT < ScoutXScraperK.out;
    final roles = scoutXRoleBadges[i % scoutXRoleBadges.length];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (slotT >= ScoutXScraperK.fire)
          CustomPaint(
            size: const Size(ScoutXScraper.cw, ScoutXScraper.ch),
            painter: _FiringLinePainter(
              mx: mx,
              my: my,
              ex: ex,
              ey: ey,
              hx: hx,
              hy: hy,
              u: u,
              drawT: drawT,
              flying: flying,
              hit: hit,
              lineOpacity: lineOp,
              accent: accent,
            ),
          ),
        if (hit && ring < 1)
          Positioned(
            left: pos.dx - ScoutXScraper.tw / 2,
            top: pos.dy - ScoutXScraper.th / 2,
            child: Transform.scale(
              scale: 1 + 0.32 * sxEnter(ring),
              child: Opacity(
                opacity: 0.6 * (1 - ring),
                child: Container(
                  width: ScoutXScraper.tw,
                  height: ScoutXScraper.th,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent, width: 2),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: pos.dx - ScoutXScraper.tw / 2,
          top: pos.dy - ScoutXScraper.th / 2,
          child: Opacity(
            opacity: math.min(appear * 1.4, 1) * fade,
            child: Transform.scale(
              scale: cardScale,
              child: Container(
                width: ScoutXScraper.tw,
                height: ScoutXScraper.th,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: ScoutXScraper.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: lit ? accent : ScoutXScraper.cardBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (lit)
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 5,
                        spreadRadius: 5,
                      ),
                    const BoxShadow(
                      color: Color(0x1414161B),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _Logo(companyIdx),
              ),
            ),
          ),
        ),
        if (slotT >= ScoutXScraperK.badge)
          Positioned(
            left: pos.dx + ScoutXScraper.tw / 2 - 34,
            top: pos.dy - ScoutXScraper.th / 2 - 14,
            child: Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: badgePop,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.33),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    '+$roles',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geologica',
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FiringLinePainter extends CustomPainter {
  final double mx;
  final double my;
  final double ex;
  final double ey;
  final double hx;
  final double hy;
  final double u;
  final double drawT;
  final bool flying;
  final bool hit;
  final double lineOpacity;
  final Color accent;

  _FiringLinePainter({
    required this.mx,
    required this.my,
    required this.ex,
    required this.ey,
    required this.hx,
    required this.hy,
    required this.u,
    required this.drawT,
    required this.flying,
    required this.hit,
    required this.lineOpacity,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final exDraw = lerpDouble(mx, ex, drawT)!;
    final eyDraw = lerpDouble(my, ey, drawT)!;
    canvas.drawLine(
      Offset(mx, my),
      Offset(exDraw, eyDraw),
      Paint()
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = (hit ? accent : ScoutXScraper.ink)
            .withValues(alpha: lineOpacity),
    );

    if (flying) {
      final tu = math.max(0, u - 0.2).toDouble();
      final tx = sxLerp(mx, ex, tu);
      final ty = sxLerp(my, ey, tu);
      canvas.drawLine(
        Offset(tx, ty),
        Offset(hx, hy),
        Paint()
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.2),
      );
      canvas.drawLine(
        Offset(tx, ty),
        Offset(hx, hy),
        Paint()
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [accent.withValues(alpha: 0), accent],
          ).createShader(Rect.fromPoints(Offset(tx, ty), Offset(hx, hy))),
      );
      canvas.drawCircle(
        Offset(hx, hy),
        5.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(hx, hy),
        5.5,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FiringLinePainter old) => true;
}

class _Logo extends StatelessWidget {
  final int companyIndex;
  const _Logo(this.companyIndex);

  @override
  Widget build(BuildContext context) {
    final asset = scoutxLogoAsset(companyIndex);
    final domain =
        scoutxScraperDomains[companyIndex % scoutxScraperDomains.length];
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Image.network(scoutxFavicon(domain)),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.network(scoutxFavicon(domain)),
    );
  }
}