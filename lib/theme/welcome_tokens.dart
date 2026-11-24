import 'package:flutter/material.dart';

/// Design tokens for Welcome & Sign-In flow matching 01-welcome-and-sign-in.html.
/// Implemented as a ThemeExtension to support flawless light and dark theming.
@immutable
class WelcomeTokens extends ThemeExtension<WelcomeTokens> {
  final Color bg;
  final Color ink;
  final Color mute;
  final Color card;
  final Color line;
  final Color teal;
  final Color teal2;
  final Color tealSoft;
  final Color hl;
  final Color glow;
  final Color triColor;
  final Color firstColor;
  final Color stepColor;
  final Color skipBg;
  final Color skipInk;
  final Color ctaBg;
  final Color ctaInk;
  final Color statusColor;
  final Color okBg;
  final Color okColor;
  final Color visaBg;
  final Color visaColor;

  // Sign-in liquid wave header tokens
  final Color lgTop;
  final Color lgBottom;
  final Color lgInk;
  final Color lgMute;
  final Color lgBtnLine;
  final double lineOpacity;

  // Shadows
  final List<BoxShadow> cardShadow;

  const WelcomeTokens({
    required this.bg,
    required this.ink,
    required this.mute,
    required this.card,
    required this.line,
    required this.teal,
    required this.teal2,
    required this.tealSoft,
    required this.hl,
    required this.glow,
    required this.triColor,
    required this.firstColor,
    required this.stepColor,
    required this.skipBg,
    required this.skipInk,
    required this.ctaBg,
    required this.ctaInk,
    required this.statusColor,
    required this.okBg,
    required this.okColor,
    required this.visaBg,
    required this.visaColor,
    required this.lgTop,
    required this.lgBottom,
    required this.lgInk,
    required this.lgMute,
    required this.lgBtnLine,
    required this.lineOpacity,
    required this.cardShadow,
  });

