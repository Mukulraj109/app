import 'package:flutter/material.dart';

/// FirstStep brand mark and wordmark widget.
/// Uses the transparent high-resolution assets extracted directly from the official logo.
/// - Triangle: assets/icons/triangle.png (Navy) or triangle_white.png (White)
/// - Wordmark: assets/icons/wordmark.png (Navy + Teal) or wordmark_dark.png (White + Cyan)
class FirstStepLogo extends StatelessWidget {
  final double triangleWidth;
  final double? fontSize;
  final double? wordmarkWidth;
  final bool showWordmark;
  final double spacing;
  final bool? isDark;

  const FirstStepLogo({
    super.key,
    this.triangleWidth = 46.0,
    this.fontSize,
    this.wordmarkWidth,
    this.showWordmark = true,
    this.spacing = 12.0,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    // Logo aspect ratio is 3958 / 936 = 4.2286
    final wmWidth = wordmarkWidth ?? (triangleWidth * 3.8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FirstStepTriangle(
          width: triangleWidth,
          isDark: dark,
        ),
        if (showWordmark) ...[
          SizedBox(width: spacing),
          FirstStepWordmark(
            width: wmWidth,
            isDark: dark,
          ),
        ],
      ],
    );
  }
}

/// Standalone triangle mark with transparent background
class FirstStepTriangle extends StatelessWidget {
  final double width;
  final bool? isDark;
  final Color? color;

  const FirstStepTriangle({
    super.key,
    required this.width,
    this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    // Aspect ratio 1246 / 971 = 1.2832
    final height = width / (1246.0 / 971.0);

    if (color != null) {
      return Image.asset(
        'assets/icons/triangle_white.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    }

    return Image.asset(
      dark ? 'assets/icons/triangle_white.png' : 'assets/icons/triangle.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

/// Exact extracted "FirstStep" wordmark with custom branding
class FirstStepWordmark extends StatelessWidget {
  final double width;
  final bool? isDark;

  const FirstStepWordmark({
    super.key,
    this.width = 184.0,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    // Aspect ratio 3958 / 936 = 4.2286
    final height = width / (3958.0 / 936.0);

    return Image.asset(
      dark ? 'assets/icons/wordmark_dark.png' : 'assets/icons/wordmark.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
