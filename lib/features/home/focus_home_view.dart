import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_client.dart';
import '../../shared_widgets/app_nav.dart';
import '../../shared_widgets/liquid_wash.dart';
import '../../shared_widgets/spring_entrance.dart';
import '../../state/app_state.dart';
import '../../theme/home_tokens.dart';
import '../learn/screens/learn_screens.dart';
import '../learn/screens/pitch_page.dart';
import 'screens/bell_inbox.dart';
import '../welcome/widgets/firststep_logo.dart';
import 'home_refresh.dart';
import 'home_store.dart';
import 'screens/news_pages.dart';
import 'widgets/hero_arc.dart';

part 'widgets/home_top.dart';
part 'widgets/home_cards.dart';
part 'widgets/home_more.dart';
/// Home tab, rebuilt from 02-homev2.html. Reads every block from [HomeStore]
/// so it can be HTML-matched across all 8 states without touching the real
/// user/tracker seed.
///
/// ponytail: blocks are private widgets in this one file rather than the
/// plan's per-block files — add them out only if a block outgrows ~60 lines.
class FocusHomeView extends StatefulWidget {
  final HomeStore homeStore;
  final AppState? appState;
  final Future<void> Function()? onRefresh;
  final ApiClient? api;

  const FocusHomeView({
    super.key,
    required this.homeStore,
    this.appState,
    this.onRefresh,
    this.api,
  });

  @override
  State<FocusHomeView> createState() => _FocusHomeViewState();
}

