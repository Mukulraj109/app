import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/welcome_tokens.dart';
import '../widgets/animated_circle_progress.dart';
import '../widgets/drawn_underline.dart';
import '../widgets/firststep_logo.dart';

/// 4-Slide Intro Carousel matching 01-welcome-and-sign-in.html:
/// 1. Apply: Real team application counter, company list, "Proof added" badge
/// 2. Find: ScoutX radar card, stacked job cards with H-1B sponsor tag
/// 3. Learn: 82% circular progress, learning path, hexagon badges, AI mock interview
/// 4. Stay informed: 3 tilted news cards with tags and read times
///
/// Features:
/// - Auto-advances every 3600ms with a linear filling active dot indicator.
/// - Full swipe support via PageView (resets timer).
/// - Single "Continue ->" CTA button taking user directly to Sign In.
class IntroScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const IntroScreen({super.key, required this.onContinue});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  static const int _totalSlides = 4;
  static const int _dwellMs = 3600;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controller for the active dot progress fill (3600ms linear)
  late final AnimationController _dotTimerController;
  Timer? _autoPlayTimer;

  // Stagger controllers for each slide's content animations
  late final List<AnimationController> _slideControllers;

  @override
  void initState() {
    super.initState();

    _dotTimerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _dwellMs),
    );

    _slideControllers = List.generate(
      _totalSlides,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      ),
    );

    _playCurrentSlide();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _dotTimerController.dispose();
    _pageController.dispose();
    for (final c in _slideControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _playCurrentSlide() {
    _autoPlayTimer?.cancel();
    _slideControllers[_currentPage].forward(from: 0.0);
    _dotTimerController.forward(from: 0.0);

    // If not the last slide, schedule auto-advance
    if (_currentPage < _totalSlides - 1) {
      _autoPlayTimer = Timer(const Duration(milliseconds: _dwellMs), () {
        if (mounted && _currentPage < _totalSlides - 1) {
          _pageController.animateToPage(
            _currentPage + 1,
            duration: const Duration(milliseconds: 420),
            curve: WelcomeCurves.easeOutCubic,
          );
        }
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _playCurrentSlide();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 12, 28, 4),
              child: FirstStepLogo(
                triangleWidth: 28,
                wordmarkWidth: 110,
              ),
            ),
            // PageView of slides (takes majority of screen)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _Slide1Apply(controller: _slideControllers[0]),
                  _Slide2Find(controller: _slideControllers[1]),
                  _Slide3Learn(controller: _slideControllers[2]),
                  _Slide4Informed(controller: _slideControllers[3]),
                ],
              ),
            ),
            // Bottom area: Indicator dots, text area, and CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicator dots with active dot filling linearly
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalSlides, (i) {
                      final isActive = i == _currentPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: isActive ? 22 : 6,
                        decoration: BoxDecoration(
                          color: tokens.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isActive
                            ? (reduceMotion
                                ? Container(color: tokens.teal2)
                                : AnimatedBuilder(
                                    animation: _dotTimerController,
                                    builder: (context, _) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: _dotTimerController.value,
                                          child: Container(color: tokens.teal2),
                                        ),
                                      );
                                    },
                                  ))
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Headline & Subtitle
                  _buildHeadline(tokens),
                  const SizedBox(height: 10),
                  _buildSubtitle(tokens),
                  const SizedBox(height: 24),
                  // Continue CTA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.ctaBg,
                        foregroundColor: tokens.ctaInk,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontFamily: 'Geologica',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
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

  Widget _buildHeadline(WelcomeTokens tokens) {
    const style = TextStyle(
      fontFamily: 'Geologica',
      fontSize: 27,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.16,
    );

    switch (_currentPage) {
      case 0:
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('We ', style: style.copyWith(color: tokens.ink)),
            DrawnUnderlineText(
              text: 'apply',
              style: style.copyWith(color: tokens.hl),
              underlineColor: tokens.hl,
            ),
            Text(' for you, every day', style: style.copyWith(color: tokens.ink)),
          ],
        );
      case 1:
        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DrawnUnderlineText(
                  text: 'Find',
                  style: style.copyWith(color: tokens.hl),
                  underlineColor: tokens.hl,
                ),
                Text(' jobs', style: style.copyWith(color: tokens.ink)),
              ],
            ),
            Text(
              'before everyone else',
              textAlign: TextAlign.center,
              style: style.copyWith(color: tokens.ink),
            ),
          ],
        );
      case 2:
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DrawnUnderlineText(
              text: 'Learn',
              style: style.copyWith(color: tokens.hl),
              underlineColor: tokens.hl,
            ),
            Text(' and practise with a plan', style: style.copyWith(color: tokens.ink)),
          ],
        );
      case 3:
      default:
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Immigration news, ', style: style.copyWith(color: tokens.ink)),
            DrawnUnderlineText(
              text: 'explained',
              style: style.copyWith(color: tokens.hl),
              underlineColor: tokens.hl,
            ),
          ],
        );
    }
  }

  Widget _buildSubtitle(WelcomeTokens tokens) {
    String text;
    switch (_currentPage) {
      case 0:
        text = 'A real team sends applications for you while you focus on interviews.';
        break;
      case 1:
        text = 'Fresh roles on the job board, and ScoutX watching company career pages for you.';
        break;
      case 2:
        text = 'Skill checks, learning paths and mock interviews to get you ready.';
        break;
      case 3:
      default:
        text = 'Know what changes for your visa, AI and your industry, in plain words.';
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Geologica',
        fontSize: 14.5,
        color: tokens.mute,
        height: 1.45,
      ),
    );
  }
}

