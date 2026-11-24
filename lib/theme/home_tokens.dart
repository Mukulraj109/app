import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home screen + bottom nav design tokens (02-home.html / README spec).
///
/// Mirrors the [WelcomeTokens] pattern: a ThemeExtension with light + dark
/// const sets, a null-safe [of] accessor, [copyWith] and [lerp].
///
/// Colour rules (README section 4):
/// - navy #06334A = main buttons, bottom bar, headings
/// - teal #4399A9 = hero arc, progress, links
/// - each pastel always means the same thing; text on a pastel uses its
///   deep tone; at most 2-3 pastels visible at once; red only for unread
///   dots and errors
/// - dark mode is black and white: pastels become one neutral grey, teal
///   #6CC3CF is the only accent
class Pastel {
  final Color bg;
  final Color fg;

  const Pastel(this.bg, this.fg);
}

@immutable
class HomeTokens extends ThemeExtension<HomeTokens> {
  final Color bg;
  final Color card;
  final Color line;
  final Color ink;
  final Color mute;

  final Color navy;
  final Color teal;
  final Color tealSoft;
  final Color tri;
  final Color status;

  final Color ctaBg;
  final Color ctaInk;

  final Color nav;
  final Color navInk;
  final Color navOn;

  final Color amberBg;
  final Color amber;
  final Color ok;
  final Color okBg;
  final Color wa;
  final Color alert;

  final Pastel lavender; // interviews, AI
  final Pastel butter;   // assessments, rewards, referral, leave notices
  final Pastel mint;     // applied, done, new activity
  final Pastel sky;      // immigration, news
  final Pastel peach;    // weekly tasks, learning

  final List<BoxShadow> cardShadow;

  const HomeTokens({
    required this.bg,
    required this.card,
    required this.line,
    required this.ink,
    required this.mute,
    required this.navy,
    required this.teal,
    required this.tealSoft,
    required this.tri,
    required this.status,
    required this.ctaBg,
    required this.ctaInk,
    required this.nav,
    required this.navInk,
    required this.navOn,
    required this.amberBg,
    required this.amber,
    required this.ok,
    required this.okBg,
    required this.wa,
    required this.alert,
    required this.lavender,
    required this.butter,
    required this.mint,
    required this.sky,
    required this.peach,
    required this.cardShadow,
  });

