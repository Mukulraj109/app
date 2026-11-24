import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/auth_controller.dart';
import '../../theme/welcome_tokens.dart';
import 'screens/intro_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';

enum WelcomeStep { splash, intro, signIn }

/// Unified Welcome & Authentication Flow matching 01-welcome-and-sign-in.html:
/// 1. Splash Screen (<2s cold start animation)
/// 2. Intro Screen (4-slide carousel with auto-play & timer dot)
/// 3. Sign In Screen (dual-mode liquid wave, 2x2 SSO grid, referral field)
class WelcomeFlow extends StatefulWidget {
  final AuthController auth;
  final VoidCallback onFinished;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const WelcomeFlow({
    super.key,
    required this.auth,
    required this.onFinished,
    this.onThemeModeChanged,
    this.currentThemeMode = ThemeMode.light,
  });

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  static const _introSeenKey = 'firststep_intro_seen_v3';
  WelcomeStep _currentStep = WelcomeStep.splash;
  bool _introAlreadySeen = false;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.currentThemeMode;
    _checkIntroStatus();
  }

  Future<void> _checkIntroStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _introAlreadySeen = prefs.getBool(_introSeenKey) ?? false;
  }

  void _onSplashFinished() {
    if (!mounted) return;
    setState(() {
      _currentStep = _introAlreadySeen ? WelcomeStep.signIn : WelcomeStep.intro;
    });
  }

  Future<void> _onIntroContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introSeenKey, true);
    if (!mounted) return;
    setState(() {
      _introAlreadySeen = true;
      _currentStep = WelcomeStep.signIn;
    });
  }

  void _toggleTheme() {
    setState(() {
      final isDark = _themeMode == ThemeMode.dark ||
          (_themeMode == ThemeMode.system &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);

      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
    widget.onThemeModeChanged?.call(_themeMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final tokens = isDark ? WelcomeTokens.dark : WelcomeTokens.light;

    return Theme(
      data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        scaffoldBackgroundColor: tokens.bg,
        extensions: [tokens],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: WelcomeCurves.easeOutCubic,
        switchOutCurve: WelcomeCurves.easeOutCubic,
        child: _buildCurrentScreen(isDark),
      ),
    );
  }

  Widget _buildCurrentScreen(bool isDark) {
    switch (_currentStep) {
      case WelcomeStep.splash:
        return SplashScreen(
          key: const ValueKey('splash_screen'),
          onFinish: _onSplashFinished,
        );
      case WelcomeStep.intro:
        return IntroScreen(
          key: const ValueKey('intro_screen'),
          onContinue: _onIntroContinue,
        );
      case WelcomeStep.signIn:
        return SignInScreen(
          key: const ValueKey('sign_in_screen'),
          auth: widget.auth,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
    }
  }
}