// -------------------------------------------------------------
// SLIDE 1: Apply
// -------------------------------------------------------------
class _Slide1Apply extends StatelessWidget {
  final AnimationController controller;
  const _Slide1Apply({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);

    // Stagger intervals:
    // Today card: 0.15 - 0.55
    // Applications list: 0.35 - 0.85
    // Proof badge: 0.70 - 1.00
    final todayFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.1, 0.45, curve: WelcomeCurves.easeOutCubic),
    );
    final listFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.25, 0.65, curve: WelcomeCurves.easeOutCubic),
    );
    final proofPop = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.65, 0.95, curve: WelcomeCurves.easePop),
    );

    return _SlideBackground(
      rotDeg: -8,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Today's summary card
                  FadeTransition(
                    opacity: todayFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(todayFade),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tokens.line),
                          boxShadow: tokens.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _PulsingGreenDot(),
                                const SizedBox(width: 8),
                                Text(
                                  'Your team is applying',
                                  style: TextStyle(
                                    fontFamily: 'Geologica',
                                    fontSize: 13,
                                    color: tokens.mute,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AnimatedBuilder(
                                  animation: controller,
                                  builder: (_, __) {
                                    final num = (12 + (6 * todayFade.value)).round();
                                    return Text(
                                      '$num',
                                      style: TextStyle(
                                        fontFamily: 'Geologica',
                                        fontSize: 40,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.ink,
                                        letterSpacing: -1.0,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'applications today',
                                  style: TextStyle(
                                    fontFamily: 'Geologica',
                                    fontSize: 14,
                                    color: tokens.mute,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Progress bar (72%)
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: tokens.tealSoft,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AnimatedBuilder(
                                animation: controller,
                                builder: (_, __) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (0.72 * todayFade.value).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: tokens.teal2,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Application list
                  FadeTransition(
                    opacity: listFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(listFade),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tokens.line),
                          boxShadow: tokens.cardShadow,
                        ),
                        child: Column(
                          children: [
                            _buildAppRow('S', const Color(0xFF2F8090), 'Data Engineer', 'Stripe', 'stripe.com', tokens),
                            Divider(height: 1, color: tokens.line),
                            _buildAppRow('C', const Color(0xFF06334A), 'Data Engineer II', 'Capital One', 'capitalone.com', tokens),
                            Divider(height: 1, color: tokens.line),
                            _buildAppRow('A', const Color(0xFFB5884B), 'Analytics Engineer', 'Airbnb', 'airbnb.com', tokens),
                            Divider(height: 1, color: tokens.line),
                            _buildAppRow('N', const Color(0xFF5B7684), 'Data Platform Engineer', 'Notion', 'notion.so', tokens),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Proof Added sticker (bottom right tilted -2 deg)
            Positioned(
              right: 28,
              bottom: 24,
              child: ScaleTransition(
                scale: proofPop,
                child: Transform.rotate(
                  angle: -2.0 * (math.pi / 180.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.line),
                      boxShadow: tokens.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: tokens.okColor),
                        const SizedBox(width: 6),
                        Text(
                          'Proof added',
                          style: TextStyle(
                            fontFamily: 'Geologica',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppRow(
    String letter,
    Color bg,
    String title,
    String company,
    String domain,
    WelcomeTokens tokens,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _CompanyLogoMark(letter: letter, bg: bg, domain: domain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.ink,
                  ),
                ),
                Text(
                  company,
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontSize: 12.5,
                    color: tokens.mute,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.okBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Applied',
              style: TextStyle(
                fontFamily: 'Geologica',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: tokens.okColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SLIDE 2: Find
// -------------------------------------------------------------
class _Slide2Find extends StatelessWidget {
  final AnimationController controller;
  const _Slide2Find({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);

    final scoutFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.1, 0.45, curve: WelcomeCurves.easeOutCubic),
    );
    final cardStack = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.3, 0.75, curve: WelcomeCurves.easeOutCubic),
    );

    return _SlideBackground(
      rotDeg: 14,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ScoutX card
              FadeTransition(
                opacity: scoutFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(scoutFade),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tokens.line),
                      boxShadow: tokens.cardShadow,
                    ),
                    child: Row(
                      children: [
                        _ScoutXRadarIcon(tokens: tokens),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ScoutX',
                                style: TextStyle(
                                  fontFamily: 'Geologica',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.ink,
                                ),
                              ),
                              Text(
                                'Watching your saved companies',
                                style: TextStyle(
                                  fontFamily: 'Geologica',
                                  fontSize: 12.5,
                                  color: tokens.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: tokens.tealSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '3 new',
                            style: TextStyle(
                              fontFamily: 'Geologica',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Stack of job cards
              SizedBox(
                height: 240,
                child: FadeTransition(
                  opacity: cardStack,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                    // Back card 2
                    Positioned(
                      top: 0,
                      left: 18,
                      right: 18,
                      child: Container(
                        height: 190,
                        decoration: BoxDecoration(
                          color: tokens.card.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tokens.line),
                        ),
                      ),
                    ),
                    // Back card 1
                    Positioned(
                      top: 12,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 190,
                        decoration: BoxDecoration(
                          color: tokens.card.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tokens.line),
                        ),
                      ),
                    ),
                    // Front card
                    Positioned(
                      top: 24,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tokens.line),
                          boxShadow: tokens.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _CompanyLogoMark(
                                  letter: 'R',
                                  bg: Color(0xFF06334A),
                                  domain: 'rivian.com',
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Senior Data Engineer',
                                        style: TextStyle(
                                          fontFamily: 'Geologica',
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.ink,
                                        ),
                                      ),
                                      Text(
                                        'Rivian · Austin, TX',
                                        style: TextStyle(
                                          fontFamily: 'Geologica',
                                          fontSize: 13,
                                          color: tokens.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Tag chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildTag('Full-time', tokens.tealSoft, tokens.teal),
                                _buildTag('H-1B sponsor', tokens.visaBg, tokens.visaColor),
                                _buildTag('Posted today', tokens.tealSoft, tokens.teal),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Ask my AIC CTA
                            Container(
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tokens.tealSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Ask my AIC to apply',
                                    style: TextStyle(
                                      fontFamily: 'Geologica',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 16, color: tokens.teal),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Geologica',
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// SLIDE 3: Learn
// -------------------------------------------------------------
class _Slide3Learn extends StatelessWidget {
  final AnimationController controller;
  const _Slide3Learn({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);

    final skillFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.1, 0.45, curve: WelcomeCurves.easeOutCubic),
    );
    final pathFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.3, 0.65, curve: WelcomeCurves.easeOutCubic),
    );
    final badgePop = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.65, 0.95, curve: WelcomeCurves.easePop),
    );
    final mockFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 0.85, curve: WelcomeCurves.easeOutCubic),
    );

    return _SlideBackground(
      rotDeg: -22,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
          children: [
            // Circular progress card
            FadeTransition(
              opacity: skillFade,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.line),
                  boxShadow: tokens.cardShadow,
                ),
                child: Row(
                  children: [
                    const AnimatedCircleProgress(targetValue: 82),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SQL skill check',
                            style: TextStyle(
                              fontFamily: 'Geologica',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Data Engineer path · Week 3',
                            style: TextStyle(
                              fontFamily: 'Geologica',
                              fontSize: 12.5,
                              color: tokens.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Learning path card
            FadeTransition(
              opacity: pathFade,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.line),
                  boxShadow: tokens.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Learning path',
                          style: TextStyle(
                            fontFamily: 'Geologica',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink,
                          ),
                        ),
                        Text(
                          '6 of 14 topics',
                          style: TextStyle(
                            fontFamily: 'Geologica',
                            fontSize: 12.5,
                            color: tokens.mute,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: tokens.tealSoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.43,
                          child: Container(
                            decoration: BoxDecoration(
                              color: tokens.teal2,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Hexagon badges row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildHexBadge('SQL', const Color(0xFF2F8090), 54, 58),
                _buildHexBadge('PY', const Color(0xFF06334A), 54, 58),
                _buildHexBadge('ETL', const Color(0xFF5B7684), 54, 58),
                // New AWS Badge with pop tag
                ScaleTransition(
                  scale: badgePop,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tokens.tealSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Badge earned',
                          style: TextStyle(
                            fontFamily: 'Geologica',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tokens.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildHexBadge('AWS', const Color(0xFFB5884B), 62, 67),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Mock Interview card
            FadeTransition(
              opacity: mockFade,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.line),
                  boxShadow: tokens.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tokens.ctaBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.play_arrow_rounded, color: tokens.ctaInk, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI mock interview',
                            style: TextStyle(
                              fontFamily: 'Geologica',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                          Text(
                            '15 min · Behavioural questions',
                            style: TextStyle(
                              fontFamily: 'Geologica',
                              fontSize: 12.5,
                              color: tokens.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: tokens.mute),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildHexBadge(String label, Color color, double width, double height) {
    return ClipPath(
      clipper: _HexagonClipper(),
      child: Container(
        width: width,
        height: height,
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// SLIDE 4: Stay Informed
// -------------------------------------------------------------
class _Slide4Informed extends StatelessWidget {
  final AnimationController controller;
  const _Slide4Informed({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);

    final drop3 = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.1, 0.5, curve: WelcomeCurves.easeOutCubic),
    );
    final drop2 = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.25, 0.65, curve: WelcomeCurves.easeOutCubic),
    );
    final drop1 = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.4, 0.8, curve: WelcomeCurves.easeOutCubic),
    );

    return _SlideBackground(
      rotDeg: 6,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discover',
                    style: TextStyle(
                      fontFamily: 'Geologica',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontFamily: 'Geologica',
                      fontSize: 13,
                      color: tokens.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Tilted News Cards Stack
              SizedBox(
                height: 320,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                  // Card 3: Industry (top 0, rot 2.6 deg)
                  Positioned(
                    top: 0,
                    left: 4,
                    right: 4,
                    child: FadeTransition(
                      opacity: drop3,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(drop3),
                        child: Transform.rotate(
                          angle: 2.6 * (math.pi / 180.0),
                          child: Opacity(
                            opacity: 0.72,
                            child: _buildNewsCard(
                              tag: 'Industry',
                              tagBg: tokens.tealSoft,
                              tagFg: tokens.teal,
                              title: 'Fintech hiring picked up again this month',
                              meta: '2 min read',
                              tokens: tokens,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Card 2: AI (top 96, rot -2 deg)
                  Positioned(
                    top: 96,
                    left: 4,
                    right: 4,
                    child: FadeTransition(
                      opacity: drop2,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(drop2),
                        child: Transform.rotate(
                          angle: -2.0 * (math.pi / 180.0),
                          child: Opacity(
                            opacity: 0.88,
                            child: _buildNewsCard(
                              tag: 'AI',
                              tagBg: tokens.tealSoft,
                              tagFg: tokens.teal,
                              title: 'How recruiters now use AI to screen resumes',
                              meta: '3 min read',
                              tokens: tokens,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Card 1: Immigration (top 196, rot 0.5 deg)
                  Positioned(
                    top: 196,
                    left: 4,
                    right: 4,
                    child: FadeTransition(
                      opacity: drop1,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(drop1),
                        child: Transform.rotate(
                          angle: 0.5 * (math.pi / 180.0),
                          child: _buildNewsCard(
                            tag: 'Immigration',
                            tagBg: tokens.ctaBg,
                            tagFg: tokens.ctaInk,
                            title: 'H-1B registration 2027: key dates and what to prepare',
                            meta: '4 min read · Explained simply',
                            hasBookmark: true,
                            tokens: tokens,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNewsCard({
    required String tag,
    required Color tagBg,
    required Color tagFg,
    required String title,
    required String meta,
    bool hasBookmark = false,
    required WelcomeTokens tokens,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.line),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontFamily: 'Geologica',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: tagFg,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Geologica',
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: tokens.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meta,
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 12.5,
                  color: tokens.mute,
                ),
              ),
              if (hasBookmark)
                Icon(Icons.bookmark_border_rounded, size: 18, color: tokens.mute),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Shared slide background with subtle radial glow & watermark
// -------------------------------------------------------------
/// Clearbit logo with letter-tile fallback.
class _CompanyLogoMark extends StatelessWidget {
  final String letter;
  final Color bg;
  final String domain;

  const _CompanyLogoMark({
    required this.letter,
    required this.bg,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 36,
        height: 36,
        color: Colors.white,
        alignment: Alignment.center,
        child: Image.network(
          'https://logo.clearbit.com/$domain',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 36,
              height: 36,
              color: bg,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 36,
              height: 36,
              color: bg,
              alignment: Alignment.center,
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideBackground extends StatelessWidget {
  final double rotDeg;
  final Widget child;

  const _SlideBackground({required this.rotDeg, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = WelcomeTokens.of(context);

    return Stack(
      children: [
        // Radial Glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.65, -0.6),
                radius: 0.72,
                colors: [
                  tokens.glow,
                  tokens.bg.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.72],
              ),
            ),
          ),
        ),
        // Decorative Triangle Watermark
        Positioned(
          top: 36,
          right: -90,
          child: Transform.rotate(
            angle: rotDeg * (math.pi / 180.0),
            child: Opacity(
              opacity: 0.045,
              child: FirstStepTriangle(
                width: 330,
                color: tokens.triColor,
              ),
            ),
          ),
        ),
        // Slide Content
        Positioned.fill(child: child),
      ],
    );
  }
}

// -------------------------------------------------------------
// Live pulsing green dot for Slide 1
// -------------------------------------------------------------
class _PulsingGreenDot extends StatefulWidget {
  @override
  State<_PulsingGreenDot> createState() => _PulsingGreenDotState();
}

class _PulsingGreenDotState extends State<_PulsingGreenDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale = 0.4 + (1.2 * t);
        final opacity = (1.0 - t) * 0.6;

        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3BB273).withValues(alpha: opacity),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3BB273),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// ScoutX Radar pulse icon for Slide 2
// -------------------------------------------------------------
class _ScoutXRadarIcon extends StatefulWidget {
  final WelcomeTokens tokens;
  const _ScoutXRadarIcon({required this.tokens});

  @override
  State<_ScoutXRadarIcon> createState() => _ScoutXRadarIconState();
}

class _ScoutXRadarIconState extends State<_ScoutXRadarIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: widget.tokens.tealSoft,
        shape: BoxShape.circle,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t1 = _controller.value;
          final t2 = (_controller.value + 0.5) % 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              _buildPulseRing(t1),
              _buildPulseRing(t2),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.tokens.teal2,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPulseRing(double t) {
    final scale = 0.5 + (1.1 * t);
    final opacity = (1.0 - t) * 0.6;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.tokens.teal2.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Hexagon clipper for badges
// -------------------------------------------------------------
class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