  /// Light theme: sky-blue wash over pure white — never a grey canvas.
  static const HomeTokens light = HomeTokens(
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE6EDF2),
    ink: Color(0xFF14232B),
    mute: Color(0xFF626D72),
    navy: Color(0xFF06334A),
    teal: Color(0xFF4399A9),
    tealSoft: Color(0xFFE2F0F3),
    tri: Color(0xFF06334A),
    status: Color(0xFF0B2A38),
    ctaBg: Color(0xFF06334A),
    ctaInk: Color(0xFFFFFFFF),
    nav: Color(0xFF06334A),
    navInk: Color(0xFFBFD3DA),
    navOn: Color(0x24FFFFFF),
    amberBg: Color(0xFFFFF4DE),
    amber: Color(0xFF8A5A0B),
    ok: Color(0xFF24834F),
    okBg: Color(0x1F2E9A61),
    wa: Color(0xFF1FAF55),
    alert: Color(0xFFE5533D),
    lavender: Pastel(Color(0xFFE6E0FB), Color(0xFF4B3A99)),
    butter: Pastel(Color(0xFFFBE9B7), Color(0xFF7A5408)),
    mint: Pastel(Color(0xFFD7F0DD), Color(0xFF1F6B3A)),
    sky: Pastel(Color(0xFFD3EAF6), Color(0xFF0E4A66)),
    peach: Pastel(Color(0xFFFCDFD2), Color(0xFF8A3B1E)),
    cardShadow: [
      BoxShadow(color: Color(0x0F28281E), blurRadius: 22, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0D28281E), blurRadius: 3, offset: Offset(0, 1)),
    ],
  );

  /// Dark theme — black and white; teal #6CC3CF is the only accent.
  static const HomeTokens dark = HomeTokens(
    bg: Color(0xFF000000),
    card: Color(0xFF141416),
    line: Color(0xFF26262A),
    ink: Color(0xFFF2F2F2),
    mute: Color(0xFF9A9A9F),
    navy: Color(0xFFFFFFFF), // CTAs flip to white
    teal: Color(0xFF6CC3CF),
    tealSoft: Color(0xFF1F1F22),
    tri: Color(0xFFFFFFFF),
    status: Color(0xFFF2F2F2),
    ctaBg: Color(0xFFFFFFFF),
    ctaInk: Color(0xFF000000),
    nav: Color(0xFF141416),
    navInk: Color(0xFF8E8E93),
    navOn: Color(0x1FFFFFFF),
    amberBg: Color(0xFF1F1F22),
    amber: Color(0xFFE6E6E6),
    ok: Color(0xFFE6E6E6),
    okBg: Color(0xFF1F1F22),
    wa: Color(0xFF3DDC84),
    alert: Color(0xFFE5533D),
    lavender: Pastel(Color(0xFF1F1F22), Color(0xFFE6E6E6)),
    butter: Pastel(Color(0xFF1F1F22), Color(0xFFE6E6E6)),
    mint: Pastel(Color(0xFF1F1F22), Color(0xFFE6E6E6)),
    sky: Pastel(Color(0xFF1F1F22), Color(0xFFE6E6E6)),
    peach: Pastel(Color(0xFF1F1F22), Color(0xFFE6E6E6)),
    cardShadow: [
      BoxShadow(color: Color(0x99000000), blurRadius: 26, offset: Offset(0, 10)),
    ],
  );

  /// Null-safe accessor; falls back to light/dark by brightness.
  static HomeTokens of(BuildContext context) {
    final ext = Theme.of(context).extension<HomeTokens>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  @override
  HomeTokens copyWith({
    Color? bg,
    Color? card,
    Color? line,
    Color? ink,
    Color? mute,
    Color? navy,
    Color? teal,
    Color? tealSoft,
    Color? tri,
    Color? status,
    Color? ctaBg,
    Color? ctaInk,
    Color? nav,
    Color? navInk,
    Color? navOn,
    Color? amberBg,
    Color? amber,
    Color? ok,
    Color? okBg,
    Color? wa,
    Color? alert,
    Pastel? lavender,
    Pastel? butter,
    Pastel? mint,
    Pastel? sky,
    Pastel? peach,
    List<BoxShadow>? cardShadow,
  }) {
    return HomeTokens(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      mute: mute ?? this.mute,
      navy: navy ?? this.navy,
      teal: teal ?? this.teal,
      tealSoft: tealSoft ?? this.tealSoft,
      tri: tri ?? this.tri,
      status: status ?? this.status,
      ctaBg: ctaBg ?? this.ctaBg,
      ctaInk: ctaInk ?? this.ctaInk,
      nav: nav ?? this.nav,
      navInk: navInk ?? this.navInk,
      navOn: navOn ?? this.navOn,
      amberBg: amberBg ?? this.amberBg,
      amber: amber ?? this.amber,
      ok: ok ?? this.ok,
      okBg: okBg ?? this.okBg,
      wa: wa ?? this.wa,
      alert: alert ?? this.alert,
      lavender: lavender ?? this.lavender,
      butter: butter ?? this.butter,
      mint: mint ?? this.mint,
      sky: sky ?? this.sky,
      peach: peach ?? this.peach,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  HomeTokens lerp(Object? other, double t) {
    if (other is! HomeTokens) return this;
    final m = t < 1 - t ? 1 - t : t;
    return HomeTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t)!,
      tri: Color.lerp(tri, other.tri, t)!,
      status: Color.lerp(status, other.status, t)!,
      ctaBg: Color.lerp(ctaBg, other.ctaBg, t)!,
      ctaInk: Color.lerp(ctaInk, other.ctaInk, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      navInk: Color.lerp(navInk, other.navInk, t)!,
      navOn: Color.lerp(navOn, other.navOn, t)!,
      amberBg: Color.lerp(amberBg, other.amberBg, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      okBg: Color.lerp(okBg, other.okBg, t)!,
      wa: Color.lerp(wa, other.wa, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      lavender: Pastel(
        Color.lerp(lavender.bg, other.lavender.bg, m)!,
        Color.lerp(lavender.fg, other.lavender.fg, m)!,
      ),
      butter: Pastel(
        Color.lerp(butter.bg, other.butter.bg, m)!,
        Color.lerp(butter.fg, other.butter.fg, m)!,
      ),
      mint: Pastel(
        Color.lerp(mint.bg, other.mint.bg, m)!,
        Color.lerp(mint.fg, other.mint.fg, m)!,
      ),
      sky: Pastel(
        Color.lerp(sky.bg, other.sky.bg, m)!,
        Color.lerp(sky.fg, other.sky.fg, m)!,
      ),
      peach: Pastel(
        Color.lerp(peach.bg, other.peach.bg, m)!,
        Color.lerp(peach.fg, other.peach.fg, m)!,
      ),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

/// Named curves for Home motion (reuses WelcomeCurves where identical).
class HomeCurves {
  HomeCurves._();

  /// 450-700 ms entrances, 350 ms arc segments, 320 ms pill.
  static const Curve easeOutCubic = Cubic(0.22, 0.8, 0.24, 1.0);

  /// Applying-segment breathing (1.8 s loop).
  static const Curve easeInOut = Curves.easeInOut;
}