  static const WelcomeTokens light = WelcomeTokens(
    bg: Color(0xFFFFFFFF),
    ink: Color(0xFF0B2A38),
    mute: Color(0xFF5B707A),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFDCE7EB),
    teal: Color(0xFF2F8090),
    teal2: Color(0xFF4399A9),
    tealSoft: Color(0xFFE2F0F3),
    hl: Color(0xFF2F8090),
    glow: Color(0x334399A9), // rgba(67, 153, 169, 0.20)
    triColor: Color(0xFF06334A),
    firstColor: Color(0xFF06334A),
    stepColor: Color(0xFF4399A9),
    skipBg: Color(0xFFFFFFFF),
    skipInk: Color(0xFF0B2A38),
    ctaBg: Color(0xFF06334A),
    ctaInk: Color(0xFFFFFFFF),
    statusColor: Color(0xFF0B2A38),
    okBg: Color(0x1F2E9A61), // rgba(46, 154, 97, 0.12)
    okColor: Color(0xFF24834F),
    visaBg: Color(0x23D6961E), // rgba(214, 150, 30, 0.14)
    visaColor: Color(0xFF9A6510),
    lgTop: Color(0xFFFFFFFF),
    lgBottom: Color(0xFF06334A),
    lgInk: Color(0xFF0B2A38),
    lgMute: Color(0xFF5B707A),
    lgBtnLine: Color(0xFFDCE7EB),
    lineOpacity: 0.0,
    cardShadow: [
      BoxShadow(
        color: Color(0x1A06334A), // rgba(6, 51, 74, 0.10)
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x0D06334A), // rgba(6, 51, 74, 0.05)
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const WelcomeTokens dark = WelcomeTokens(
    bg: Color(0xFF071821),
    ink: Color(0xFFEAF2F4),
    mute: Color(0xFF8FA6B0),
    card: Color(0xFF0F2531),
    line: Color(0xFF1B3846),
    teal: Color(0xFF6CC3CF),
    teal2: Color(0xFF4399A9),
    tealSoft: Color(0xFF123542),
    hl: Color(0xFF6CC3CF),
    glow: Color(0x474399A9), // rgba(67, 153, 169, 0.28)
    triColor: Color(0xFFFFFFFF),
    firstColor: Color(0xFFFFFFFF),
    stepColor: Color(0xFF6CC3CF),
    skipBg: Color(0xFF12303D),
    skipInk: Color(0xFFEAF2F4),
    ctaBg: Color(0xFF6CC3CF),
    ctaInk: Color(0xFF04222F),
    statusColor: Color(0xFFEAF2F4),
    okBg: Color(0x244CC887), // rgba(76, 200, 135, 0.14)
    okColor: Color(0xFF6FD49C),
    visaBg: Color(0x24F2C46B), // rgba(242, 196, 107, 0.14)
    visaColor: Color(0xFFF2C46B),
    lgTop: Color(0x00071821), // transparent top in dark mode
    lgBottom: Color(0xFF071821),
    lgInk: Color(0xFFEAF2F4),
    lgMute: Color(0xFF8FA6B0),
    lgBtnLine: Color(0x2EFFFFFF), // rgba(255, 255, 255, 0.18)
    lineOpacity: 1.0,
    cardShadow: [
      BoxShadow(
        color: Color(0x73000000), // rgba(0, 0, 0, 0.45)
        blurRadius: 32,
        offset: Offset(0, 14),
      ),
    ],
  );

  static WelcomeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<WelcomeTokens>();
    if (tokens != null) return tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  @override
  ThemeExtension<WelcomeTokens> copyWith({
    Color? bg,
    Color? ink,
    Color? mute,
    Color? card,
    Color? line,
    Color? teal,
    Color? teal2,
    Color? tealSoft,
    Color? hl,
    Color? glow,
    Color? triColor,
    Color? firstColor,
    Color? stepColor,
    Color? skipBg,
    Color? skipInk,
    Color? ctaBg,
    Color? ctaInk,
    Color? statusColor,
    Color? okBg,
    Color? okColor,
    Color? visaBg,
    Color? visaColor,
    Color? lgTop,
    Color? lgBottom,
    Color? lgInk,
    Color? lgMute,
    Color? lgBtnLine,
    double? lineOpacity,
    List<BoxShadow>? cardShadow,
  }) {
    return WelcomeTokens(
      bg: bg ?? this.bg,
      ink: ink ?? this.ink,
      mute: mute ?? this.mute,
      card: card ?? this.card,
      line: line ?? this.line,
      teal: teal ?? this.teal,
      teal2: teal2 ?? this.teal2,
      tealSoft: tealSoft ?? this.tealSoft,
      hl: hl ?? this.hl,
      glow: glow ?? this.glow,
      triColor: triColor ?? this.triColor,
      firstColor: firstColor ?? this.firstColor,
      stepColor: stepColor ?? this.stepColor,
      skipBg: skipBg ?? this.skipBg,
      skipInk: skipInk ?? this.skipInk,
      ctaBg: ctaBg ?? this.ctaBg,
      ctaInk: ctaInk ?? this.ctaInk,
      statusColor: statusColor ?? this.statusColor,
      okBg: okBg ?? this.okBg,
      okColor: okColor ?? this.okColor,
      visaBg: visaBg ?? this.visaBg,
      visaColor: visaColor ?? this.visaColor,
      lgTop: lgTop ?? this.lgTop,
      lgBottom: lgBottom ?? this.lgBottom,
      lgInk: lgInk ?? this.lgInk,
      lgMute: lgMute ?? this.lgMute,
      lgBtnLine: lgBtnLine ?? this.lgBtnLine,
      lineOpacity: lineOpacity ?? this.lineOpacity,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  ThemeExtension<WelcomeTokens> lerp(
    covariant ThemeExtension<WelcomeTokens>? other,
    double t,
  ) {
    if (other is! WelcomeTokens) return this;
    return WelcomeTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      teal2: Color.lerp(teal2, other.teal2, t)!,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t)!,
      hl: Color.lerp(hl, other.hl, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      triColor: Color.lerp(triColor, other.triColor, t)!,
      firstColor: Color.lerp(firstColor, other.firstColor, t)!,
      stepColor: Color.lerp(stepColor, other.stepColor, t)!,
      skipBg: Color.lerp(skipBg, other.skipBg, t)!,
      skipInk: Color.lerp(skipInk, other.skipInk, t)!,
      ctaBg: Color.lerp(ctaBg, other.ctaBg, t)!,
      ctaInk: Color.lerp(ctaInk, other.ctaInk, t)!,
      statusColor: Color.lerp(statusColor, other.statusColor, t)!,
      okBg: Color.lerp(okBg, other.okBg, t)!,
      okColor: Color.lerp(okColor, other.okColor, t)!,
      visaBg: Color.lerp(visaBg, other.visaBg, t)!,
      visaColor: Color.lerp(visaColor, other.visaColor, t)!,
      lgTop: Color.lerp(lgTop, other.lgTop, t)!,
      lgBottom: Color.lerp(lgBottom, other.lgBottom, t)!,
      lgInk: Color.lerp(lgInk, other.lgInk, t)!,
      lgMute: Color.lerp(lgMute, other.lgMute, t)!,
      lgBtnLine: Color.lerp(lgBtnLine, other.lgBtnLine, t)!,
      lineOpacity: lineOpacity + (other.lineOpacity - lineOpacity) * t,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

/// Motion curves matching the spec
class WelcomeCurves {
  /// cubic-bezier(.22,.8,.24,1) -> Flutter Curves.easeOutCubic
  static const Curve easeOutCubic = Cubic(0.22, 0.8, 0.24, 1.0);

  /// cubic-bezier(.3,1.3,.5,1) -> Pop/badge overshoot curve
  static const Curve easePop = Cubic(0.3, 1.3, 0.5, 1.0);

  /// cubic-bezier(.6,.05,.3,1) -> Underline draw curve
  static const Curve easeDraw = Cubic(0.6, 0.05, 0.3, 1.0);

  /// Curves.easeInOutCubic -> Wave breathing curve
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
}
