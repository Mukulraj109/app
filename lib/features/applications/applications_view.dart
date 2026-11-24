import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared_widgets/app_nav.dart';
import '../../shared_widgets/liquid_wash.dart';
import '../../shared_widgets/spring_entrance.dart';
import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../state/app_state.dart';
import '../../theme/home_tokens.dart';
import '../welcome/widgets/firststep_logo.dart';
import '../home/screens/news_pages.dart';
import '../profile/profile_store.dart';
import '../profile/screens/help_pages.dart';
import '../profile/screens/profile_screens.dart';
import '../home/screens/bell_inbox.dart';
import 'applications_store.dart';
import 'screens/apps_extra_pages.dart';
import 'screens/applications_screens.dart';

part 'widgets/applications_chrome.dart';
part 'widgets/applications_cards.dart';
part 'widgets/applications_banners.dart';
part 'widgets/applications_job_sheet.dart';

ButtonStyle _navyButton(HomeTokens t) {
  return FilledButton.styleFrom(
    backgroundColor: t.ctaBg,
    foregroundColor: t.ctaInk,
    disabledBackgroundColor: t.ctaBg.withValues(alpha: 0.4),
    disabledForegroundColor: t.ctaInk,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

class _LogApplicationSheet extends StatefulWidget {
  final Future<AppJob?> Function({
    required String company,
    required String role,
    required String appliedOn,
    String jobUrl,
  }) onSave;

  const _LogApplicationSheet({required this.onSave});

  @override
  State<_LogApplicationSheet> createState() => _LogApplicationSheetState();
}

class _LogApplicationSheetState extends State<_LogApplicationSheet> {
  final _company = TextEditingController();
  final _role = TextEditingController();
  final _jobUrl = TextEditingController();
  DateTime _day = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    _jobUrl.dispose();
    super.dispose();
  }

  String get _label =>
      '${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}';

  InputDecoration _field(HomeTokens t, String label) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: t.line),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: t.mute),
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: t.navy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log application',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _company, decoration: _field(t, 'Company')),
          const SizedBox(height: 8),
          TextField(controller: _role, decoration: _field(t, 'Role')),
          const SizedBox(height: 8),
          TextField(
            controller: _jobUrl,
            decoration: _field(t, 'Job URL (optional)'),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: t.ink,
              side: BorderSide(color: t.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final now = DateTime.now();
              final first = DateTime(now.year, now.month - 5, 1);
              final last = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
              final initial = _day.isBefore(first) ? first : (_day.isAfter(last) ? last : _day);
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: t.navy,
                        onPrimary: t.ctaInk,
                        surface: t.card,
                        onSurface: t.ink,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _day = picked);
            },
            child: Text(_label),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: t.mute)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            style: _navyButton(t),
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    try {
                      await widget.onSave(
                        company: _company.text.trim(),
                        role: _role.text.trim(),
                        appliedOn: _label,
                        jobUrl: _jobUrl.text.trim(),
                      );
                      if (mounted) Navigator.of(context).pop();
                    } catch (err) {
                      if (!mounted) return;
                      setState(() {
                        _saving = false;
                        _error = err is ApiException
                            ? err.message
                            : 'Could not log this application.';
                      });
                    }
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ApplicationsTab extends StatefulWidget {
  final AppState? appState;
  final ApiClient? api;
  final AuthController? auth;

  const ApplicationsTab({super.key, this.appState, this.api, this.auth});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab>
    with SingleTickerProviderStateMixin {
  late final ApplicationsStore _store;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _monthKey = GlobalKey();
  final GlobalKey _daySummaryKey = GlobalKey();
  final GlobalKey _pickerEndKey = GlobalKey();
  final GlobalKey _listStackKey = GlobalKey();
  final GlobalKey _tabStackKey = GlobalKey();

  AppJob? _openJob;
  double _sheetTop = 0;
  bool _sheetVisible = false;

  /// Match 04-applications.html `.wash.scrolled` — shadow once list moves.
  bool _headerScrolled = false;

  /// Match `.wash.showsel` — slim date bar after day picker scrolls away.
  bool _showSelectionLine = false;
  late final AnimationController _tabPill;

  @override
  void initState() {
    super.initState();
    _store = ApplicationsStore(api: widget.api);
    _tabPill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scroll.addListener(_syncStuck);
    widget.appState?.addListener(_onAppState);
  }

  @override
  void dispose() {
    if (_sheetVisible) {
      widget.appState?.setBottomNavHidden(false);
    }
    widget.appState?.removeListener(_onAppState);
    _scroll.removeListener(_syncStuck);
    _store.dispose();
    _scroll.dispose();
    _tabPill.dispose();
    super.dispose();
  }

  /// Port of `syncStuck` from 04-applications.html + sticky selline rules:
  /// - Slim bar stays in the fixed header (never scrolls with the list).
  /// - Show it only while the November haptic day-picker is off-screen.
  /// - Keep it until that day-picker intersects the list viewport again.
  /// - If the picker was recycled far off-screen, treat it as hidden (keep bar).
  void _syncStuck() {
    final scrolled = _scroll.hasClients && _scroll.offset > 4;
    var showSel = false;
    if (_store.pane == AppsPane.applied && _scroll.hasClients) {
      try {
        final pickerBox =
            _pickerEndKey.currentContext?.findRenderObject() as RenderBox?;
        final listBox =
            _listStackKey.currentContext?.findRenderObject() as RenderBox?;
        if (listBox == null || !listBox.attached || !listBox.hasSize) {
          showSel = _showSelectionLine;
        } else if (pickerBox == null ||
            !pickerBox.attached ||
            !pickerBox.hasSize) {
          // ListView dropped the picker off its cache — still not visible.
          showSel = scrolled || _showSelectionLine;
        } else {
          final pickerTop = pickerBox.localToGlobal(Offset.zero).dy;
          final pickerBottom = pickerTop + pickerBox.size.height;
          final listTop = listBox.localToGlobal(Offset.zero).dy;
          final listBottom = listTop + listBox.size.height;
          final pickerVisible =
              pickerBottom > listTop + 1 && pickerTop < listBottom - 1;
          showSel = !pickerVisible;
        }
      } catch (_) {
        showSel = _showSelectionLine;
      }
    }
    if (scrolled == _headerScrolled && showSel == _showSelectionLine) return;
    setState(() {
      _headerScrolled = scrolled;
      _showSelectionLine = showSel;
    });
  }

  void _scrollToDayPicker() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onAppState() {
    final app = widget.appState;
    if (app == null) return;
    if (app.mainTabIndex != 1 && (_sheetVisible || _openJob != null)) {
      _closeJob();
    }
    if (app.openApplicationsReview) {
      app.clearApplicationsReviewRequest();
      _store.openReview();
    }
  }

  void _openStatePicker() {
    final t = HomeTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheet).height * 0.7,
            child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Preview Applications state',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              for (final s in AppsScreenState.values)
                ListTile(
                  title: Text(
                    _stateLabel(s),
                    style: TextStyle(color: t.ink, fontWeight: FontWeight.w500),
                  ),
                  trailing: _store.state == s
                      ? Icon(Icons.check_rounded, color: t.teal)
                      : null,
                  onTap: () {
                    _closeJob();
                    _store.setState(s);
                    Navigator.pop(sheet);
                  },
                ),
            ],
            ),
          ),
        );
      },
    );
  }

  String _stateLabel(AppsScreenState s) {
    switch (s) {
      case AppsScreenState.activePremium:
        return 'Active · Premium (resumes)';
      case AppsScreenState.activeElite:
        return 'Active · Elite (no resumes)';
      case AppsScreenState.paymentDue:
        return 'Payment due';
      case AppsScreenState.paused:
        return 'Paused';
      case AppsScreenState.expired:
        return 'Expired / Got a job';
      case AppsScreenState.locked:
        return 'Downgraded (locked)';
      case AppsScreenState.startingSoon:
        return 'Starting soon';
      case AppsScreenState.basic:
        return 'Basic (free)';
    }
  }

  Future<void> _openJobSheet(AppJob job) async {
    final c = _store.content;
    if (c.locked || c.basicSample) return;

    if (_showSelectionLine) {
      setState(() => _showSelectionLine = false);
    }

    final monthCtx = _monthKey.currentContext;
    if (monthCtx != null) {
      await Scrollable.ensureVisible(
        monthCtx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    // Full-tab overlay: sheet starts at ~20% so content is ~80%,
    // and the scrim covers header + list (no grey corner ears).
    final tabBox =
        _tabStackKey.currentContext?.findRenderObject() as RenderBox?;
    final tabH = (tabBox != null && tabBox.hasSize)
        ? tabBox.size.height
        : MediaQuery.sizeOf(context).height;
    final top = (tabH * 0.20).clamp(0.0, tabH * 0.28);

    setState(() {
      _openJob = job;
      _sheetTop = top;
      _sheetVisible = true;
    });
    widget.appState?.setBottomNavHidden(true);
    if (_store.live) unawaited(_store.loadJobDetail(job));
  }

  void _closeJob() {
    if (!_sheetVisible && _openJob == null) return;
    setState(() {
      _sheetVisible = false;
      _openJob = null;
    });
    widget.appState?.setBottomNavHidden(false);
  }

  Future<void> _onThumbDown(AppJob job) async {
    HapticFeedback.mediumImpact();
    final reason = await openReasonSheet(
      context,
      resume: _store.content.showResumes,
    );
    if (reason == null) return;
    final ok = await _store.rateDown(job, reason: reason);
    if (!mounted) return;
    showAppsToast(
      context,
      ok ? 'Thanks. Your AIC can see this now.' : 'Could not save your rating.',
    );
  }

  Future<void> _onThumbUp(AppJob job) async {
    HapticFeedback.mediumImpact();
    final ok = await _store.rateUp(job);
    if (!mounted || ok) return;
    showAppsToast(context, 'Could not save your rating.');
  }

  Future<void> _onBookmark(AppJob job) async {
    HapticFeedback.mediumImpact();
    final willSave = !job.bookmarked;
    final ok = await _store.toggleBookmark(job);
    if (!mounted) return;
    showAppsToast(
      context,
      ok
          ? (willSave
              ? 'Saved. Find it under the Saved tab.'
              : 'Removed from Saved.')
          : 'Could not update saved jobs.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);

    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final c = _store.content;

        if (_store.reviewOpen) {
          return ReviewModeOverlay(
            store: _store,
            onClose: () => _store.closeReview(),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final stickyWash = _showSelectionLine &&
            _store.pane == AppsPane.applied &&
            !c.locked &&
            !c.startingSoon;

        return Stack(
          key: _tabStackKey,
          children: [
            Column(
              children: [
                SpringEntrance(
                  index: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    decoration: appsStickyHeaderWash(
                      t,
                      isDark: isDark,
                      active: stickyWash || _headerScrolled,
                    ).copyWith(
                      border: _headerScrolled
                          ? Border(
                              bottom: BorderSide(color: t.line),
                            )
                          : null,
                      boxShadow: _headerScrolled
                          ? [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.5)
                                    : const Color(0x1414232B),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: LiquidWash(
                      intensity: 1.2,
                      child: Column(
                        children: [
                          _TopRow(
                            basicSample: c.basicSample,
                            showCounts: !c.locked && !c.startingSoon,
                            firstStepTotal:
                                _store.live ? _store.firstStepTotal : null,
                            byYouCount: _store.live ? _store.byYouCount : null,
                            onPreview: _openStatePicker,
                            onNotifications: () => openBellInbox(context, widget.api),
                            onNews: () => openNewsFeed(
                              context,
                              api: widget.api,
                            ),
                            unread: widget.appState?.bellUnread ?? 0,
                            onAnalytics: () {},
                          ),
                          if (_store.live || (!c.locked && !c.startingSoon))
                            _SourceToggle(
                              source: _store.jobSource,
                              onSelect: (s) {
                                _closeJob();
                                _store.setJobSource(s);
                              },
                            ),
                          _SegTabs(
                            counts: c.counts,
                            pane: _store.pane,
                            locked: c.locked || c.basicSample || c.startingSoon,
                            onSelect: (p) {
                              _closeJob();
                              if (_showSelectionLine || _headerScrolled) {
                                setState(() {
                                  _showSelectionLine = false;
                                  _headerScrolled = false;
                                });
                              }
                              _store.setPane(p);
                              _tabPill.forward(from: 0);
                            },
                          ),
                          // HTML `.selline` — slim date bar under tabs when scrolled.
                          _SelectionLine(
                            visible: _showSelectionLine &&
                                _store.pane == AppsPane.applied &&
                                !c.locked &&
                                !c.startingSoon,
                            label: c.daySummaryLabel,
                            count: c.dayCount,
                            onChange: _scrollToDayPicker,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    key: _listStackKey,
                    children: [
                      _store.live
                          ? _liveScroll(c, t)
                          : ListView(
                              controller: _scroll,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: const EdgeInsets.only(bottom: 128),
                              children: [
                                if (_store.pane == AppsPane.applied)
                                  ..._appliedBody(c, t)
                                else if (_store.pane == AppsPane.saved)
                                  ..._savedBody(c, t)
                                else
                                  ..._responsesBody(t),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
            if (_sheetVisible && _openJob != null)
              _JobSheetLayer(
                top: _sheetTop,
                job: _openJob!,
                content: c,
                onClose: _closeJob,
                onBookmark: () => _onBookmark(_openJob!),
                onThumbUp: () => _onThumbUp(_openJob!),
                onThumbDown: () => _onThumbDown(_openJob!),
                onOpenResume: () =>
                    openResumeViewer(context, _openJob!, store: _store),
                store: _store,
                onPosting: () {
                  final url = _openJob!.jobUrl;
                  if (url.isEmpty) {
                    showAppsToast(context, 'No job posting link yet.');
                    return;
                  }
                  openExternal(url);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _liveScroll(AppsContent c, HomeTokens t) {
    return RefreshIndicator(
      onRefresh: _store.refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: _liveSlivers(c, t),
      ),
    );
  }

  List<Widget> _liveSlivers(AppsContent c, HomeTokens t) {
    if (!_store.booted) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (_store.pane == AppsPane.saved) return _pagedSlivers(c, t, saved: true);
    if (_store.pane == AppsPane.responses) {
      return [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 128),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Responses',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: t.ink)),
                        Text('Recruiter replies your AIC tagged',
                            style: TextStyle(fontSize: 13, color: t.mute)),
                        if (_store.responsesError != null) ...[
                          const SizedBox(height: 12),
                          Text(_store.responsesError!,
                              style: TextStyle(color: t.mute)),
                          TextButton(
                            onPressed: () => _store.loadResponses(reset: true),
                            child: const Text('Try again'),
                          ),
                        ] else if (_store.booted &&
                            _store.responses.isEmpty) ...[
                          const SizedBox(height: 24),
                          Text('No responses yet.',
                              style: TextStyle(color: t.mute)),
                        ],
                      ],
                    ),
                  );
                }
                final row = index - 1;
                if (row >= _store.responses.length) {
                  if (!_store.responsesHasMore)
                    return const SizedBox(height: 24);
                  return _loadMoreButton(t);
                }
                final response = _store.responses[row];
                return _ResponseCard(
                  response: response,
                  onTap: () => openResponseImage(context, response),
                );
              },
              childCount: _store.responses.length + 2,
            ),
          ),
        ),
      ];
    }
    if (c.locked ||
        c.basicSample ||
        c.startingSoon ||
        _store.jobSource == AppsJobSource.byYou) {
      return [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 128),
          sliver:
              SliverList(delegate: SliverChildListDelegate(_appliedBody(c, t))),
        ),
      ];
    }
    return _pagedSlivers(c, t, saved: false);
  }

  List<Widget> _pagedSlivers(AppsContent c, HomeTokens t,
      {required bool saved}) {
    final jobs = saved ? _store.saved : _store.visibleJobs;
    final hasMore = saved ? _store.savedHasMore : _store.jobsHasMore;
    final waiting = _store.requests.where((r) => !r.isApplied).length;
    return [
      if (!saved && c.bannerKind != null)
        SliverToBoxAdapter(child: _Banner(kind: c.bannerKind!, t: t, auth: widget.auth)),
      if (!saved && c.showRequests)
        SliverToBoxAdapter(
          child: _RequestsBar(
            waiting: waiting,
            total: _store.requests.length,
            onTap: () => openRequestsSheet(context, _store),
          ),
        ),
      if (!saved)
        SliverToBoxAdapter(
          child: _MonthAndDays(
            keyMonth: _monthKey,
            keyPickerEnd: _pickerEndKey,
            content: c,
            rangeEndDay: _store.rangeEndDay,
            rangeLabel: _store.rangeLabel,
            pickingEnd: _store.pickingEnd,
            onMonth: () => openMonthCalendar(context, _store),
            onDay: (day) {
              _closeJob();
              final ok = _store.selectDay(day);
              if (!ok) {
                showAppsToast(context,
                    'Pick a range of ${ApplicationsStore.maxRangeDays} days or less.');
              }
            },
          ),
        ),
      if (!saved)
        SliverToBoxAdapter(
          child: _DaySummary(
            key: _daySummaryKey,
            label: c.daySummaryLabel,
            count: c.dayCount,
            showReview: c.showReview && _store.unratedCount > 0,
            onReview: () => _store.openReview(),
            onSearch: () async {
              final job = await openApplicationsSearch(context, _store);
              if (job != null && mounted) await _openJobSheet(job);
            },
          ),
        ),
      if (saved)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved jobs',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: t.ink)),
                Text('Bookmarked applications from any date',
                    style: TextStyle(fontSize: 13, color: t.mute)),
              ],
            ),
          ),
        ),
      if (_store.paneError != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(_store.paneError!, style: TextStyle(color: t.mute)),
          ),
        ),
      if (jobs.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              saved ? 'No saved jobs yet.' : 'No applications in this range.',
              style: TextStyle(color: t.mute),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final job = jobs[index];
              return _JobCard(
                job: job,
                showResume: c.showResumes,
                ratingClosed: c.ratingClosed,
                onOpen: () => _openJobSheet(job),
                onThumbUp: () => _onThumbUp(job),
                onThumbDown: () => _onThumbDown(job),
                onBookmark: () => _onBookmark(job),
              );
            },
            childCount: jobs.length,
          ),
        ),
      ),
      if (hasMore) SliverToBoxAdapter(child: _loadMoreButton(t)),
      const SliverToBoxAdapter(child: SizedBox(height: 128)),
    ];
  }

  Widget _loadMoreButton(HomeTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: OutlinedButton(
        onPressed: _store.loadingMore ? null : _store.loadMore,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: BorderSide(color: t.line),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(_store.loadingMore ? 'Loading…' : 'Load more'),
      ),
    );
  }

  Future<void> _openLogSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: !kIsWeb && Platform.isIOS,
      builder: (sheetContext) {
        return _LogApplicationSheet(
          onSave: ({
            required String company,
            required String role,
            required String appliedOn,
            String jobUrl = '',
          }) =>
              _store.logMine(
                company: company,
                role: role,
                appliedOn: appliedOn,
                jobUrl: jobUrl,
              ),
        );
      },
    );
  }

  List<Widget> _byYouBody(HomeTokens t) {
    final c = _store.content;
    final jobs = _store.visibleByYouJobs;
    return [
      SpringEntrance(
        index: 2,
        child: _MonthAndDays(
          keyMonth: _monthKey,
          keyPickerEnd: _pickerEndKey,
          content: c,
          rangeEndDay: _store.rangeEndDay,
          rangeLabel: _store.rangeLabel,
          pickingEnd: _store.pickingEnd,
          onMonth: () => openMonthCalendar(context, _store),
          onDay: (day) {
            _closeJob();
            final ok = _store.selectDay(day);
            if (!ok) {
              showAppsToast(
                context,
                'Pick a range of ${ApplicationsStore.maxRangeDays} days or less.',
              );
            }
          },
        ),
      ),
      SpringEntrance(
        index: 3,
        child: _DaySummary(
          key: _daySummaryKey,
          label: c.daySummaryLabel,
          count: c.dayCount,
          showReview: false,
          onReview: () {},
          onSearch: () async {
            final job = await openApplicationsSearch(context, _store);
            if (job != null && mounted) await _openJobSheet(job);
          },
        ),
      ),
      if (_store.live)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: FilledButton(
            onPressed: _openLogSheet,
            style: _navyButton(t),
            child: const Text('Log application'),
          ),
        ),
      if (_store.byYouError != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Text(_store.byYouError!, style: TextStyle(color: t.mute)),
              TextButton(
                onPressed: () => _store.loadByYou(reset: true),
                child: const Text('Try again'),
              ),
            ],
          ),
        )
      else if (_store.live && !_store.byYouLoading && jobs.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Text(
            _store.byYouJobs.isEmpty
                ? 'You have not logged an application yet.'
                : 'No applications logged in this range.',
            style: TextStyle(color: t.mute),
          ),
        ),
      for (var i = 0; i < jobs.length; i++)
        SpringEntrance(
          index: 4 + i.clamp(0, 3),
          child: _ByYouJobCard(
            job: jobs[i],
            onBookmark: () => _onBookmark(jobs[i]),
          ),
        ),
      if (_store.live && _store.byYouHasMore)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: OutlinedButton(
            onPressed: () => _store.loadByYou(reset: false),
            child: const Text('Load more'),
          ),
        ),
    ];
  }

  List<Widget> _appliedBody(AppsContent c, HomeTokens t) {
    // Gate states (locked / basic / startingSoon) before byYou — setState maps
    // non-paid previews to byYou, which must not hide the lock / sample cards.
    // Callers: ApplicationsTab ListView + live SliverList; tests: applications_test.
    // User: "build tet for backend and flutter app"
    if (c.startingSoon) {
      return [
        _MonthAndDays(
          keyMonth: _monthKey,
          keyPickerEnd: _pickerEndKey,
          content: c,
          rangeEndDay: _store.rangeEndDay,
          rangeLabel: _store.rangeLabel,
          pickingEnd: _store.pickingEnd,
          onDay: (_) {},
          onMonth: () => openMonthCalendar(context, _store),
        ),
        _StartingSoon(t: t),
      ];
    }

    if (c.basicSample) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: t.peach.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Sample',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.peach.fg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "This is what members see every day",
                style: TextStyle(fontSize: 13, color: t.mute),
              ),
            ],
          ),
        ),
        _MonthAndDays(
          keyMonth: _monthKey,
          keyPickerEnd: _pickerEndKey,
          content: c,
          rangeEndDay: _store.rangeEndDay,
          rangeLabel: _store.rangeLabel,
          pickingEnd: _store.pickingEnd,
          onDay: (_) {},
          onMonth: () => openMonthCalendar(context, _store),
        ),
        _DaySummary(
          key: _daySummaryKey,
          label: c.daySummaryLabel,
          count: c.dayCount,
          showReview: false,
          onReview: () {},
          onSearch: () async {
            final job = await openApplicationsSearch(context, _store);
            if (job != null && mounted) {
              await _openJobSheet(job);
            }
          },
        ),
        // Facts: part of ApplicationsTab (focus_shell); UI-only mock jobs; user:
        // "Match Applications to 04-applications.html" — basic blur + absolute lock.
        Stack(
          clipBehavior: Clip.none,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Opacity(
                opacity: 0.75,
                child: IgnorePointer(
                  child: Column(
                    children: [
                      for (final j in _store.jobs.take(4))
                        _JobCard(
                          job: j,
                          showResume: true,
                          ratingClosed: true,
                          onOpen: () {},
                          onThumbUp: () {},
                          onThumbDown: () {},
                          onBookmark: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 190,
              child: _LockCard(
                icon: Icons.check_circle_outline,
                iconBg: t.mint.bg,
                iconColor: t.mint.fg,
                title: 'Let our team apply for you',
                body:
                    'A real person sends 25–45 applications for you every weekday. Each one shows up here with its resume.',
                secondary: 'Book a call',
                primary: 'See plans ↗',
                onSecondary: () => openExternal(AppUrls.booking),
                onPrimary: () => openExternal(AppUrls.plans),
              ),
            ),
          ],
        ),
      ];
    }

    if (c.locked) {
      return [
        _MonthAndDays(
          keyMonth: _monthKey,
          keyPickerEnd: _pickerEndKey,
          content: c,
          rangeEndDay: _store.rangeEndDay,
          rangeLabel: _store.rangeLabel,
          pickingEnd: _store.pickingEnd,
          onDay: (_) {},
          onMonth: () => openMonthCalendar(context, _store),
        ),
        _DaySummary(
          key: _daySummaryKey,
          label: c.daySummaryLabel,
          count: c.dayCount,
          showReview: false,
          onReview: () {},
          onSearch: () async {
            final job = await openApplicationsSearch(context, _store);
            if (job != null && mounted) {
              await _openJobSheet(job);
            }
          },
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Opacity(
                opacity: 0.55,
                child: IgnorePointer(
                  child: Column(
                    children: [
                      for (final j in _store.jobs.take(3))
                        _JobCard(
                          job: j,
                          showResume: true,
                          ratingClosed: true,
                          onOpen: () {},
                          onThumbUp: () {},
                          onThumbDown: () {},
                          onBookmark: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 30,
              child: _LockCard(
                icon: Icons.lock_outline_rounded,
                iconBg: t.lavender.bg,
                iconColor: t.lavender.fg,
                title: 'Your applications are locked',
                body:
                    'Your plan was changed on 3 Nov. Applications, resumes and responses are hidden. Talk to us if you think this is a mistake.',
                secondary: 'Chat with us',
                primary: 'See plans ↗',
                onSecondary: () => openExternal(AppUrls.whatsapp),
                onPrimary: () => openExternal(AppUrls.plans),
              ),
            ),
          ],
        ),
      ];
    }

    if (_store.jobSource == AppsJobSource.byYou) return _byYouBody(t);

    return [
      if (c.bannerKind != null)
        SpringEntrance(
          index: 1,
          child: _Banner(kind: c.bannerKind!, t: t, auth: widget.auth),
        ),
      if (c.showRequests)
        SpringEntrance(
          index: 1,
          child: _RequestsBar(
            waiting: _store.requests.where((r) => !r.isApplied).length,
            total: _store.requests.length,
            onTap: () => openRequestsSheet(context, _store),
          ),
        ),
      SpringEntrance(
        index: 2,
        child: _MonthAndDays(
          keyMonth: _monthKey,
          keyPickerEnd: _pickerEndKey,
          content: c,
          rangeEndDay: _store.rangeEndDay,
          rangeLabel: _store.rangeLabel,
          pickingEnd: _store.pickingEnd,
          onDay: (day) {
            _closeJob();
            final ok = _store.selectDay(day);
            if (!ok) {
              showAppsToast(
                context,
                'Pick a range of ${ApplicationsStore.maxRangeDays} days or less.',
              );
            }
          },
          onMonth: () => openMonthCalendar(context, _store),
        ),
      ),
      SpringEntrance(
        index: 3,
        child: _DaySummary(
          key: _daySummaryKey,
          label: c.daySummaryLabel,
          count: c.dayCount,
          showReview: c.showReview && _store.unratedCount > 0,
          onReview: () => _store.openReview(),
          onSearch: () async {
            final job = await openApplicationsSearch(context, _store);
            if (job != null && mounted) {
              await _openJobSheet(job);
            }
          },
        ),
      ),
      ...[
        for (var i = 0; i < _store.visibleJobs.length; i++)
          SpringEntrance(
            index: 4 + i.clamp(0, 3),
            child: _JobCard(
              job: _store.visibleJobs[i],
              showResume: c.showResumes,
              ratingClosed: c.ratingClosed,
              onOpen: () => _openJobSheet(_store.visibleJobs[i]),
              onThumbUp: () => _onThumbUp(_store.visibleJobs[i]),
              onThumbDown: () => _onThumbDown(_store.visibleJobs[i]),
              onBookmark: () => _onBookmark(_store.visibleJobs[i]),
            ),
          ),
        // Callers: _appliedBody in ApplicationsTab. Demo Priya resumes are
        // preview-only — hide when live API is connected.
        // User: "make it smotth app with production ready"
        if (c.showResumes && !_store.live) const _OtherResumes(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: OutlinedButton(
            onPressed: () => _store.loadMore(),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.ink,
              side: BorderSide(color: t.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Load more'),
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 10.5, height: 1.55, color: t.mute),
            children: [
              const TextSpan(
                text:
                    'Applications older than 6 months are removed.\nSubmission proofs are on the web: log in at ',
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => openExternal('https://firststepjob.com'),
                  child: Text(
                    'firststepjob.com',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: t.mute,
                      decoration: TextDecoration.underline,
                      decorationColor: t.mute,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ];
  }

  List<Widget> _savedBody(AppsContent c, HomeTokens t) {
    return [
      SpringEntrance(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved jobs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              Text(
                'Bookmarked applications from any date',
                style: TextStyle(fontSize: 13, color: t.mute),
              ),
            ],
          ),
        ),
      ),
      for (var i = 0; i < _store.saved.length; i++)
        SpringEntrance(
          index: 2 + i.clamp(0, 3),
          child: _JobCard(
            job: _store.saved[i],
            showResume: c.showResumes,
            ratingClosed: c.ratingClosed,
            onOpen: () => _openJobSheet(_store.saved[i]),
            onThumbUp: () => _onThumbUp(_store.saved[i]),
            onThumbDown: () => _onThumbDown(_store.saved[i]),
            onBookmark: () => _onBookmark(_store.saved[i]),
          ),
        ),
    ];
  }

  List<Widget> _responsesBody(HomeTokens t) {
    return [
      SpringEntrance(
        index: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Responses',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              Text(
                'Recruiter replies your AIC tagged',
                style: TextStyle(fontSize: 13, color: t.mute),
              ),
            ],
          ),
        ),
      ),
      for (var i = 0; i < _store.responses.length; i++)
        SpringEntrance(
          index: 2 + i.clamp(0, 3),
          child: _ResponseCard(
            response: _store.responses[i],
            onTap: () => openResponseImage(context, _store.responses[i]),
          ),
        ),
    ];
  }
}
