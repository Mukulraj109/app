import 'package:flutter/material.dart';

/// FirstStep Mobile — Vibrant brand system.
///
/// Light-first, punchy, playful. The muted navy/teal "corporate" palette is
/// gone in favor of a deep-indigo brand with coral / violet / cyan / lime
/// accents and warm colored-glow shadows. No google_fonts runtime fetch (that
/// janked first paint on an earlier pass) — headings use a bundled-agnostic
/// serif display stack, body uses the platform sans.
class FirstStepColors {
  // --- Core surfaces ---
  static const Color pageBg = Color(0xFFFFFFFF); // white canvas; sky wash sits on top
  static const Color white = Color(0xFFFFFFFF);
  static const Color warmCream = Color(0xFFFFF8EE);
  static const Color warmInk = Color(0xFF8A5A00);

  // --- Brand + accents ---
  static const Color teal = Color(0xFF2A1A6B); // deep indigo: headings, filled CTAs
  static const Color tealLight = Color(0xFF4A2BD6); // vivid indigo
  static const Color accent = Color(0xFFFF5C8A); // coral — primary energy
  static const Color accentSoft = Color(0xFFFFE3EE);
  static const Color accentGlow = Color(0xFFFF8FB8);

  static const Color violet = Color(0xFF7C4DFF);
  static const Color violetSoft = Color(0xFFECE4FF);
  static const Color cyan = Color(0xFF00C2E8);
  static const Color cyanSoft = Color(0xFFD6F6FF);
  static const Color lime = Color(0xFFC6F135);
  static const Color limeSoft = Color(0xFFEFF9CC);

  // --- Text ---
  static const Color textPrimary = Color(0xFF241663); // deep indigo
  static const Color textSecondary = Color(0xFF5A548A);
  static const Color textMuted = Color(0xFF8B85AE);
  static const Color textLight = Color(0x59241663);

  // --- Lines / glass ---
  static const Color border = Color(0x14241663);
  static const Color borderSubtle = Color(0x0A241663);
  static const Color borderAccent = Color(0x38FF5C8A);
  static const Color glassWhite = Color(0xE6FFFFFF);

  // --- Semantics ---
  static const Color success = Color(0xFF168A6F);
  static const Color successSoft = Color(0xFFE4F7F2);
  static const Color warning = Color(0xFFB57000);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFC74334);
  static const Color dangerSoft = Color(0xFFFDEEEC);
  static const Color whatsapp = Color(0xFF25D366);

  // --- Status chip pairs (bg + fg) ---
  static const Color submittedBg = Color(0xFFECE4FF);
  static const Color submittedFg = Color(0xFF7C4DFF);
  static const Color reviewingBg = Color(0xFFFFF4E0);
  static const Color reviewingFg = Color(0xFFB57000);
  static const Color interviewBg = Color(0xFFE4F7F2);
  static const Color interviewFg = Color(0xFF168A6F);
  static const Color offerBg = Color(0xFFEFF9CC);
  static const Color offerFg = Color(0xFF5C7A00);
  static const Color closedBg = Color(0xFFEEF1F3);
  static const Color closedFg = Color(0xFF6B7683);

  // --- Dark tokens (kept for now; unused on the live light path) ---
  static const Color darkCanvas = Color(0xFF090D12);
  static const Color darkCard = Color(0xFF131B24);
  static const Color darkCardElevated = Color(0xFF1B2633);
  static const Color darkBorder = Color(0x2E2DD4BF);
  static const Color neonTeal = Color(0xFF2DD4BF);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF94A3B8);
}

/// Small helper so any widget can grab a brand gradient for a hero surface.
extension FirstStepGrads on FirstStepColors {
  static const List<Color> heroStops = [
    Color(0xFF7C4DFF),
    Color(0xFFFF5C8A),
  ];
}

class FirstStepTheme {
  /// Matches ScoutX website / app-wide Geologica.
  static const String _font = 'Geologica';

  static TextStyle get displaySerif => const TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w700,
        color: FirstStepColors.teal,
        height: 1.12,
        letterSpacing: -0.5,
      );

  static TextStyle get bodySans => const TextStyle(
        fontFamily: _font,
        color: FirstStepColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get chipLabel => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFFFF5C8A)],
  );

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A2BD6), Color(0xFF7C4DFF), Color(0xFFFF5C8A)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: FirstStepColors.pageBg,
      primaryColor: FirstStepColors.teal,
      fontFamily: _font,
      colorScheme: const ColorScheme.light(
        primary: FirstStepColors.teal,
        secondary: FirstStepColors.accent,
        surface: FirstStepColors.white,
        error: FirstStepColors.danger,
        onPrimary: FirstStepColors.white,
        onSecondary: FirstStepColors.white,
        onSurface: FirstStepColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: FirstStepColors.teal),
      ),
    );
  }

  // Colored-glow shadows instead of flat black — the card reads "lifted",
  // not "outlined".
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x224A2BD6),
          blurRadius: 20,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get heroShadow => const [
        BoxShadow(
          color: Color(0x33FF5C8A),
          blurRadius: 24,
          offset: Offset(0, 10),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get violetGlow => const [
        BoxShadow(
          color: Color(0x337C4DFF),
          blurRadius: 22,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get coralGlow => const [
        BoxShadow(
          color: Color(0x33FF5C8A),
          blurRadius: 22,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get navShadow => const [
        BoxShadow(
          color: Color(0x2E4A2BD6),
          blurRadius: 20,
          offset: Offset(0, 8),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get subtleShadow => const [
        BoxShadow(
          color: Color(0x0F241663),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => cardShadow;

  // A smooth mix helper used by cards that want a custom-tinted glow.
  static Color lerpColor(Color a, Color b, double t) =>
      Color.lerp(a, b, t) ?? a;
}
