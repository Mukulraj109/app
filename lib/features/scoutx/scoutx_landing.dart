import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../api/api_client.dart';
import '../../theme/home_tokens.dart';
import '../home/screens/bell_inbox.dart';
import '../home/screens/news_pages.dart';
import '../welcome/widgets/firststep_logo.dart';
import 'scoutx_data.dart';
import 'scoutx_hero_loop.dart';
import 'scoutx_tokens.dart';

// Callers: ScoutXTab → ScoutXLanding. No new file; extends existing landing.
// User: "add the logo in the page at the top just like how home is having"

/// Full ScoutX marketing landing — mobile layout of ScoutXLandingContent.tsx.
///
/// Callers: ScoutXTab (shell), scoutx_test. Existing landing file — not a new
/// screen. Unread comes from AppState.bellUnread (int); no data-file I/O.
/// User: "fix these speed issue so my user experice is up to the mark..."
class ScoutXLanding extends StatefulWidget {
  final ApiClient? api;
  final int unread;
  final Listenable? unreadListenable;
  final int Function()? unreadOf;

  const ScoutXLanding({
    super.key,
    this.api,
    this.unread = 0,
    this.unreadListenable,
    this.unreadOf,
  });

  @override
  State<ScoutXLanding> createState() => _ScoutXLandingState();
}

