import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../auth/auth_controller.dart';
import '../../profile/screens/help_pages.dart';
import '../../../theme/welcome_tokens.dart';
import '../widgets/firststep_logo.dart';
import '../widgets/liquid_wave_painter.dart';

/// Sign In screen matching 01-welcome-and-sign-in.html:
/// - Liquid wave header with pour & breathe animation.
/// - Top right theme toggle (Light / Dark).
/// - FirstStep branding & "Everything you need to land your US job."
/// - Rotating 4 pillars ("Apply · Find · Learn · Stay informed") with cycling highlight.
/// - 2x2 SSO Grid: Google (with "Last used" pill), Apple, LinkedIn, GitHub.
/// - Tactile scale-down on press (.sso:active { transform: scale(.97) }).
/// - Staggered fadeUp entrance animations matching the spec.
/// - Referral code accordion with uppercase code input and Apply button.
/// - Legal agreement footer.
class SignInScreen extends StatefulWidget {
  final AuthController auth;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SignInScreen({
    super.key,
    required this.auth,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  int _activePillar = 0;
  Timer? _pillarTimer;

  bool _showReferralField = false;
  final TextEditingController _referralController = TextEditingController();

  static const _pillars = ['Apply', 'Find', 'Learn', 'Stay informed'];

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    // Rotate active pillar every 1800ms
    _pillarTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() => _activePillar = (_activePillar + 1) % _pillars.length);
      }
    });

    // Entrance animation matching the spec: 1200ms total
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pillarTimer?.cancel();
    _referralController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  bool get _busy =>
      widget.auth.phase == AuthPhase.authenticating ||
      widget.auth.phase == AuthPhase.bootstrapping;

  Future<void> _onSSOTapped(String provider) async {
    if (_busy) return;
    if (provider == 'GitHub' && !widget.auth.githubEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GitHub sign-in is not enabled for this build.'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF04141C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.auth.setPendingReferralCode(_referralController.text);
    // Auth0 connections: google-oauth2 | apple | linkedin | github
    switch (provider) {
      case 'Apple':
        await widget.auth.signInWithApple();
      case 'LinkedIn':
        await widget.auth.signInWithLinkedIn();
      case 'GitHub':
        await widget.auth.signInWithGitHub();
      default:
        await widget.auth.signInWithGoogle();
    }
    if (!mounted) return;
    final err = widget.auth.errorMessage;
    if (widget.auth.phase == AuthPhase.error && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF8B1E1E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await widget.auth.dismissErrorToSignedOut();
    }
  }

  Future<void> _applyReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    widget.auth.setPendingReferralCode(code);
    String message = 'Code "$code" saved! It will link when sign-in finishes.';
    try {
      final lookup = await widget.auth.lookupReferral(code);
      if (lookup['found'] == true && lookup['firstName'] is String) {
        message = 'Invited by ${lookup['firstName']}. Code saved for sign-in.';
      }
    } catch (_) {
      // Keep local save message if lookup fails.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF24834F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Animation<double> _curved(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: WelcomeCurves.easeOutCubic),
    );
  }

  Widget _fadeUp({
    required Animation<double> animation,
    required Widget child,
    double dy = 14.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final val = animation.value;
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy * (1.0 - val)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.lgBottom,
      body: Stack(
        children: [
          // Background Liquid Wave Header
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LiquidWaveWidget(
              height: 380,
            ),
          ),
          // Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top Header area (Logo, Pillars, Theme Button)
                _buildHeader(tokens),
                const Spacer(),
                // Bottom Area (SSO Grid, Referral Code, Legal)
                _buildBottomArea(tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WelcomeTokens tokens) {
    final logoAnim = _curved(0.25, 0.65);
    final tagAnim = _curved(0.35, 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Row with Theme Toggle button at top-right
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: widget.onToggleTheme,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.lgBtnLine),
                ),
                child: Icon(
                  widget.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  size: 20,
                  color: tokens.lgInk,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // FirstStep Logo (fades up with authentic asset)
          _fadeUp(
            animation: logoAnim,
            child: FirstStepLogo(
              triangleWidth: 48,
              wordmarkWidth: 184,
              spacing: 12,
              isDark: widget.isDarkMode,
            ),
          ),
          const SizedBox(height: 14),
          // Slogan
          _fadeUp(
            animation: tagAnim,
            child: Text(
              'Everything you need to land your US job.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geologica',
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
                color: tokens.lgMute,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 4 Rotating Pillars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pillars.length * 2 - 1, (index) {
              final delayStart = (0.45 + (index * 0.04)).clamp(0.0, 0.85);
              final itemAnim = _curved(delayStart, (delayStart + 0.35).clamp(0.0, 1.0));

              if (index.isOdd) {
                return _fadeUp(
                  animation: itemAnim,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.teal2.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              final pillarIdx = index ~/ 2;
              final isActive = pillarIdx == _activePillar;

              return _fadeUp(
                animation: itemAnim,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  curve: WelcomeCurves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? tokens.hl : tokens.lgInk.withValues(alpha: 0.55),
                    letterSpacing: 0.2,
                  ),
                  child: Text(_pillars[pillarIdx]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea(WelcomeTokens tokens) {
    final labelAnim = _curved(0.12, 0.45);
    final sso1Anim = _curved(0.18, 0.50);
    final sso2Anim = _curved(0.24, 0.56);
    final sso3Anim = _curved(0.30, 0.62);
    final sso4Anim = _curved(0.36, 0.68);
    final footerAnim = _curved(0.40, 0.75);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Continue with" label
          _fadeUp(
            animation: labelAnim,
            child: const Text(
              'Continue with',
              style: TextStyle(
                fontFamily: 'Geologica',
                fontSize: 13.5,
                color: Color(0xFF9DB4BE),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 2x2 SSO: Google · Apple / LinkedIn · GitHub (Auth0 connections).
          Row(
            children: [
              Expanded(
                child: _fadeUp(
                  animation: sso1Anim,
                  child: _buildGoogleButton(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _fadeUp(
                  animation: sso2Anim,
                  child: _buildSSOButton(
                    label: 'Apple',
                    icon: const _AppleIcon(),
                    onTap: () => _onSSOTapped('Apple'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _fadeUp(
                  animation: sso3Anim,
                  child: _buildSSOButton(
                    label: 'LinkedIn',
                    icon: const _LinkedInIcon(),
                    onTap: () => _onSSOTapped('LinkedIn'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _fadeUp(
                  animation: sso4Anim,
                  child: _buildSSOButton(
                    label: 'GitHub',
                    icon: const _GitHubIcon(),
                    onTap: () => _onSSOTapped('GitHub'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // "Have a referral code?" toggle button
          _fadeUp(
            animation: footerAnim,
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _showReferralField = !_showReferralField);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7FD0DB),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Have a referral code?',
                    style: TextStyle(
                      fontFamily: 'Geologica',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Expandable Referral Code Box
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 350),
                  firstCurve: WelcomeCurves.easeOutCubic,
                  secondCurve: WelcomeCurves.easeOutCubic,
                  crossFadeState: _showReferralField
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: TextField(
                              controller: _referralController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontFamily: 'Geologica',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter referral code',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Geologica',
                                  color: Color(0xFF8FA6B0),
                                  fontSize: 14,
                                  letterSpacing: 0,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.06),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6CC3CF),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _applyReferralCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6CC3CF),
                              foregroundColor: const Color(0xFF04222F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontFamily: 'Geologica',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                // Legal disclaimer footer
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Geologica',
                      fontSize: 12,
                      height: 1.55,
                      color: Color(0xFF8FA6B0),
                    ),
                    children: [
                      const TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: Color(0xFFC9DDE3),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => openTermsPrivacy(context),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Color(0xFFC9DDE3),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => openTermsPrivacy(context),
                      ),
                      const TextSpan(text: '.\nWe never share your data.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return _InteractiveBounce(
      onTap: () => _onSSOTapped('Google'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleIcon(),
                SizedBox(width: 10),
                Text(
                  'Google',
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
          ),
          // "Last used" pill
          Positioned(
            top: -9,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6CC3CF),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Last used',
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF04222F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSSOButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return _InteractiveBounce(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Geologica',
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEAF2F4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile scale bounce on press (.sso:active { transform: scale(.97) })
class _InteractiveBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveBounce({required this.child, required this.onTap});

  @override
  State<_InteractiveBounce> createState() => _InteractiveBounceState();
}

class _InteractiveBounceState extends State<_InteractiveBounce> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// -------------------------------------------------------------
// Vector SSO Brand Icons
// -------------------------------------------------------------
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Blue horizontal bar
    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, h * 0.38, w * 0.98, h * 0.62),
      paintBlue,
    );

    // Blue arc
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.78), -0.7, 1.4, false, strokePaint);

    // Green arc (bottom)
    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.78), 0.7, 1.6, false, strokePaint);

    // Yellow arc (bottom-left)
    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.78), 2.3, 1.6, false, strokePaint);

    // Red arc (top)
    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.78), 3.9, 1.6, false, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.apple,
      size: 22,
      color: Colors.white,
    );
  }
}

class _LinkedInIcon extends StatelessWidget {
  const _LinkedInIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF0A66C2),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'in',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          fontFamily: 'Geologica',
        ),
      ),
    );
  }
}

class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.code_rounded,
        size: 14,
        color: Color(0xFF0D1117),
      ),
    );
  }
}
