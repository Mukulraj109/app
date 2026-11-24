import 'package:flutter/material.dart';

/// ScoutX landing palette — mirrored from ScoutXLandingContent.tsx `SX`.
abstract final class ScoutXTokens {
  static const navy = Color(0xFF023345);
  static const ink = Color(0xFF0E2D3A);
  static const body = Color(0xFF0E2D3A);
  static const teal = Color(0xFF1F8A7D);
  static const tealCta = Color(0xFF4DB6A8);
  static const tealSoft = Color(0xFF7FD6C8);
  static const mint = Color(0xFFE3F3F0);
  static const paper = Color(0xFFF7F9FA);
  static const paperAlt = Color(0xFFEEF3F4);
  static const muted = Color(0xFF5B6B73);
  static const mutedSoft = Color(0xFF8A979D);
  static const border = Color(0xFFDDE5E8);
  static const borderSoft = Color(0xFFE3E9EB);
  static const borderStrong = Color(0xFFCDD8DC);
  static const white = Color(0xFFFFFFFF);

  static const fontFamily = 'Geologica';

  static TextStyle get display => const TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: ink,
        height: 1.05,
      );

  static TextStyle get bodyText => const TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.55,
      );

  static const monoLabel = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 1.0,
    color: teal,
  );
}