class _ScoutXLandingState extends State<ScoutXLanding> {
  final _scroll = ScrollController();
  final _howKey = GlobalKey();
  final _reelsKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _openDashboard() async {
    final uri = Uri.parse(scoutXWebUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open ScoutX on the website.'),
        ),
      );
    }
  }

  void _openReel(int index) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      useSafeArea: !kIsWeb && Platform.isIOS,
      builder: (_) => _ReelPlayerSheet(index: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final half = (scoutXTrackingCompanies.length / 2).ceil();
    final rowA = scoutXTrackingCompanies.sublist(0, half);
    final rowB = scoutXTrackingCompanies.sublist(half);

    return ColoredBox(
      color: ScoutXTokens.paper,
      child: ListView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        children: [
          _HeroSection(
            api: widget.api,
            unread: widget.unread,
            unreadListenable: widget.unreadListenable,
            unreadOf: widget.unreadOf,
            onDashboard: _openDashboard,
            onHow: () => _scrollTo(_howKey),
            onReels: () => _scrollTo(_reelsKey),
          ),
          const _ManifestoBand(),
          _TrackingSection(rowA: rowA, rowB: rowB),
          const _StatsSection(),
          KeyedSubtree(
            key: _reelsKey,
            child: _ReelsSection(onOpen: _openReel),
          ),
          KeyedSubtree(
            key: _howKey,
            child: const _HowItWorksSection(),
          ),
          const _CadenceSection(),
          _ClustersSection(onBrowse: _openDashboard),
          _FinalCta(onDashboard: _openDashboard),
        ],
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final ApiClient? api;
  final int unread;
  final Listenable? unreadListenable;
  final int Function()? unreadOf;
  final VoidCallback onDashboard;
  final VoidCallback onHow;
  final VoidCallback onReels;

  const _HeroSection({
    this.api,
    this.unread = 0,
    this.unreadListenable,
    this.unreadOf,
    required this.onDashboard,
    required this.onHow,
    required this.onReels,
  });

  @override
  Widget build(BuildContext context) {
    // Callers: ScoutXTab → ScoutXLanding → _HeroSection (existing file).
    // User: "add the logo in the page at the top just like how home is having"
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoutTopIcon(
                icon: Icons.article_outlined,
                label: 'News',
                hasDot: false,
                onTap: () => openNewsFeed(context, api: api),
                tokens: t,
              ),
              const Expanded(
                child: Center(
                  child: FirstStepLogo(
                    triangleWidth: 24,
                    wordmarkWidth: 112,
                    spacing: 7,
                  ),
                ),
              ),
              if (unreadListenable != null)
                AnimatedBuilder(
                  animation: unreadListenable!,
                  builder: (context, _) => _ScoutTopIcon(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    hasDot: (unreadOf?.call() ?? unread) > 0,
                    onTap: () => openBellInbox(context, api),
                    tokens: t,
                  ),
                )
              else
              if (unreadListenable != null)
                AnimatedBuilder(
                  animation: unreadListenable!,
                  builder: (context, _) => _ScoutTopIcon(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    hasDot: (unreadOf?.call() ?? unread) > 0,
                    onTap: () => openBellInbox(context, api),
                    tokens: t,
                  ),
                )
              else
                _ScoutTopIcon(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  hasDot: unread > 0,
                  onTap: () => openBellInbox(context, api),
                  tokens: t,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                label: 'ScoutX',
                bg: ScoutXTokens.navy,
                fg: ScoutXTokens.white,
              ),
              _Pill(
                label: 'Beta · Go Live January 1',
                bg: ScoutXTokens.mint,
                fg: ScoutXTokens.teal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _HeroHeadline(),
          const SizedBox(height: 14),
          Text(
            'ScoutX scans 4+ company career pages every minute. New roles hit your feed the moment they go live, not days later on a job board.',
            style: ScoutXTokens.bodyText.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _PrimaryCta(
              label: 'Go to dashboard',
              onPressed: onDashboard,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onHow,
              style: OutlinedButton.styleFrom(
                foregroundColor: ScoutXTokens.ink,
                side: const BorderSide(color: ScoutXTokens.borderStrong),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'See how it works',
                style: TextStyle(
                  fontFamily: ScoutXTokens.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onReels,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Watch the product'),
            style: TextButton.styleFrom(
              foregroundColor: ScoutXTokens.teal,
              textStyle: const TextStyle(
                fontFamily: ScoutXTokens.fontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: ScoutXHeroLoop()),
          const SizedBox(height: 18),
          const Divider(color: ScoutXTokens.border, height: 1),
          const SizedBox(height: 14),
          const ScoutXRolesCounterWidget(),
          const SizedBox(height: 10),
          const _TrustPills(),
        ],
      ),
    );
  }
}

class _ScoutTopIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasDot;
  final VoidCallback onTap;
  final HomeTokens tokens;

  const _ScoutTopIcon({
    required this.icon,
    required this.label,
    this.hasDot = false,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.card,
                shape: BoxShape.circle,
                border: Border.all(color: t.line, width: 1.2),
                boxShadow: t.cardShadow,
              ),
              child: Icon(icon, size: 21, color: t.ink),
            ),
            if (hasDot)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5533D),
                    shape: BoxShape.circle,
                    border: Border.all(color: t.card, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: ScoutXTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _HeroHeadline extends StatefulWidget {
  const _HeroHeadline();

  @override
  State<_HeroHeadline> createState() => _HeroHeadlineState();
}

class _HeroHeadlineState extends State<_HeroHeadline>
    with SingleTickerProviderStateMixin {
  static const _words = [
    'Watched for you.',
    'Scraped live.',
    'Never missed.',
  ];
  int _i = 0;
  late final AnimationController _rotate;

  @override
  void initState() {
    super.initState();
    // AnimationController respects shell TickerMode when the tab is offstage.
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _i = (_i + 1) % _words.length);
        _rotate.forward(from: 0);
      });
    _rotate.forward();
  }

  @override
  void dispose() {
    _rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final word = reduce ? _words.first : _words[_i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Every career page.',
          style: ScoutXTokens.display.copyWith(fontSize: 36),
        ),
        AnimatedSwitcher(
          duration: reduce
              ? Duration.zero
              : const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: Text(
            word,
            key: ValueKey(word),
            style: ScoutXTokens.display.copyWith(
              fontSize: 36,
              color: ScoutXTokens.teal,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryCta({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ScoutXTokens.tealCta,
        foregroundColor: ScoutXTokens.navy,
        elevation: 0,
        shadowColor: ScoutXTokens.teal.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }
}

/// Web parity — `ScoutXRolesCounter` (~132k bounded ticker).
class ScoutXRolesCounterWidget extends StatefulWidget {
  const ScoutXRolesCounterWidget({super.key});

  @override
  State<ScoutXRolesCounterWidget> createState() =>
      _ScoutXRolesCounterWidgetState();
}

class _ScoutXRolesCounterWidgetState extends State<ScoutXRolesCounterWidget>
    with SingleTickerProviderStateMixin {
  static const _min = 120000;
  static const _max = 150000;
  static const _steps = [2, 1, 3, 2, 4, 1, 3, 2, 5, 2, 3, 1];

  int _value = 132480;
  int _stepIx = 0;
  bool _flash = false;
  Timer? _flashReset;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((s) {
        if (s != AnimationStatus.completed || !mounted) return;
        setState(() {
          _value += _steps[_stepIx % _steps.length];
          _stepIx++;
          if (_value > _max) _value = _min + (_value - _max);
          _flash = true;
        });
        _flashReset?.cancel();
        _flashReset = Timer(const Duration(milliseconds: 220), () {
          if (mounted) setState(() => _flash = false);
        });
        _pulse.forward(from: 0);
      });
    _pulse.forward();
  }

  @override
  void dispose() {
    _flashReset?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _fmt(_value),
          style: TextStyle(
            fontFamily: ScoutXTokens.fontFamily,
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: _flash ? ScoutXTokens.teal : ScoutXTokens.ink,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'new roles found this week',
            style: TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 15,
              color: ScoutXTokens.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustPills extends StatelessWidget {
  const _TrustPills();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (var i = 0; i < scoutXTrustPills.length; i++) ...[
          if (i > 0)
            const Text(
              '/',
              style: TextStyle(
                fontFamily: ScoutXTokens.fontFamily,
                fontSize: 12,
                letterSpacing: 1,
                color: ScoutXTokens.teal,
              ),
            ),
          Text(
            scoutXTrustPills[i].toUpperCase(),
            style: const TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 12,
              letterSpacing: 1,
              color: ScoutXTokens.mutedSoft,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Manifesto ───────────────────────────────────────────────────────────────

class _ManifestoBand extends StatefulWidget {
  const _ManifestoBand();

  @override
  State<_ManifestoBand> createState() => _ManifestoBandState();
}

class _ManifestoBandState extends State<_ManifestoBand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Marquee Rows are wider than the viewport; ClipRect only clips paint —
    // OverflowBox removes the max-width constraint so layout does not report
    // RIGHT OVERFLOW. Callers: ScoutXLanding. User: ScoutX overflow fix.
    final items = [...scoutXBandItems, ...scoutXBandItems];
    return ColoredBox(
      color: ScoutXTokens.navy,
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(-_c.value * 480, 0),
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontFamily: ScoutXTokens.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: ScoutXTokens.tealSoft,
                            ),
                          ),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ScoutXTokens.tealCta,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Tracking ────────────────────────────────────────────────────────────────

class _TrackingSection extends StatelessWidget {
  final List<String> rowA;
  final List<String> rowB;

  const _TrackingSection({required this.rowA, required this.rowB});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScoutXTokens.paperAlt,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRACKING NOW', style: ScoutXTokens.monoLabel),
                SizedBox(height: 4),
                Text(
                  'Fortune 500 + StartUps + FAANG + more',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: ScoutXTokens.mutedSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CompanyTicker(names: rowA),
          const SizedBox(height: 10),
          _CompanyTicker(names: rowB, reverse: true),
        ],
      ),
    );
  }
}

class _CompanyTicker extends StatefulWidget {
  final List<String> names;
  final bool reverse;

  const _CompanyTicker({required this.names, this.reverse = false});

  @override
  State<_CompanyTicker> createState() => _CompanyTickerState();
}

class _CompanyTickerState extends State<_CompanyTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.reverse ? 42 : 36),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Same marquee pattern as _ManifestoBand — OverflowBox avoids RIGHT
    // OVERFLOW under ClipRect. Callers: _TrackingSection. User: ScoutX overflow.
    final names = [...widget.names, ...widget.names];
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = widget.reverse ? 1 - _c.value : _c.value;
            return Transform.translate(
              offset: Offset(-t * 520, 0),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final n in names)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          n,
                          style: const TextStyle(
                            fontFamily: ScoutXTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF33505C),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    // Fixed childAspectRatio clipped long labels ("Career pages scanned…")
    // → BOTTOM OVERFLOW. Wrap sizes to content instead.
    // Callers: ScoutXLanding. User: ScoutX overflow fix.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 24.0;
          final colW = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: 28,
            children: [
              for (final s in scoutXStats)
                SizedBox(
                  width: colW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 1, color: ScoutXTokens.ink),
                      const SizedBox(height: 14),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontFamily: ScoutXTokens.fontFamily,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.2,
                          color: s.accent ? ScoutXTokens.teal : ScoutXTokens.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.label,
                        softWrap: true,
                        style: ScoutXTokens.bodyText.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Reels ───────────────────────────────────────────────────────────────────

class _ReelsSection extends StatelessWidget {
  final ValueChanged<int> onOpen;

  const _ReelsSection({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WATCH THE PRODUCT', style: ScoutXTokens.monoLabel),
          const SizedBox(height: 12),
          Text(
            'See ScoutX in four short clips.',
            style: ScoutXTokens.display.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scoutXReels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 4 / 5,
            ),
            itemBuilder: (context, i) {
              final r = scoutXReels[i];
              return _ReelCard(reel: r, onTap: () => onOpen(i));
            },
          ),
        ],
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  final ScoutXReel reel;
  final VoidCallback onTap;

  const _ReelCard({required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A3F52),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              reel.poster,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0A3F52)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x59022330),
                    Colors.transparent,
                    Color(0xE0022330),
                  ],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      reel.tag,
                      style: const TextStyle(
                        fontFamily: ScoutXTokens.fontFamily,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ScoutXTokens.tealCta,
                        boxShadow: [
                          BoxShadow(
                            color: ScoutXTokens.tealCta.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: ScoutXTokens.navy,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    reel.title,
                    style: const TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reel.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFFC5D4DA),
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
}

class _ReelPlayerSheet extends StatefulWidget {
  final int index;

  const _ReelPlayerSheet({required this.index});

  @override
  State<_ReelPlayerSheet> createState() => _ReelPlayerSheetState();
}

class _ReelPlayerSheetState extends State<_ReelPlayerSheet> {
  VideoPlayerController? _controller;
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final reel = scoutXReels[widget.index];
    final c = VideoPlayerController.networkUrl(Uri.parse(reel.src));
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _ready = true);
      await c.setLooping(true);
      if (!mounted) return;
      await c.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Playback failed. Showing poster instead.');
    }
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = scoutXReels[widget.index];
    final h = MediaQuery.sizeOf(context).height * 0.78;
    return SafeArea(
      child: SizedBox(
        height: h,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reel.title,
                      style: const TextStyle(
                        fontFamily: ScoutXTokens.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        reel.poster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF0A3F52)),
                      ),
                      if (_ready && _controller != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      if (!_ready && _error == null)
                        const Center(
                          child: CircularProgressIndicator(
                            color: ScoutXTokens.tealCta,
                          ),
                        ),
                      if (_error != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            color: Colors.black54,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: ScoutXTokens.fontFamily,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── How it works (parity with ScoutXHowItWorks.tsx) ────────────────────────

class _HowItWorksSection extends StatefulWidget {
  const _HowItWorksSection();

  @override
  State<_HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<_HowItWorksSection>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  bool _auto = true;
  late final AnimationController _autoStep;

  @override
  void initState() {
    super.initState();
    _autoStep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted || !_auto) return;
        setState(() => _step = (_step + 1) % scoutXHowSteps.length);
        _autoStep.forward(from: 0);
      });
    _autoStep.forward();
  }

  @override
  void dispose() {
    _autoStep.dispose();
    super.dispose();
  }

  void _pick(int i) {
    setState(() {
      _step = i;
      _auto = false;
    });
    _autoStep.stop();
  }

  @override
  Widget build(BuildContext context) {
    final s = scoutXHowSteps[_step];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOW IT WORKS', style: ScoutXTokens.monoLabel),
          const SizedBox(height: 14),
          Text(
            'Three steps. Then the feed runs itself.',
            style: ScoutXTokens.display.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < scoutXHowSteps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _HowStepTab(
              step: scoutXHowSteps[i],
              selected: i == _step,
              onTap: () => _pick(i),
            ),
          ],
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Container(
              key: ValueKey(_step),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ScoutXTokens.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ScoutXTokens.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HowItWorksPreview(step: _step),
                  const SizedBox(height: 28),
                  Text(
                    'STEP ${s.n} / 03',
                    style: const TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 12,
                      letterSpacing: 1,
                      color: ScoutXTokens.mutedSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1.1,
                      color: ScoutXTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.body,
                    style: ScoutXTokens.bodyText.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 18),
                  for (final p in s.points) ...[
                    _HowDiamondBullet(text: p),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStepTab extends StatelessWidget {
  final ScoutXHowStep step;
  final bool selected;
  final VoidCallback onTap;

  const _HowStepTab({
    required this.step,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? ScoutXTokens.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ScoutXTokens.teal : const Color(0xFFDDE5E8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? ScoutXTokens.teal : ScoutXTokens.paperAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  step.n,
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? ScoutXTokens.white : ScoutXTokens.muted,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: ScoutXTokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowDiamondBullet extends StatelessWidget {
  final String text;
  const _HowDiamondBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: ScoutXTokens.teal),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 15,
              height: 1.35,
              color: ScoutXTokens.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _HowItWorksPreview extends StatelessWidget {
  final int step;
  const _HowItWorksPreview({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ScoutXTokens.paper,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: switch (step) {
          0 => _previewStep0(),
          1 => _previewStep1(),
          _ => _previewStep2(),
        },
      ),
    );
  }

  List<Widget> _previewStep0() {
    const rows = [
      (name: 'FAANG Software Engineering', cos: '12 cos', on: true),
      (name: 'NYC Strategy Consulting', cos: '148 cos', on: false),
      (name: 'Healthcare Texas', cos: '76 cos', on: false),
    ];
  return [
      for (final row in rows) ...[
        _clusterRow(
          name: row.name,
          cos: row.cos,
          selected: row.on,
        ),
        const SizedBox(height: 10),
      ],
      _dashedAddRow(),
    ];
  }

  List<Widget> _previewStep1() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ScoutXTokens.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ScoutXTokens.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CURATED · FAANG SWE',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 11,
                    letterSpacing: 1,
                    color: ScoutXTokens.muted,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: ScoutXTokens.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ScoutXTokens.teal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontFamily: ScoutXTokens.fontFamily,
                          fontSize: 11,
                          letterSpacing: 1,
                          color: ScoutXTokens.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Scraped every minute, streaming nonstop',
              style: TextStyle(
                fontFamily: ScoutXTokens.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: ScoutXTokens.ink,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ScoutXTokens.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ScoutXTokens.teal, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F4FB3A9),
              blurRadius: 0,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CUSTOM · MY 50 COMPANIES',
              style: TextStyle(
                fontFamily: ScoutXTokens.fontFamily,
                fontSize: 11,
                letterSpacing: 1,
                color: ScoutXTokens.muted,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ScoutXTokens.paper,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  for (final w in ['1h', '6h', '12h', '24h'])
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: w == '6h' ? ScoutXTokens.teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          w,
                          style: TextStyle(
                            fontFamily: ScoutXTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: w == '6h' ? FontWeight.w600 : FontWeight.w500,
                            color: w == '6h' ? ScoutXTokens.white : ScoutXTokens.muted,
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
    ];
  }

  List<Widget> _previewStep2() {
    const fav =
        'https://www.google.com/s2/favicons?domain=stripe.com&sz=128';
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ScoutXTokens.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ScoutXTokens.teal, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F4FB3A9),
              blurRadius: 0,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(fav, width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend Engineer, Payments',
                    style: TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ScoutXTokens.ink,
                    ),
                  ),
                  Text(
                    'Stripe · San Francisco',
                    style: TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 13,
                      color: ScoutXTokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ScoutXTokens.mint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'NEW · 2m',
                style: TextStyle(
                  fontFamily: ScoutXTokens.fontFamily,
                  fontSize: 11,
                  color: ScoutXTokens.teal,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ScoutXTokens.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ScoutXTokens.borderStrong),
              ),
              child: const Text(
                'Apply myself ↗',
                style: TextStyle(
                  fontFamily: ScoutXTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ScoutXTokens.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ScoutXTokens.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Assign to FirstStep',
                style: TextStyle(
                  fontFamily: ScoutXTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ScoutXTokens.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _clusterRow({
    required String name,
    required String cos,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ScoutXTokens.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? ScoutXTokens.teal : ScoutXTokens.borderSoft,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x1F4FB3A9),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? ScoutXTokens.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: selected
                  ? null
                  : Border.all(color: ScoutXTokens.borderStrong, width: 1.5),
            ),
            child: selected
                ? const Text(
                    '✓',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: ScoutXTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ScoutXTokens.ink,
              ),
            ),
          ),
          Text(
            cos,
            style: const TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 12,
              color: ScoutXTokens.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedAddRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9FCFC7), width: 1.5),
      ),
      child: const Row(
        children: [
          Text(
            '+',
            style: TextStyle(
              fontSize: 18,
              height: 1,
              color: ScoutXTokens.teal,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Build a custom cluster',
              style: TextStyle(
                fontFamily: ScoutXTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ScoutXTokens.teal,
              ),
            ),
          ),
          Text(
            'up to 50',
            style: TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 12,
              color: ScoutXTokens.teal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cadence ─────────────────────────────────────────────────────────────────

class _CadenceSection extends StatelessWidget {
  const _CadenceSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SCRAPE CADENCE', style: ScoutXTokens.monoLabel),
          const SizedBox(height: 12),
          Text(
            'Two cadences. One feed.',
            style: ScoutXTokens.display.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 10),
          Text(
            'Curated clusters never stop. Custom clusters run on the window you set.',
            style: ScoutXTokens.bodyText.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ScoutXTokens.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURATED CLUSTERS',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: ScoutXTokens.tealSoft,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Every minute',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.4,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Ops maintains the company set. Every employer in the cluster is scraped on every run — no staggered rotation.',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFFA9BCC4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ScoutXTokens.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ScoutXTokens.borderSoft),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOM CLUSTERS',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: ScoutXTokens.teal,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '1h – 24h',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.4,
                    color: ScoutXTokens.ink,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Pick up to 50 companies and a window from 1h to 24h. We hit only your companies, only on your schedule.',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 14,
                    height: 1.55,
                    color: ScoutXTokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clusters ────────────────────────────────────────────────────────────────

class _ClustersSection extends StatelessWidget {
  final VoidCallback onBrowse;

  const _ClustersSection({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURATED SETS', style: ScoutXTokens.monoLabel),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Sample clusters',
                  style: ScoutXTokens.display.copyWith(fontSize: 28),
                ),
              ),
              TextButton(
                onPressed: onBrowse,
                child: const Text(
                  'Browse in dashboard →',
                  style: TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontWeight: FontWeight.w500,
                    color: ScoutXTokens.ink,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final c in scoutXClusters) ...[
            _ClusterCard(cluster: c),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  final ScoutXCluster cluster;

  const _ClusterCard({required this.cluster});

  @override
  Widget build(BuildContext context) {
    final icons = cluster.faviconUrls;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ScoutXTokens.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScoutXTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cluster.name,
            style: const TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: ScoutXTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cluster.sub,
            style: const TextStyle(
              fontFamily: ScoutXTokens.fontFamily,
              fontSize: 13,
              color: ScoutXTokens.muted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 36,
                width: 36.0 + (icons.length - 1) * 28,
                child: Stack(
                  children: [
                    for (var i = 0; i < icons.length; i++)
                      Positioned(
                        left: i * 28.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ScoutXTokens.white,
                            border: Border.all(
                              color: ScoutXTokens.borderSoft,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(7),
                          child: Image.network(
                            icons[i],
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              size: 14,
                              color: ScoutXTokens.mutedSoft,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                cluster.more,
                style: const TextStyle(
                  fontFamily: ScoutXTokens.fontFamily,
                  fontSize: 13,
                  color: ScoutXTokens.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDF2F3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${cluster.roles}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ScoutXTokens.ink,
                      ),
                    ),
                    const TextSpan(text: ' open roles'),
                  ],
                  style: const TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 13,
                    color: ScoutXTokens.muted,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${cluster.cos}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ScoutXTokens.ink,
                      ),
                    ),
                    const TextSpan(text: ' companies'),
                  ],
                  style: const TextStyle(
                    fontFamily: ScoutXTokens.fontFamily,
                    fontSize: 13,
                    color: ScoutXTokens.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Final CTA ───────────────────────────────────────────────────────────────

class _FinalCta extends StatelessWidget {
  final VoidCallback onDashboard;

  const _FinalCta({required this.onDashboard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
        decoration: BoxDecoration(
          color: ScoutXTokens.navy,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x247DD3D8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Beta · Go Live January 1',
                    style: TextStyle(
                      fontFamily: ScoutXTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ScoutXTokens.tealSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Every career page. '),
                      TextSpan(
                        text: 'Watched for you.',
                        style: TextStyle(color: ScoutXTokens.tealSoft),
                      ),
                    ],
                    style: ScoutXTokens.display.copyWith(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScoutXTokens.teal,
                      foregroundColor: ScoutXTokens.navy,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to dashboard →',
                      style: TextStyle(
                        fontFamily: ScoutXTokens.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    const step = 26.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
