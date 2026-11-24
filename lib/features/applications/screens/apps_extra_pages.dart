import 'package:flutter/material.dart';

import '../../../shared_widgets/app_nav.dart';
import '../../../theme/home_tokens.dart';
import '../applications_store.dart';

Future<AppJob?> openApplicationsSearch(
  BuildContext context,
  ApplicationsStore store, {
  String initialQuery = '',
}) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<AppJob>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(
        height: h,
        child: ApplicationsSearchPage(
          store: store,
          initialQuery: initialQuery,
          asSheet: true,
        ),
      );
    },
  );
}

Future<void> openMonthCalendar(
  BuildContext context,
  ApplicationsStore store,
) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(
        height: h,
        child: MonthCalendarPage(store: store, asSheet: true),
      );
    },
  );
}

class ApplicationsSearchPage extends StatefulWidget {
  final ApplicationsStore store;
  final String initialQuery;
  final bool asSheet;

  const ApplicationsSearchPage({
    super.key,
    required this.store,
    this.initialQuery = '',
    this.asSheet = false,
  });

  @override
  State<ApplicationsSearchPage> createState() => _ApplicationsSearchPageState();
}

class _ApplicationsSearchPageState extends State<ApplicationsSearchPage> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    widget.store.addListener(_onStore);
    if (widget.store.live &&
        widget.store.jobSource != AppsJobSource.byYou &&
        widget.initialQuery.trim().length >= 2) {
      widget.store.scheduleSearch(widget.initialQuery);
    }
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _ctrl.dispose();
    super.dispose();
  }

  List<AppJob> get _results {
    final q = _ctrl.text.trim().toLowerCase();
    if (widget.store.jobSource == AppsJobSource.byYou) {
      final all = widget.store.byYouJobs;
      if (q.isEmpty) return all;
      return all
          .where((j) =>
              j.company.toLowerCase().contains(q) ||
              j.role.toLowerCase().contains(q) ||
              j.jobUrl.toLowerCase().contains(q))
          .toList();
    }
    if (widget.store.live) return widget.store.searchResults;
    final all = [...widget.store.jobs, ...widget.store.saved];
    if (q.isEmpty) return all;
    return all
        .where((j) => j.company.toLowerCase().contains(q))
        .toList();
  }

  Widget _searchField(HomeTokens t) {
    return TextField(
      controller: _ctrl,
      autofocus: true,
      style: TextStyle(
        fontFamily: 'Geologica',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: t.ink,
      ),
      onChanged: (value) {
        if (widget.store.live &&
            widget.store.jobSource != AppsJobSource.byYou) {
          widget.store.scheduleSearch(value);
        }
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: widget.store.jobSource == AppsJobSource.byYou
            ? 'Search your logged applications'
            : 'Search by company · last 6 months',
        hintStyle: TextStyle(
          fontFamily: 'Geologica',
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: t.mute,
        ),
        prefixIcon: Icon(Icons.search, color: t.mute),
        filled: true,
        fillColor: t.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.teal, width: 1.4),
        ),
      ),
    );
  }

  Widget _resultTile(HomeTokens t, AppJob job) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, job),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.mint.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.company.isEmpty ? '?' : job.company[0],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: t.mint.fg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.role,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                      Text(
                        '${job.company} · ${job.location}',
                        style: TextStyle(fontSize: 12.5, color: t.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final results = _results;

    if (widget.asSheet) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: t.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: t.mute),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _searchField(t),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        widget.store.searchLoading ? 'Searching…' : 'No matches',
                        style: TextStyle(color: t.mute),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: results.length + (widget.store.searchHasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= results.length) {
                          return TextButton(
                            onPressed: () => widget.store.loadMoreSearch(_ctrl.text),
                            child: const Text('Load more'),
                          );
                        }
                        return _resultTile(t, results[i]);
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return AppPageScaffold(
      title: 'Search',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _searchField(t),
        ),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No matches',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.mute),
            ),
          ),
        for (final job in results)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _resultTile(t, job),
          ),
      ],
    );
  }
}

class MonthCalendarPage extends StatefulWidget {
  final ApplicationsStore store;
  final bool asSheet;

  const MonthCalendarPage({
    super.key,
    required this.store,
    this.asSheet = false,
  });

  @override
  State<MonthCalendarPage> createState() => _MonthCalendarPageState();
}

class _MonthCalendarPageState extends State<MonthCalendarPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _month = widget.store.live
        ? DateTime.utc(widget.store.liveMonth.year, widget.store.liveMonth.month, 1)
        : DateTime.utc(now.year, 11, 1);
  }

  bool get _canPrev {
    final now = DateTime.now().toUtc();
    final oldest = widget.store.live
        ? DateTime.utc(now.year, now.month - 5, 1)
        : DateTime.utc(2026, 5, 1);
    return _month.isAfter(oldest);
  }

  bool get _canNext {
    final now = DateTime.now().toUtc();
    final newest = widget.store.live
        ? DateTime.utc(now.year, now.month, 1)
        : DateTime.utc(2026, 11, 1);
    return _month.isBefore(newest);
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sun=0
    final label = '${_monthName(_month.month)} ${_month.year}';

    final monthNav = Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _canPrev
                ? () => setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    })
                : null,
            icon: Icon(Icons.chevron_left, color: t.ink),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: _canNext
                ? () => setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    })
                : null,
            icon: Icon(Icons.chevron_right, color: t.ink),
          ),
        ],
      ),
    );

    final weekdayRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
            Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.mute,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final grid = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: startWeekday + daysInMonth,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, i) {
          if (i < startWeekday) return const SizedBox.shrink();
          final day = i - startWeekday + 1;
          final dateKey =
              '${_month.year}-${_month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final isNovActive = widget.store.live
              ? (widget.store.activeDayCounts[dateKey] ?? 0) > 0
              : _month.month == 11 && day >= 3 && day <= 8;
          return Material(
            color: isNovActive
                ? t.teal.withValues(alpha: 0.12)
                : (widget.asSheet ? t.bg : t.card),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (widget.store.live) {
                  await widget.store.loadMonth(
                    '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                    preferredDay: '$day',
                  );
                  widget.store.jumpToDay('$day');
                  if (context.mounted) Navigator.pop(context);
                  return;
                }
                if (_month.month == 11 && day >= 3 && day <= 8) {
                  final labels = ['3', '4', '5', '6', '7', '8'];
                  widget.store.selectDay(labels[day - 3]);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('No applications on this day.'),
                      backgroundColor: t.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontWeight:
                        isNovActive ? FontWeight.w700 : FontWeight.w500,
                    color: isNovActive ? t.teal : t.ink,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final hint = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        'Last 6 months only · tap a day with applications',
        style: TextStyle(fontSize: 12.5, color: t.mute),
      ),
    );

    if (widget.asSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: t.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: t.mute),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                monthNav,
                weekdayRow,
                const SizedBox(height: 8),
                grid,
                hint,
              ],
            ),
          ),
        ],
      );
    }

    return AppPageScaffold(
      title: 'Calendar',
      children: [
        monthNav,
        weekdayRow,
        const SizedBox(height: 8),
        grid,
        hint,
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }
}
