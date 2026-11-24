import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/home_tokens.dart';

/// Full-screen Gemini-style wash. Sit behind page content with [Positioned.fill].
/// Stronger / blurrier / more motion at the top; fades into [bg] toward the bottom.
///
/// Driven at ~20fps — the motion is slow enough that 60fps wastes paint work.
class LiquidWashBackdrop extends StatefulWidget {
  final double intensity;

  const LiquidWashBackdrop({super.key, this.intensity = 1.0});

  @override
  State<LiquidWashBackdrop> createState() => _LiquidWashBackdropState();
}

class _LiquidWashBackdropState extends State<LiquidWashBackdrop>
    with WidgetsBindingObserver {
  static const _period = Duration(seconds: 16);
  static const _tick = Duration(milliseconds: 50); // ~20fps

  double _phase = 0;
  Timer? _timer;
  DateTime _started = DateTime.now();
  Duration _elapsedAtPause = Duration.zero;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _started = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || _paused) return;
      final elapsed = DateTime.now().difference(_started).inMilliseconds +
          _elapsedAtPause.inMilliseconds;
      final t = (elapsed % _period.inMilliseconds) / _period.inMilliseconds;
      setState(() => _phase = t * math.pi * 2);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _paused = false;
      _started = DateTime.now();
      _startTimer();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _elapsedAtPause = DateTime.now().difference(_started) + _elapsedAtPause;
      _paused = true;
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _pagePalette(isDark, widget.intensity);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _FullBleedWashPainter(
          phase: _phase,
          bg: t.bg,
          colors: colors,
          isDark: isDark,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Optional: wrap a single widget (legacy). Prefer [LiquidWashBackdrop] for pages.
class LiquidWash extends StatelessWidget {
  final Widget child;
  final bool fill;
  final double intensity;

  const LiquidWash({
    super.key,
    required this.child,
    this.fill = false,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Headers no longer paint their own wash — avoid the “box” look.
    if (!fill) return child;

    return _CardWash(intensity: intensity, child: child);
  }
}

class _CardWash extends StatefulWidget {
  final Widget child;
  final double intensity;

  const _CardWash({required this.child, required this.intensity});

  @override
  State<_CardWash> createState() => _CardWashState();
}

class _CardWashState extends State<_CardWash> {
  static const _period = Duration(seconds: 12);
  static const _tick = Duration(milliseconds: 50);

  double _phase = 0;
  Timer? _timer;
  DateTime _started = DateTime.now();

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_started).inMilliseconds;
      final t = (elapsed % _period.inMilliseconds) / _period.inMilliseconds;
      setState(() => _phase = t * math.pi * 2);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _pagePalette(isDark, widget.intensity);
    final base = isDark ? const Color(0xFF101820) : const Color(0xFFFFFFFF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FullBleedWashPainter(
                phase: _phase,
                bg: base,
                colors: colors,
                isDark: isDark,
                compact: true,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

List<Color> _pagePalette(bool isDark, double intensity) {
  final t = ((intensity.clamp(0.6, 1.4) - 0.6) / 0.8);
  // Blue-only wash — lighter at the top, fades into page bg.
  if (isDark) {
    return [
      Color.lerp(const Color(0xFF1A3850), const Color(0xFF2A5A78), t)!,
      Color.lerp(const Color(0xFF163248), const Color(0xFF245870), t)!,
      Color.lerp(const Color(0xFF1E4058), const Color(0xFF306888), t)!,
      Color.lerp(const Color(0xFF142838), const Color(0xFF1E4860), t)!,
    ];
  }
  return [
    Color.lerp(const Color(0xFFC8E4F5), const Color(0xFFA8D4EC), t)!,
    Color.lerp(const Color(0xFFD4EAF8), const Color(0xFFB6DCF0), t)!,
    Color.lerp(const Color(0xFFBCE0F2), const Color(0xFF96CEE8), t)!,
    Color.lerp(const Color(0xFFE0F0FA), const Color(0xFFC4E4F4), t)!,
  ];
}

class _FullBleedWashPainter extends CustomPainter {
  final double phase;
  final Color bg;
  final List<Color> colors;
  final bool isDark;
  final bool compact;

  _FullBleedWashPainter({
    required this.phase,
    required this.bg,
    required this.colors,
    required this.isDark,
    this.compact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    final w = size.width;
    final h = size.height;

    // Motion & opacity fall off with depth (top = strong, bottom = quiet).
    void blob({
      required Color c,
      required double nx,
      required double ny,
      required double radiusFrac,
      required double ampX,
      required double ampY,
      required double speed,
      required double baseAlpha,
      double phaseOff = 0,
    }) {
      final depth = ny.clamp(0.0, 1.0);
      // Top third keeps most energy; bottom third almost still / faint.
      final falloff = math.pow(1.0 - depth, 1.65).toDouble();
      final motion = 0.15 + 0.85 * falloff;
      final alpha = baseAlpha * (0.25 + 0.75 * falloff);
      final blurBoost = 18 + 36 * falloff;

      final cx = w * (nx + ampX * motion * math.sin(phase * speed + phaseOff));
      final cy = h * (ny + ampY * motion * math.cos(phase * speed * 0.9 + phaseOff));
      final r = w * radiusFrac * (compact ? 1.15 : 1.0);

      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          r,
          [
            c.withValues(alpha: alpha),
            c.withValues(alpha: alpha * 0.4),
            c.withValues(alpha: 0),
          ],
          const [0.0, 0.5, 1.0],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurBoost);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    final a = isDark ? 0.28 : 0.42;

    // Cluster in the upper half so color “lives” at the top like Gemini.
    blob(
      c: colors[0],
      nx: 0.18,
      ny: 0.08,
      radiusFrac: compact ? 0.75 : 0.85,
      ampX: 0.08,
      ampY: 0.05,
      speed: 1.0,
      baseAlpha: a,
    );
    blob(
      c: colors[1],
      nx: 0.78,
      ny: 0.06,
      radiusFrac: compact ? 0.7 : 0.8,
      ampX: 0.07,
      ampY: 0.06,
      speed: 0.85,
      baseAlpha: a * 0.95,
      phaseOff: 1.1,
    );
    blob(
      c: colors[2],
      nx: 0.48,
      ny: 0.18,
      radiusFrac: compact ? 0.72 : 0.9,
      ampX: 0.1,
      ampY: 0.07,
      speed: 0.7,
      baseAlpha: a * 0.85,
      phaseOff: 2.2,
    );
    blob(
      c: colors[3],
      nx: 0.9,
      ny: 0.22,
      radiusFrac: compact ? 0.55 : 0.65,
      ampX: 0.06,
      ampY: 0.05,
      speed: 1.15,
      baseAlpha: a * 0.75,
      phaseOff: 0.6,
    );
    blob(
      c: colors[1],
      nx: 0.35,
      ny: 0.32,
      radiusFrac: compact ? 0.6 : 0.7,
      ampX: 0.09,
      ampY: 0.06,
      speed: 0.6,
      baseAlpha: a * 0.55,
      phaseOff: 3.0,
    );
    // Soft mid wash — already weak via falloff.
    blob(
      c: colors[0],
      nx: 0.62,
      ny: 0.48,
      radiusFrac: 0.55,
      ampX: 0.05,
      ampY: 0.04,
      speed: 0.5,
      baseAlpha: a * 0.35,
      phaseOff: 1.7,
    );

    // Dissolve into page white/bg — no hard edge / “banner box”.
    final fade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bg.withValues(alpha: 0.0),
          bg.withValues(alpha: 0.08),
          bg.withValues(alpha: 0.45),
          bg.withValues(alpha: 0.85),
          bg,
        ],
        // Reach pure white sooner so mid/lower page never reads grey.
        stops: compact
            ? const [0.0, 0.2, 0.45, 0.72, 1.0]
            : const [0.0, 0.18, 0.4, 0.62, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fade);
  }

  @override
  bool shouldRepaint(covariant _FullBleedWashPainter old) =>
      old.phase != phase ||
      old.bg != bg ||
      old.isDark != isDark ||
      old.compact != compact ||
      old.colors != colors;
}