class _FocusHomeViewState extends State<FocusHomeView> {
  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return RefreshIndicator(
      color: t.teal,
      onRefresh: () async {
        final refresh = widget.onRefresh;
        if (refresh != null) {
          await refresh();
          return;
        }
        await Future.delayed(const Duration(milliseconds: 450));
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 128),
        children: [
          AnimatedBuilder(
            animation: widget.homeStore,
            builder: (context, _) {
              final c = widget.homeStore.content;
              final failed = widget.homeStore.loadFailed && widget.api != null;
              final waiting = widget.homeStore.awaitingLive && widget.api != null;
              if (waiting || failed) {
                return Column(
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: waiting
                          ? const CircularProgressIndicator()
                          : Text('Could not load Home.', style: TextStyle(color: t.ink)),
                    ),
                    if (!waiting)
                      Center(
                        child: TextButton(
                          onPressed: widget.onRefresh,
                          child: const Text('Retry'),
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  SpringEntrance(
                    index: 0,
                    child: LiquidWash(
                      intensity: 1.2,
                      child: _TopBar(
                        content: c,
                        tokens: t,
                        store: widget.homeStore,
                        api: widget.api,
                        unread: widget.appState?.bellUnread ?? 0,
                        signedIn: widget.api != null,
                      ),
                    ),
                  ),
                  if (c.hero != null) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth.clamp(0.0, 340.0);
                          return Center(child: HeroArc(spec: c.hero!, size: w));
                        },
                      ),
                    ),
                  ],
                  if (c.quietTotal > 0 || c.quietHours > 0) ...[
                    const SizedBox(height: 10),
                    SpringEntrance(
                      index: 2,
                      child: _QuietLine(total: c.quietTotal, hours: c.quietHours),
                    ),
                  ],
                  if (c.showBusy) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 3,
                      child: _BusyCard(text: c.busyText),
                    ),
                  ],
                  if (c.banner != null) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 3,
                      child: _StateBanner(
                        banner: c.banner!,
                        appState: widget.appState,
                      ),
                    ),
                  ],
                  if (c.upNextFirst != null || c.upNextRest.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SpringEntrance(
                      index: 4,
                      child: _UpNext(
                        title: c.upNextTitle,
                        first: c.upNextFirst,
                        rest: c.upNextRest,
                        appState: widget.appState,
                      ),
                    ),
                  ],
                  if (c.showFeedback) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 5,
                      child: _FeedbackCard(
                        onOpenReview: () =>
                            widget.appState?.requestApplicationsReview(),
                      ),
                    ),
                  ],
                  if (c.partner != null) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 6,
                      child: _ApplicationPartner(
                        partner: c.partner!,
                        appState: widget.appState,
                      ),
                    ),
                  ],
                  if (widget.api != null && widget.homeStore.actions.hasAny) ...[
                    const SizedBox(height: 18),
                    SpringEntrance(
                      index: 7,
                      child: _HomeWriteBacks(
                        api: widget.api!,
                        store: widget.homeStore,
                      ),
                    ),
                  ],
                  if (c.showDiscover) ...[
                    const SizedBox(height: 18),
                    SpringEntrance(
                      index: 8,
                      child: _DiscoverCards(
                        api: widget.api,
                        cards: widget.api != null
                            ? c.news
                            : (c.liveNews ? c.news : sampleNews),
                      ),
                    ),
                  ],
                  // Proof stats strip removed (Applications / This week /
                  // Coming up / Hours saved). Callers: FocusHomeView via
                  // focus_shell.dart ~227; part widgets in home_more.dart.
                  // No data-file I/O. User: "can u remove this red circle section we need to remove it"
                  if (c.sell != null) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 10,
                      child: _SellCard(
                        sell: c.sell!,
                        appState: widget.appState,
                      ),
                    ),
                  ],
                  if (c.newJobs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 11,
                      child: _NewJobs(
                        jobs: c.newJobs,
                        appState: widget.appState,
                      ),
                    ),
                  ],
                  if (c.showRefer) ...[
                    const SizedBox(height: 14),
                    SpringEntrance(
                      index: 12,
                      child: _ReferRow(),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Milestone / nudge / interview follow-up — themed to [HomeTokens], never
/// Material default pink/purple.
class _HomeWriteBacks extends StatefulWidget {
  const _HomeWriteBacks({required this.api, required this.store});
  final ApiClient api;
  final HomeStore store;

  @override
  State<_HomeWriteBacks> createState() => _HomeWriteBacksState();
}

class _HomeWriteBacksState extends State<_HomeWriteBacks> {
  String _rating = 'Great';
  String _nextRound = 'Waiting';
  bool _busy = false;

  Future<void> _run(Future<void> Function() call, VoidCallback onDone) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await call();
      if (!mounted) return;
      onDone();
    } catch (_) {
      if (!mounted) return;
      final t = HomeTokens.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save. Try again.'),
          backgroundColor: t.alert,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final actions = widget.store.actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actions.milestoneId.isNotEmpty) ...[
          _ActionCard(
            eyebrow: 'Milestone',
            title: actions.milestoneTitle.isEmpty
                ? 'You hit a milestone'
                : actions.milestoneTitle,
            child: _ActionCta(
              label: 'Got it',
              busy: _busy,
              onPressed: () => _run(
                () => widget.api.markMilestoneSeen(actions.milestoneId),
                () => widget.store.updateActions(
                  actions.copyWith(milestoneId: '', milestoneTitle: ''),
                ),
              ),
            ),
          ),
          if (actions.nudgeId.isNotEmpty || actions.followupId.isNotEmpty)
            const SizedBox(height: 12),
        ],
        if (actions.nudgeId.isNotEmpty) ...[
          _ActionCard(
            eyebrow: 'Quick check',
            title: actions.nudgeTitle.isEmpty
                ? 'How was that?'
                : actions.nudgeTitle,
            child: Row(
              children: [
                Expanded(
                  child: _ActionCta(
                    label: 'Good',
                    busy: _busy,
                    onPressed: () => _run(
                      () => widget.api.sendHomeFeedback(
                        id: actions.nudgeId,
                        rating: 'up',
                      ),
                      () => widget.store.updateActions(
                        actions.copyWith(nudgeId: '', nudgeTitle: ''),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionCta(
                    label: 'Not good',
                    busy: _busy,
                    outlined: true,
                    onPressed: () => _run(
                      () => widget.api.sendHomeFeedback(
                        id: actions.nudgeId,
                        rating: 'down',
                      ),
                      () => widget.store.updateActions(
                        actions.copyWith(nudgeId: '', nudgeTitle: ''),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actions.followupId.isNotEmpty) const SizedBox(height: 12),
        ],
        if (actions.followupId.isNotEmpty)
          _ActionCard(
            eyebrow: 'Interview follow-up',
            title: actions.followupTitle.isEmpty
                ? 'How did it go?'
                : actions.followupTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How did it go?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: t.mute,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rating in followupRatings)
                      _SelectPill(
                        label: rating,
                        selected: _rating == rating,
                        onTap: () => setState(() => _rating = rating),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Next round?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: t.mute,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final round in followupRounds)
                      _SelectPill(
                        label: round,
                        selected: _nextRound == round,
                        onTap: () => setState(() => _nextRound = round),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _ActionCta(
                  label: 'Submit',
                  busy: _busy,
                  onPressed: () => _run(
                    () => widget.api.answerTaskFollowup(
                      actions.followupId,
                      followupAnswer(
                        rating: _rating,
                        nextRound: _nextRound,
                      ),
                    ),
                    () => widget.store.updateActions(
                      actions.copyWith(followupId: '', followupTitle: ''),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;

  const _ActionCard({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: t.teal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SelectPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final bg = selected ? t.navy : t.card;
    final fg = selected ? t.ctaInk : t.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? t.navy : t.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCta extends StatelessWidget {
  final String label;
  final bool busy;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionCta({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final bg = outlined ? Colors.transparent : t.ctaBg;
    final fg = outlined ? t.ink : t.ctaInk;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: busy ? null : onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: outlined ? Border.all(color: t.ink, width: 1.5) : null,
          ),
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}


