part of '../applications_view.dart';

// --------------------------------------------------------------------------
// Header / tabs
// --------------------------------------------------------------------------

class _TopRow extends StatelessWidget {
  final bool basicSample;
  final bool showCounts;
  final int? firstStepTotal;
  final int? byYouCount;
  final VoidCallback onPreview;
  final VoidCallback onNotifications;
  final VoidCallback onNews;
  final VoidCallback onAnalytics;
  final int unread;

  const _TopRow({
    required this.basicSample,
    required this.showCounts,
    this.firstStepTotal,
    this.byYouCount,
    required this.onPreview,
    required this.onNotifications,
    required this.onNews,
    required this.onAnalytics,
    this.unread = 0,
  });

  // Match 04-applications.html .ah2 / .asub:
  // Row 1: News · centred "Applications" · Notifications
  // Row 2: "412 by FirstStep · 23 by you · Insights"
  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _AppsIconButton(
                icon: Icons.article_outlined,
                label: 'News',
                hasDot: false,
                onTap: onNews,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: kDebugMode ? onPreview : null,
                  onLongPress: kDebugMode ? onPreview : null,
                  onDoubleTap: kDebugMode ? onPreview : null,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Applications',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: t.ink,
                    ),
                  ),
                ),
              ),
              _AppsIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                hasDot: unread > 0,
                onTap: onNotifications,
              ),
            ],
          ),
          if (showCounts) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: firstStepTotal == null ? onAnalytics : null,
              behavior: HitTestBehavior.opaque,
              child: basicSample
                  ? Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: t.mute,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Track jobs you apply to yourself · ',
                          ),
                          TextSpan(
                            text: 'Insights',
                            style: TextStyle(
                              color: t.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: t.mute,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${firstStepTotal ?? 412}',
                            style: TextStyle(
                              color: t.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' by FirstStep'),
                          if (firstStepTotal != null) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: '${byYouCount ?? 0}',
                              style: TextStyle(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' by you'),
                          ] else ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: '23',
                              style: TextStyle(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' by you · '),
                            TextSpan(
                              text: 'Insights',
                              style: TextStyle(
                                color: t.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppsIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasDot;
  final VoidCallback onTap;

  const _AppsIconButton({
    required this.icon,
    required this.label,
    this.hasDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
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
                border: Border.all(color: t.line),
              ),
              child: Icon(icon, size: 20, color: t.ink),
            ),
            if (hasDot)
              Positioned(
                right: 8,
                top: 7,
                child: Container(
                  width: 8,
                  height: 8,
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

class _SourceToggle extends StatelessWidget {
  final AppsJobSource source;
  final ValueChanged<AppsJobSource> onSelect;

  const _SourceToggle({
    required this.source,
    required this.onSelect,
  });

  // Match 04-applications.html .src: sliding navy pill,
  // left = FirstStep triangle + wordmark, right = "By you".
  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final isFs = source == AppsJobSource.byFirstStep;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = (constraints.maxWidth - 8) / 2;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: const Cubic(0.2, 0.9, 0.25, 1.04),
                    top: 0,
                    bottom: 0,
                    left: isFs ? 0 : half,
                    width: half,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.ctaBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _srcSide(
                          onTap: () => onSelect(AppsJobSource.byFirstStep),
                          child: FirstStepLogo(
                            triangleWidth: 14,
                            wordmarkWidth: 72,
                            spacing: 4,
                            isDark: isFs,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _srcSide(
                          onTap: () => onSelect(AppsJobSource.byYou),
                          child: Text(
                            'By you',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isFs ? t.mute : t.ctaInk,
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
        },
      ),
    );
  }

  Widget _srcSide({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: SizedBox(
        height: 38,
        child: Center(child: child),
      ),
    );
  }
}

class _SegTabs extends StatelessWidget {
  final List<int> counts;
  final AppsPane pane;
  final bool locked;
  final ValueChanged<AppsPane> onSelect;

  const _SegTabs({
    required this.counts,
    required this.pane,
    required this.locked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final idx = pane.index;
    final labels = ['Applied', 'Saved', 'Responses'];
    final display = locked
        ? const ['–', '–', '–']
        : counts.map((c) => '$c').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: locked
                    ? () => showAppsToast(
                          context,
                          'Not available in this state.',
                        )
                    : () {
                        HapticFeedback.mediumImpact();
                        onSelect(AppsPane.values[i]);
                      },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${labels[i]} ${display[i]}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              idx == i ? FontWeight.w700 : FontWeight.w500,
                          color: idx == i ? t.ink : t.mute,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: idx == i ? 1 : 0,
                      child: Icon(
                        Icons.keyboard_double_arrow_down_rounded,
                        size: 16,
                        color: t.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestsBar extends StatelessWidget {
  final int waiting;
  final int total;
  final VoidCallback onTap;

  const _RequestsBar({
    required this.waiting,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        color: t.butter.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inbox_outlined,
                      size: 16, color: t.butter.fg),
                ),
                const SizedBox(width: 10),
                Text(
                  'Your requests',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: t.ink,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '$waiting waiting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: t.ink.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.butter.fg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$total',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: t.butter.bg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthAndDays extends StatefulWidget {
  final GlobalKey keyMonth;
  final GlobalKey? keyPickerEnd;
  final AppsContent content;
  final String? rangeEndDay;
  final String rangeLabel;
  final bool pickingEnd;
  final ValueChanged<String> onDay;
  final VoidCallback? onMonth;

  const _MonthAndDays({
    required this.keyMonth,
    this.keyPickerEnd,
    required this.content,
    required this.rangeEndDay,
    required this.rangeLabel,
    required this.pickingEnd,
    required this.onDay,
    this.onMonth,
  });

  @override
  State<_MonthAndDays> createState() => _MonthAndDaysState();
}

class _MonthAndDaysState extends State<_MonthAndDays>
    with AutomaticKeepAliveClientMixin {
  static const _loops = 40;
  static const _itemExtent = 52.0;
  late final ScrollController _daysScroll;
  late int _base;
  int _lastTickIndex = -1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final days = widget.content.days;
    _base = widget.content.finiteDays || days.isEmpty ? 0 : days.length * (_loops ~/ 2);
    final selectedIdx = days.indexWhere(
      (d) => d.day == widget.content.selectedDay,
    );
    final start = selectedIdx < 0 ? 0 : selectedIdx;
    _daysScroll = ScrollController(
      initialScrollOffset: math.max(0, (_base + start) * _itemExtent - 80),
    );
    _daysScroll.addListener(_onDaysScrollTick);
  }

  @override
  void didUpdateWidget(covariant _MonthAndDays old) {
    super.didUpdateWidget(old);
    final days = widget.content.days;
    final nextBase = widget.content.finiteDays || days.isEmpty ? 0 : days.length * (_loops ~/ 2);
    final monthChanged = old.content.monthLabel != widget.content.monthLabel;
    final lengthChanged = old.content.days.length != days.length || old.content.finiteDays != widget.content.finiteDays;
    if (!monthChanged && !lengthChanged && nextBase == _base) return;
    _base = nextBase;
    final selectedIdx = days.indexWhere((d) => d.day == widget.content.selectedDay);
    final start = selectedIdx < 0 ? 0 : selectedIdx;
    final target = math.max(0.0, (_base + start) * _itemExtent - 80);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_daysScroll.hasClients) return;
      final max = _daysScroll.position.maxScrollExtent;
      _daysScroll.jumpTo(target.clamp(0, max).toDouble());
    });
  }

  void _onDaysScrollTick() {
    if (!_daysScroll.hasClients) return;
    // Dial-style tick as each day pill crosses under the finger / viewport.
    final idx = (_daysScroll.offset / _itemExtent).round();
    if (idx == _lastTickIndex) return;
    _lastTickIndex = idx;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _daysScroll.removeListener(_onDaysScrollTick);
    _daysScroll.dispose();
    super.dispose();
  }

  (int lo, int hi)? _rangeBounds() {
    final start = widget.content.selectedDay;
    final end = widget.rangeEndDay;
    if (end == null || end.isEmpty) return null;
    final days = widget.content.days;
    final a = days.indexWhere((x) => x.day == start);
    final b = days.indexWhere((x) => x.day == end);
    if (a < 0 || b < 0) return null;
    return (a < b ? a : b, a < b ? b : a);
  }

  bool _isEndpoint(DayPill d) {
    final start = widget.content.selectedDay;
    final end = widget.rangeEndDay;
    if (d.day == start) return true;
    return end != null && d.day == end;
  }

  bool _inRangeMid(DayPill d) {
    final bounds = _rangeBounds();
    if (bounds == null || d.weekend) return false;
    final days = widget.content.days;
    final i = days.indexWhere((x) => x.day == d.day);
    if (i < 0) return false;
    return i > bounds.$1 && i < bounds.$2;
  }

  String get _hint {
    if (widget.pickingEnd) return 'Tap an end day to finish the range';
    if (widget.rangeEndDay != null && widget.rangeLabel.isNotEmpty) {
      return widget.rangeLabel;
    }
    return 'Tap a start day, then an end day';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final t = HomeTokens.of(context);
    final content = widget.content;
    final days = content.days;
    final loops = content.finiteDays ? 1 : _loops;
    final total = days.isEmpty ? 0 : days.length * loops;

    // keyPickerEnd covers the whole November + haptic day row so sticky
    // selline visibility tracks this block, not a zero-height sentinel.
    return Column(
      key: widget.keyPickerEnd,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          key: widget.keyMonth,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onMonth == null
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              widget.onMonth!();
                            },
                      child: Text(
                        content.monthLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onMonth != null)
                    Material(
                      color: t.sky.bg,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onMonth!();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: t.sky.fg,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _hint,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.pickingEnd
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.pickingEnd ? t.teal : t.mute,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                t.bg.withValues(alpha: 0),
                t.card.withValues(alpha: 0.35),
              ],
            ),
          ),
          child: ListView.builder(
            controller: _daysScroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            itemCount: total,
            itemBuilder: (context, i) {
              final d = days[i % days.length];
              final endpoint = _isEndpoint(d);
              final mid = _inRangeMid(d);
              final muted = d.weekend ||
                  (content.startingSoon &&
                      !d.start &&
                      d.day != content.selectedDay);
              return Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                child: _DayPillButton(
                  pill: d,
                  selected: endpoint,
                  inRange: mid,
                  muted: muted && !endpoint && !mid,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onDay(d.day);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayPillButton extends StatelessWidget {
  final DayPill pill;
  final bool selected;
  final bool inRange;
  final bool muted;
  final VoidCallback onTap;

  const _DayPillButton({
    required this.pill,
    required this.selected,
    required this.inRange,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = selected || inRange;

    final Color? fill;
    Gradient? gradient;
    if (selected) {
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF6CC3CF), Color(0xFF4399A9)]
            : const [Color(0xFF4399A9), Color(0xFF2F8090)],
      );
      fill = null;
    } else if (inRange) {
      fill = isDark
          ? t.teal.withValues(alpha: 0.28)
          : t.teal.withValues(alpha: 0.18);
      gradient = null;
    } else if (pill.start) {
      fill = t.peach.bg;
      gradient = null;
    } else {
      fill = Colors.transparent;
      gradient = null;
    }

    final weekdayColor = selected
        ? (isDark ? const Color(0xFF04222F) : Colors.white)
        : inRange
            ? t.teal
            : pill.start
                ? t.peach.fg
                : muted
                    ? t.mute.withValues(alpha: 0.45)
                    : t.mute;

    final dayFg = selected
        ? (isDark ? Colors.white : const Color(0xFF06334A))
        : inRange
            ? t.teal
            : pill.start
                ? t.peach.fg
                : muted
                    ? t.mute
                    : t.ink;

    final dayBg = selected
        ? (isDark ? Colors.black : Colors.white)
        : inRange
            ? (isDark ? t.card : Colors.white.withValues(alpha: 0.85))
            : pill.start
                ? Colors.white
                : muted
                    ? Colors.transparent
                    : t.card;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: const Cubic(0.2, 0.9, 0.25, 1.04),
        width: 46,
        height: 80,
        padding: const EdgeInsets.fromLTRB(0, 9, 0, 5),
        decoration: BoxDecoration(
          gradient: gradient,
          color: fill,
          borderRadius: BorderRadius.circular(24),
          border: inRange && !selected
              ? Border.all(color: t.teal.withValues(alpha: 0.35))
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.teal.withValues(alpha: 0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        transform: selected
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pill.weekday,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: weekdayColor,
              ),
            ),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dayBg,
                shape: BoxShape.circle,
                boxShadow: active || muted
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                pill.day,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: dayFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Match 04-applications.html `.wash` background behind the sticky header
/// (sky at top fading into page bg — includes `.selline` when shown).
BoxDecoration appsStickyHeaderWash(
  HomeTokens t, {
  required bool isDark,
  required bool active,
}) {
  if (!active) {
    return const BoxDecoration();
  }
  if (isDark) {
    return BoxDecoration(color: t.bg);
  }
  final mid = Color.lerp(t.sky.bg, t.bg, 0.5)!;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [t.sky.bg, mid, t.bg],
      stops: const [0.0, 0.6, 1.0],
    ),
  );
}

/// HTML `.selline` — slim date bar under Applied/Saved/Responses once the
/// day picker has scrolled away. "Change" scrolls back to the calendar.
class _SelectionLine extends StatelessWidget {
  final bool visible;
  final String label;
  final int count;
  final VoidCallback onChange;

  const _SelectionLine({
    required this.visible,
    required this.label,
    required this.count,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final text = label.isEmpty
        ? '$count applications'
        : '$label · $count applications';

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1 : 0,
        child: visible
            ? Padding(
                // Transparent — parent `.wash` gradient provides the sky fill.
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.sky.bg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: t.sky.fg,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onChange,
                        style: TextButton.styleFrom(
                          foregroundColor: t.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 16,
                              color: t.teal,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  final String label;
  final int count;
  final bool showReview;
  final VoidCallback onReview;
  final VoidCallback? onSearch;

  const _DaySummary({
    super.key,
    required this.label,
    required this.count,
    required this.showReview,
    required this.onReview,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);

    Widget circleIcon({
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      return Material(
        color: t.card,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: t.line),
            ),
            child: Icon(icon, color: t.ink, size: 17),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: t.ink,
                        ),
                      ),
                    ),
                    if (onSearch != null) ...[
                      const SizedBox(width: 8),
                      circleIcon(
                        icon: Icons.search_rounded,
                        onTap: onSearch,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '$count applications',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: t.mute,
                  ),
                ),
              ],
            ),
          ),
          if (showReview) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onReview,
              style: TextButton.styleFrom(
                foregroundColor: t.lavender.fg,
                backgroundColor: t.lavender.bg,
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 14),
              label: const Text(
                'Review',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

