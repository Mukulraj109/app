import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../api/api_client.dart';

/// Dev states for Applications, matching 04-applications.html.
enum AppsScreenState {
  activePremium,
  activeElite,
  paymentDue,
  paused,
  expired,
  locked,
  startingSoon,
  basic,
}

enum AppsPane { applied, saved, responses }

enum AppsJobSource { byFirstStep, byYou }

enum RateValue { none, up, down }

class AppJob {
  final String company;
  final String role;
  final String location;
  final String id;
  final String industry;
  final String? appliedLabel;
  /// YYYY-MM-DD from appliedAt — used to filter By you by day/range.
  final String appliedOn;
  String jobUrl;
  final String resumeId;
  String description;
  RateValue rate;
  bool bookmarked;
  bool showFirstStepBadge;

  AppJob({
    required this.company,
    required this.role,
    required this.location,
    required this.id,
    required this.industry,
    this.appliedLabel,
    this.appliedOn = '',
    this.jobUrl = '',
    this.resumeId = '',
    this.description = '',
    this.rate = RateValue.none,
    this.bookmarked = false,
    this.showFirstStepBadge = false,
  });

  AppJob copy() => AppJob(
        company: company,
        role: role,
        location: location,
        id: id,
        industry: industry,
        appliedLabel: appliedLabel,
        appliedOn: appliedOn,
        jobUrl: jobUrl,
        resumeId: resumeId,
        description: description,
        rate: rate,
        bookmarked: bookmarked,
        showFirstStepBadge: showFirstStepBadge,
      );
}

class AppRequest {
  final String id;
  final String url;
  final String source;
  final String status; // sent | applied (backend)
  final String createdLabel;

  const AppRequest({
    required this.id,
    required this.url,
    required this.source,
    required this.status,
    this.createdLabel = '',
  });

  String get host {
    final raw = url.trim();
    if (raw.isEmpty) return 'Job request';
    try {
      final parsed = Uri.parse(raw.contains('://') ? raw : 'https://$raw');
      final host = parsed.host.replaceFirst(RegExp(r'^www\.'), '');
      return host.isEmpty ? raw : host;
    } catch (_) {
      return raw;
    }
  }

  bool get isApplied => status.toLowerCase() == 'applied';

  String get statusLabel => isApplied ? 'Applied' : 'Requested';
}

class AppResponse {
  final String tag; // Interview | Assessment | Final interview
  final String pastel; // lav | but
  final String title;
  final String subtitle;
  final String received;
  final String? due;
  final String proofUrl;

  const AppResponse({
    required this.tag,
    required this.pastel,
    required this.title,
    required this.subtitle,
    this.received = '',
    this.due,
    this.proofUrl = '',
  });
}

class DayPill {
  final String weekday;
  final String day;
  final bool weekend;
  final bool start;

  const DayPill({
    required this.weekday,
    required this.day,
    this.weekend = false,
    this.start = false,
  });
}

class AppsContent {
  final String plan; // premium | elite
  final bool showRequests;
  final List<int> counts; // applied, saved, responses — display values
  final String monthLabel;
  final List<DayPill> days;
  final String selectedDay;
  final String daySummaryLabel;
  final int dayCount;
  final bool showReview;
  final bool ratingClosed;
  final String? bannerKind; // due | pause | exp | null
  final bool locked;
  final bool startingSoon;
  final bool basicSample;
  final bool finiteDays;

  const AppsContent({
    required this.plan,
    required this.showRequests,
    required this.counts,
    required this.monthLabel,
    required this.days,
    required this.selectedDay,
    required this.daySummaryLabel,
    required this.dayCount,
    required this.showReview,
    this.ratingClosed = false,
    this.bannerKind,
    this.locked = false,
    this.startingSoon = false,
    this.basicSample = false,
    this.finiteDays = false,
  });

  bool get showResumes => plan == 'premium';
}

class ApplicationsStore extends ChangeNotifier {
  final ApiClient? api;
  AppsScreenState state;
  AppsContent content;
  AppsPane pane = AppsPane.applied;
  AppsJobSource jobSource;
  List<AppJob> jobs;
  List<AppJob> byYouJobs;
  List<AppJob> saved;
  final List<AppRequest> requests;
  final List<AppResponse> responses;
  int visibleCount = 6;
  String searchQuery = '';
  bool reviewOpen = false;
  int reviewIndex = 0;
  String? rangeEndDay;
  bool _pickingEnd = false;
  bool get pickingEnd => _pickingEnd;
  static const int reviewTotal = 12;

  bool loading = false;
  bool refreshing = false;
  bool booted = false;
  bool loadingMore = false;
  String? error;
  String? savedError;
  String? responsesError;
  bool jobsHasMore = false;
  bool savedHasMore = false;
  bool responsesHasMore = false;
  String loadedMonthKey = '';
  DateTime liveMonth = DateTime.now().toUtc();
  final Map<String, int> dayCounts = {};
  List<AppJob> searchResults = [];
  bool searchLoading = false;
  bool searchHasMore = false;
  String _jobsCursor = '';
  String _savedCursor = '';
  String _responsesCursor = '';
  String _searchCursor = '';
  int _jobsGen = 0;
  int _savedGen = 0;
  int _responsesGen = 0;
  int _byYouGen = 0;
  int _searchGen = 0;
  String _byYouCursor = '';
  Timer? _searchTimer;
  final Set<String> reviewSkippedIds = {};
  String? detailLoadingJobId;

  bool get live => api != null;

  bool get _showRequestsLive => requests.isNotEmpty;

  /// Six-month dashboard total, saved total, and response total from the API.
  int firstStepTotal = 0;
  int byYouCount = 0;
  int savedTotal = 0;
  int responsesTotal = 0;
  bool byYouHasMore = false;
  bool byYouLoading = false;
  String? byYouError;

  ApplicationsStore({this.api, this.state = AppsScreenState.activePremium})
      : content = api == null
            ? _mocks[AppsScreenState.activePremium]!
            : _emptyLiveContent(),
        jobSource = AppsJobSource.byFirstStep,
        jobs = api == null ? _seedJobs() : <AppJob>[],
        byYouJobs = api == null ? _seedByYouJobs() : <AppJob>[],
        saved = api == null ? _seedSaved() : <AppJob>[],
        requests =
            api == null ? List<AppRequest>.from(_seedRequests) : <AppRequest>[],
        responses = api == null
            ? List<AppResponse>.from(_seedResponses)
            : <AppResponse>[] {
    if (api != null) {
      loading = true;
      unawaited(startLive());
    }
  }

  static AppsContent _emptyLiveContent() {
    return const AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: [0, 0, 0],
      monthLabel: '',
      days: [],
      selectedDay: '1',
      daySummaryLabel: '',
      dayCount: 0,
      showReview: false,
      finiteDays: true,
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  static bool isPaidState(AppsScreenState s) =>
      s == AppsScreenState.activePremium ||
      s == AppsScreenState.activeElite ||
      s == AppsScreenState.paymentDue ||
      s == AppsScreenState.paused;

  void setState(AppsScreenState next) {
    if (api != null) return;
    if (next == state) return;
    state = next;
    content = _mocks[next]!;
    pane = AppsPane.applied;
    jobSource =
        isPaidState(next) ? AppsJobSource.byFirstStep : AppsJobSource.byYou;
    jobs = _seedJobs();
    byYouJobs = _seedByYouJobs();
    saved = _seedSaved();
    visibleCount = 6;
    searchQuery = '';
    reviewOpen = false;
    reviewIndex = 0;
    rangeEndDay = null;
    _pickingEnd = false;
    notifyListeners();
  }

  String? get paneError => switch (pane) {
        AppsPane.saved => savedError,
        AppsPane.responses => responsesError,
        AppsPane.applied => error,
      };

  void setJobSource(AppsJobSource next) {
    if (jobSource == next) return;
    jobSource = next;
    notifyListeners();
    if (api == null) return;
    if (next == AppsJobSource.byYou) {
      unawaited(() async {
        if (byYouJobs.isEmpty) await loadByYou(reset: true);
        _syncByYouDayChrome();
      }());
    } else {
      unawaited(loadJobs(reset: true));
    }
  }

  /// Day counts for the month calendar when viewing By you.
  Map<String, int> get byYouDayCounts {
    final map = <String, int>{};
    for (final job in byYouJobs) {
      if (job.appliedOn.isEmpty) continue;
      map[job.appliedOn] = (map[job.appliedOn] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get activeDayCounts =>
      jobSource == AppsJobSource.byYou ? byYouDayCounts : dayCounts;

  List<AppJob> get _byYouInSelectedRange {
    final start = dateKeyForDay(content.selectedDay);
    final endRaw = rangeEndDay;
    final end = dateKeyForDay(
        endRaw == null || endRaw.isEmpty ? content.selectedDay : endRaw);
    final lo = start.compareTo(end) <= 0 ? start : end;
    final hi = start.compareTo(end) <= 0 ? end : start;
    return [
      for (final job in byYouJobs)
        if (job.appliedOn.isNotEmpty &&
            job.appliedOn.compareTo(lo) >= 0 &&
            job.appliedOn.compareTo(hi) <= 0)
          job,
    ];
  }

  void _syncByYouDayChrome() {
    final n = _byYouInSelectedRange.length;
    content = _contentCopy(
      dayCount: n,
      counts: [n, savedTotal, responsesTotal],
    );
    notifyListeners();
  }

  void setPane(AppsPane next) {
    if (pane == next) return;
    if (content.locked || content.basicSample || content.startingSoon) return;
    pane = next;
    notifyListeners();
    if (api == null) return;
    if (next == AppsPane.saved && saved.isEmpty) {
      unawaited(loadSaved(reset: true));
    } else if (next == AppsPane.responses && responses.isEmpty) {
      unawaited(loadResponses(reset: true));
    }
  }

  /// First tap = start day; second tap = end day; next tap starts a new range.
  /// Ranges longer than 7 calendar days are rejected (caller should toast).
  static const int maxRangeDays = 7;

  /// Calendar pick: one day, not the start of a range.
  void jumpToDay(String day) {
    rangeEndDay = null;
    _pickingEnd = false;
    _applyDay(day);
  }

  /// Returns false when the end day would exceed [maxRangeDays].
  bool selectDay(String day) {
    if (!_pickingEnd) {
      rangeEndDay = null;
      _pickingEnd = true;
      _applyDay(day, end: null);
      return true;
    }
    if (day == content.selectedDay) {
      _pickingEnd = false;
      notifyListeners();
      return true;
    }
    final span = _calendarSpan(content.selectedDay, day);
    if (span > maxRangeDays) {
      return false;
    }
    rangeEndDay = day;
    _pickingEnd = false;
    _applyDay(content.selectedDay, end: day);
    return true;
  }

  int _calendarSpan(String start, String end) {
    final a = int.tryParse(start) ?? 0;
    final b = int.tryParse(end) ?? 0;
    return (a - b).abs() + 1;
  }

  void _applyDay(String start, {String? end}) {
    content = _contentCopy(
      selectedDay: start,
      daySummaryLabel:
          end == null ? _summaryFor(start) : rangeLabelFor(start, end),
      finiteDays: api != null ? true : content.finiteDays,
    );
    if (api != null && jobSource == AppsJobSource.byYou) {
      _syncByYouDayChrome();
      return;
    }
    final dayCount = api != null
        ? _countBetween(start, end)
        : end == null
            ? 18 + (int.tryParse(start) ?? 0) % 9
            : _rangeCount(start, end);
    content = _contentCopy(
      dayCount: dayCount,
      showReview: content.showReview && !content.ratingClosed,
      counts: api == null
          ? content.counts
          : [dayCount, savedTotal, responsesTotal],
    );
    notifyListeners();
    if (api != null &&
        !content.locked &&
        !content.basicSample &&
        !content.startingSoon) {
      unawaited(loadJobs(reset: true));
    }
  }

  String get rangeLabel {
    final end = rangeEndDay;
    if (end == null || end == content.selectedDay) return '';
    return rangeLabelFor(content.selectedDay, end);
  }

  String _summaryFor(String day, {String? monthLabel}) {
    final label = monthLabel ?? content.monthLabel;
    final pill = content.days.firstWhere(
      (d) => d.day == day,
      orElse: () => DayPill(weekday: 'Fri', day: day),
    );
    if (day == '14' && label.startsWith('November')) {
      return 'Today';
    }
    final month = label.split(' ').first;
    final short = month.length >= 3 ? month.substring(0, 3) : month;
    return '${pill.weekday} $day $short'.trim();
  }

  /// Compact range for the summary row: "Nov 10 to 14" (fits next to Review).
  String rangeLabelFor(String start, String end) {
    final month = content.monthLabel.split(' ').first;
    final short = month.length >= 3 ? month.substring(0, 3) : month;
    final a = int.tryParse(start) ?? 0;
    final b = int.tryParse(end) ?? 0;
    final lo = a <= b ? start : end;
    final hi = a <= b ? end : start;
    return '$short $lo to $hi';
  }

  int _rangeCount(String start, String end) {
    final days = content.days;
    final a = days.indexWhere((d) => d.day == start);
    final b = days.indexWhere((d) => d.day == end);
    if (a < 0 || b < 0) return content.dayCount;
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    var n = 0;
    for (var i = lo; i <= hi; i++) {
      if (!days[i].weekend) n++;
    }
    return 12 + n * 3;
  }

  void setSearch(String q) {
    searchQuery = q.trim();
    notifyListeners();
  }

  void loadMore() {
    if (api != null) {
      if (pane == AppsPane.saved) {
        unawaited(loadSaved(reset: false));
      } else if (pane == AppsPane.responses) {
        unawaited(loadResponses(reset: false));
      } else if (jobSource == AppsJobSource.byYou) {
        unawaited(loadByYou(reset: false));
      } else {
        unawaited(loadJobs(reset: false));
      }
      return;
    }
    visibleCount = (visibleCount + 20).clamp(0, jobs.length);
    notifyListeners();
  }

  List<AppJob> get visibleJobs {
    if (api != null) return jobs;
    var list = jobs;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = [
        ...jobs,
        ...saved,
      ].where((j) => j.company.toLowerCase().contains(q)).toList();
    }
    return list.take(visibleCount).toList();
  }

  List<AppJob> get visibleByYouJobs {
    if (api == null) return byYouJobs.take(visibleCount).toList();
    return _byYouInSelectedRange;
  }

  List<AppJob> get bookmarkedJobs {
    final fromDay = jobs.where((j) => j.bookmarked);
    final fromYou = byYouJobs.where((j) => j.bookmarked);
    final fromSaved = saved.where((j) => j.bookmarked);
    final map = <String, AppJob>{};
    for (final j in [...fromSaved, ...fromDay, ...fromYou]) {
      map[j.id] = j;
    }
    return map.values.toList();
  }

  int get unratedCount => jobs.where((j) => j.rate == RateValue.none).length;

  Future<bool> toggleBookmark(AppJob job) async {
    final next = !job.bookmarked;
    job.bookmarked = next;
    if (next) {
      savedTotal++;
    } else if (savedTotal > 0) {
      savedTotal--;
    }
    _syncSavedCopy(job);
    _touchCounts();
    notifyListeners();
    if (api == null) return true;
    try {
      await api!.saveApplication(job.id, saved: next);
      unawaited(_refreshMonthCounts());
      return true;
    } catch (_) {
      job.bookmarked = !next;
      if (next) {
        if (savedTotal > 0) savedTotal--;
      } else {
        savedTotal++;
      }
      _syncSavedCopy(job);
      _touchCounts();
      error = 'Could not update saved jobs.';
      notifyListeners();
      return false;
    }
  }

  void _syncSavedCopy(AppJob job) {
    saved.removeWhere((row) => row.id == job.id);
    if (job.bookmarked) saved.insert(0, job.copy());
    for (final row in jobs) {
      if (row.id == job.id) row.bookmarked = job.bookmarked;
    }
  }

  Future<bool> rateUp(AppJob job) async {
    if (content.ratingClosed) return false;
    final previous = job.rate;
    job.rate = job.rate == RateValue.up ? RateValue.none : RateValue.up;
    notifyListeners();
    if (api == null || job.rate == RateValue.none) return true;
    try {
      await api!.applicationFeedback(job.id, rating: 'up');
      return true;
    } catch (_) {
      job.rate = previous;
      error = 'Could not save your rating.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rateDown(AppJob job, {String reason = ''}) async {
    if (content.ratingClosed) return false;
    final previous = job.rate;
    job.rate = RateValue.down;
    notifyListeners();
    if (api == null) return true;
    try {
      await api!.applicationFeedback(job.id, rating: 'down', reason: reason);
      return true;
    } catch (_) {
      job.rate = previous;
      error = 'Could not save your rating.';
      notifyListeners();
      return false;
    }
  }

  void openReview() {
    if (!content.showReview || content.ratingClosed) return;
    reviewOpen = true;
    reviewIndex = 0;
    reviewSkippedIds.clear();
    notifyListeners();
  }

  void closeReview() {
    reviewOpen = false;
    reviewSkippedIds.clear();
    notifyListeners();
  }

  List<AppJob> get reviewQueue => jobs
      .where((j) => j.rate == RateValue.none && !reviewSkippedIds.contains(j.id))
      .toList();

  void bumpReviewIndex() {
    reviewIndex = (reviewIndex + 1).clamp(0, reviewTotal);
    notifyListeners();
  }

  void reviewSkip(AppJob job) {
    if (job.id.isNotEmpty) reviewSkippedIds.add(job.id);
    bumpReviewIndex();
  }

  /// Legacy local-only advance (mock / tests). Live Review uses rateUp/rateDown.
  void reviewAdvance({required String how}) {
    // how: yes | no | skip
    final queue = reviewQueue;
    if (queue.isEmpty) {
      reviewOpen = false;
      notifyListeners();
      return;
    }
    final job = queue.first;
    if (how == 'yes') {
      job.rate = RateValue.up;
    } else if (how == 'no') {
      job.rate = RateValue.down;
    } else {
      reviewSkippedIds.add(job.id);
    }
    bumpReviewIndex();
  }

  bool get reviewDone =>
      reviewOpen && (reviewQueue.isEmpty || reviewIndex >= reviewTotal);

  // ---- industry pastel keys (match HTML PAL) ----
  static String pastelFor(String industry) {
    switch (industry) {
      case 'Fintech':
        return 'mint';
      case 'Banking':
        return 'sky';
      case 'Travel':
        return 'pch';
      case 'SaaS':
        return 'lav';
      case 'Cloud':
        return 'sky';
      case 'Automotive':
        return 'but';
      case 'Design':
        return 'pch';
      default:
        return 'lav';
    }
  }

  static List<AppJob> _seedJobs() => [
        AppJob(
          company: 'Stripe',
          role: 'Data Engineer',
          location: 'Seattle, WA',
          id: 'R-48213',
          industry: 'Fintech',
          rate: RateValue.up,
          bookmarked: true,
        ),
        AppJob(
          company: 'Capital One',
          role: 'Data Engineer II',
          location: 'McLean, VA',
          id: 'JR-110482',
          industry: 'Banking',
        ),
        AppJob(
          company: 'Airbnb',
          role: 'Analytics Engineer',
          location: 'Remote · US',
          id: '7731902',
          industry: 'Travel',
          rate: RateValue.up,
        ),
        AppJob(
          company: 'Notion',
          role: 'Data Platform Engineer',
          location: 'San Francisco, CA',
          id: 'NTN-2291',
          industry: 'SaaS',
        ),
        AppJob(
          company: 'Datadog',
          role: 'Senior Data Engineer',
          location: 'New York, NY',
          id: '5521873',
          industry: 'Cloud',
          bookmarked: true,
        ),
        AppJob(
          company: 'Rivian',
          role: 'Data Engineer',
          location: 'Irvine, CA',
          id: 'RIV-18834',
          industry: 'Automotive',
        ),
      ];

  static List<AppJob> _seedByYouJobs() => [
        AppJob(
          company: 'Vercel',
          role: 'Data Engineer',
          location: 'Remote',
          id: 'YOU-1001',
          industry: 'SaaS',
          appliedLabel: 'Applied',
        ),
        AppJob(
          company: 'Linear',
          role: 'Analytics Engineer',
          location: 'Remote',
          id: 'YOU-1002',
          industry: 'SaaS',
          appliedLabel: 'Applied',
        ),
        AppJob(
          company: 'Ramp',
          role: 'Data Engineer II',
          location: 'New York, NY',
          id: 'YOU-1003',
          industry: 'Fintech',
          appliedLabel: 'Applied',
        ),
        AppJob(
          company: 'Supabase',
          role: 'Platform Engineer',
          location: 'Remote',
          id: 'YOU-1004',
          industry: 'Cloud',
          appliedLabel: 'Applied',
        ),
      ];

  static List<AppJob> _seedSaved() => [
        AppJob(
          company: 'Stripe',
          role: 'Data Engineer',
          location: 'Seattle, WA',
          id: 'R-48213',
          industry: 'Fintech',
          appliedLabel: 'Applied today',
          rate: RateValue.up,
          bookmarked: true,
        ),
        AppJob(
          company: 'Datadog',
          role: 'Senior Data Engineer',
          location: 'New York, NY',
          id: '5521873',
          industry: 'Cloud',
          appliedLabel: 'Applied today',
          bookmarked: true,
        ),
        AppJob(
          company: 'Snowflake',
          role: 'Data Engineer',
          location: 'Bellevue, WA',
          id: 'SNW-55102',
          industry: 'Cloud',
          appliedLabel: 'Applied 12 Nov',
          rate: RateValue.up,
          bookmarked: true,
        ),
        AppJob(
          company: 'Robinhood',
          role: 'Analytics Engineer',
          location: 'Menlo Park, CA',
          id: 'RH-7720',
          industry: 'Fintech',
          appliedLabel: 'Applied 6 Nov',
          bookmarked: true,
        ),
      ];

  static const _seedRequests = [
    AppRequest(
      id: 'req-1',
      url: 'https://www.figma.com/careers/data-engineer',
      source: 'share',
      status: 'sent',
      createdLabel: '13 Nov',
    ),
    AppRequest(
      id: 'req-2',
      url: 'https://plaid.com/careers/analytics-engineer',
      source: 'paste',
      status: 'sent',
      createdLabel: '13 Nov',
    ),
    AppRequest(
      id: 'req-3',
      url: 'https://stripe.com/jobs/data-engineer',
      source: 'paste',
      status: 'applied',
      createdLabel: '12 Nov',
    ),
  ];

  static const _seedResponses = [
    AppResponse(
      tag: 'Interview',
      pastel: 'lav',
      title: 'Amazon · Data Engineer II',
      subtitle: 'Received 13 Nov',
      due: 'Tue 18 Nov',
    ),
    AppResponse(
      tag: 'Assessment',
      pastel: 'but',
      title: 'Capital One · HackerRank',
      subtitle: 'Received 12 Nov',
      due: 'Fri 21 Nov',
    ),
    AppResponse(
      tag: 'Final interview',
      pastel: 'lav',
      title: 'Snowflake · Data Engineer',
      subtitle: 'Received 6 Nov',
    ),
  ];

  Future<void>? _boot;

  Future<void> loadJobRequests() async {
    final client = api;
    if (client == null) return;
    final json = await client.getJobRequests();
    final rawList = json['requests'] ?? json['items'] ?? json['jobRequests'];
    final rows = rawList is List ? rawList : const [];
    requests
      ..clear()
      ..addAll(rows.whereType<Map>().map((raw) {
        final row = Map<String, dynamic>.from(raw);
        return AppRequest(
          id: '${row['id'] ?? ''}',
          url: '${row['url'] ?? ''}',
          source: '${row['source'] ?? 'paste'}',
          status: '${row['status'] ?? 'sent'}',
          createdLabel: _prettyDay('${row['createdAt'] ?? ''}'),
        );
      }).toList());
    content = _contentCopy(showRequests: _showRequestsLive);
    notifyListeners();
  }

  AppsContent _contentCopy({
    String? plan,
    bool? showRequests,
    List<int>? counts,
    String? monthLabel,
    List<DayPill>? days,
    String? selectedDay,
    String? daySummaryLabel,
    int? dayCount,
    bool? showReview,
    bool? ratingClosed,
    String? bannerKind,
    bool clearBanner = false,
    bool? locked,
    bool? startingSoon,
    bool? basicSample,
    bool? finiteDays,
  }) {
    return AppsContent(
      plan: plan ?? content.plan,
      showRequests: showRequests ?? (api != null ? _showRequestsLive : content.showRequests),
      counts: counts ?? content.counts,
      monthLabel: monthLabel ?? content.monthLabel,
      days: days ?? content.days,
      selectedDay: selectedDay ?? content.selectedDay,
      daySummaryLabel: daySummaryLabel ?? content.daySummaryLabel,
      dayCount: dayCount ?? content.dayCount,
      showReview: showReview ?? content.showReview,
      ratingClosed: ratingClosed ?? content.ratingClosed,
      bannerKind: clearBanner ? null : (bannerKind ?? content.bannerKind),
      locked: locked ?? content.locked,
      startingSoon: startingSoon ?? content.startingSoon,
      basicSample: basicSample ?? content.basicSample,
      finiteDays: finiteDays ?? content.finiteDays,
    );
  }

  Future<void> startLive() {
    return _boot ??= _startLive();
  }

  Future<void> _startLive() async {
    final now = DateTime.now().toUtc();
    liveMonth = DateTime.utc(now.year, now.month, 1);
    try {
      await loadMonth(monthKey(liveMonth),
          preferredDay: '${now.day}', force: true);
      if (content.locked || content.basicSample || content.startingSoon) {
        loading = false;
        booted = true;
        notifyListeners();
        return;
      }
      await Future.wait([
        loadJobs(reset: true),
        loadSaved(reset: true),
        loadResponses(reset: true),
        () async {
          try {
            await loadJobRequests();
          } catch (_) {}
        }(),
      ]);
      loading = false;
      booted = true;
      notifyListeners();
    } catch (err) {
      if (jobs.isEmpty && saved.isEmpty && responses.isEmpty) {
        error = _failureMessage(err, 'Could not load applications.');
      }
      loading = false;
      booted = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (api == null) return;
    error = null;
    refreshing = true;
    notifyListeners();
    try {
      if (pane == AppsPane.saved) {
        await loadSaved(reset: true);
        return;
      }
      if (pane == AppsPane.responses) {
        await loadResponses(reset: true);
        return;
      }
      final monthReady = loadedMonthKey.isNotEmpty && content.days.isNotEmpty;
      if (monthReady) {
        await Future.wait([
          loadMonth(loadedMonthKey, force: true),
          loadJobs(reset: true),
        ]);
      } else {
        await loadMonth(
            loadedMonthKey.isEmpty ? monthKey(liveMonth) : loadedMonthKey,
            force: true);
        await loadJobs(reset: true);
      }
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  String monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  String dateKeyForDay(String day) {
    final n = int.tryParse(day) ?? 1;
    return '${liveMonth.year}-${liveMonth.month.toString().padLeft(2, '0')}-${n.toString().padLeft(2, '0')}';
  }

  int _countBetween(String start, String? end) {
    final a = int.tryParse(start) ?? 1;
    final b = int.tryParse(end ?? start) ?? a;
    final lo = a <= b ? a : b;
    final hi = a <= b ? b : a;
    var total = 0;
    for (var day = lo; day <= hi; day++) {
      total += dayCounts[dateKeyForDay('$day')] ?? 0;
    }
    return total;
  }

  Future<void> loadMonth(String key,
      {String? preferredDay, bool force = false}) async {
    if (api == null) return;
    if (!force && key == loadedMonthKey && content.days.isNotEmpty) return;
    final body = await api!.applicationMonth(key);
    final parts = key.split('-');
    liveMonth = DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), 1);
    loadedMonthKey = key;
    dayCounts
      ..clear()
      ..addAll({
        for (final row in (body['days'] as List? ?? const []))
          if (row is Map)
            '${row['date']}': (row['count'] as num?)?.toInt() ?? 0,
      });
    final daysInMonth =
        DateTime.utc(liveMonth.year, liveMonth.month + 1, 0).day;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = <DayPill>[
      for (var day = 1; day <= daysInMonth; day++)
        DayPill(
          weekday: names[
              DateTime.utc(liveMonth.year, liveMonth.month, day).weekday - 1],
          day: '$day',
          weekend:
              DateTime.utc(liveMonth.year, liveMonth.month, day).weekday >= 6,
        ),
    ];
    final selected = preferredDay ??
        (days.any((pill) => pill.day == content.selectedDay)
            ? content.selectedDay
            : '1');
    final monthLabel = _monthLabel(liveMonth);
    final summaryPill = days.firstWhere(
      (pill) => pill.day == selected,
      orElse: () => DayPill(weekday: '', day: selected),
    );
    final monthWord = monthLabel.split(' ').first;
    final monthShort =
        monthWord.length >= 3 ? monthWord.substring(0, 3) : monthWord;
    final summary = '${summaryPill.weekday} $selected $monthShort'.trim();
    firstStepTotal = (body['total'] as num?)?.toInt() ?? firstStepTotal;
    byYouCount = (body['byYouCount'] as num?)?.toInt() ?? byYouCount;
    savedTotal = (body['savedCount'] as num?)?.toInt() ?? savedTotal;
    responsesTotal =
        (body['responsesCount'] as num?)?.toInt() ?? responsesTotal;
    _applyAccess(body);
    final dayCount = _countBetween(selected, null);
    content = _contentCopy(
      monthLabel: monthLabel,
      days: days,
      selectedDay: selected,
      daySummaryLabel: summary,
      dayCount: dayCount,
      counts: [dayCount, savedTotal, responsesTotal],
      finiteDays: true,
    );
    notifyListeners();
  }

  Future<void> _refreshMonthCounts() async {
    if (api == null || loadedMonthKey.isEmpty) return;
    try {
      final body = await api!.applicationMonth(loadedMonthKey);
      firstStepTotal = (body['total'] as num?)?.toInt() ?? firstStepTotal;
      byYouCount = (body['byYouCount'] as num?)?.toInt() ?? byYouCount;
      savedTotal = (body['savedCount'] as num?)?.toInt() ?? savedTotal;
      responsesTotal =
          (body['responsesCount'] as num?)?.toInt() ?? responsesTotal;
      _touchCounts();
      notifyListeners();
    } catch (_) {
      /* keep optimistic counts */
    }
  }

  void _applyAccess(Map<String, dynamic> body) {
    final access = '${body['access'] ?? ''}';
    final stateName = '${body['state'] ?? ''}';
    final resumesHidden = body['resumesHidden'] == true;
    final paused = body['paused'] == true;
    final banner = paused
        ? 'pause'
        : body['paymentDue'] == true
            ? 'due'
            : stateName == 'expired'
                ? 'exp'
                : null;
    content = _contentCopy(
      plan: resumesHidden ? 'elite' : 'premium',
      showReview: access == 'full',
      ratingClosed: access == 'read_only' || access == 'list_only_no_resumes',
      bannerKind: banner,
      clearBanner: banner == null,
      locked: access == 'hidden',
      startingSoon: stateName == 'starting_soon',
      basicSample: stateName == 'basic',
      finiteDays: true,
    );
  }

  String _monthLabel(DateTime month) {
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
    return '${names[month.month - 1]} ${month.year}';
  }

  Future<void> loadByYou({required bool reset}) async {
    if (api == null) return;
    if (!reset && (!byYouHasMore || byYouLoading)) return;
    final gen = reset ? ++_byYouGen : _byYouGen;
    if (reset) {
      _byYouCursor = '';
      byYouHasMore = false;
    }
    byYouLoading = true;
    byYouError = null;
    notifyListeners();
    try {
      final body = await api!.userApplications(cursor: reset ? '' : _byYouCursor);
      if (gen != _byYouGen) return;
      final parsed = _jobsFrom(body);
      if (reset) {
        // Keep rows logged while this request was in flight.
        final keep = [
          for (final row in byYouJobs)
            if (parsed.every((p) => p.id != row.id)) row,
        ];
        byYouJobs = [...keep, ...parsed];
      } else {
        byYouJobs = [...byYouJobs, ...parsed];
      }
      _byYouCursor = '${body['nextCursor'] ?? ''}';
      byYouHasMore = body['hasMore'] == true;
      if (jobSource == AppsJobSource.byYou) _syncByYouDayChrome();
    } on ApiException catch (err) {
      if (gen != _byYouGen) return;
      if (reset) byYouJobs = [];
      byYouError = err.message;
    } catch (err) {
      if (gen != _byYouGen) return;
      if (reset) byYouJobs = [];
      byYouError = _failureMessage(err, 'Could not load applications.');
    }
    if (gen == _byYouGen) {
      byYouLoading = false;
      notifyListeners();
    }
  }

  Future<AppJob?> logMine({
    required String company,
    required String role,
    required String appliedOn,
    String jobUrl = '',
  }) async {
    if (api == null) return null;
    final body = await api!.logApplication(
      company: company,
      role: role,
      appliedOn: appliedOn,
      jobUrl: jobUrl,
    );
    final job = _jobsFrom({'jobs': [body]}).firstOrNull;
    if (job == null) return null;
    byYouJobs = [job, ...byYouJobs.where((row) => row.id != job.id)];
    byYouCount += 1;
    byYouError = null;
    if (jobSource == AppsJobSource.byYou) {
      // Show the day the user just logged so the new card is not filtered out.
      if (job.appliedOn.isNotEmpty) {
        final parts = job.appliedOn.split('-');
        if (parts.length == 3) {
          final dayNum = int.tryParse(parts[2]) ?? 0;
          if (dayNum > 0) {
            rangeEndDay = null;
            _pickingEnd = false;
            content = _contentCopy(
              selectedDay: '$dayNum',
              daySummaryLabel: _summaryFor('$dayNum'),
            );
          }
        }
      }
      _syncByYouDayChrome();
    } else {
      notifyListeners();
    }
    unawaited(_refreshMonthCounts());
    return job;
  }

  Future<void> loadJobs({required bool reset}) async {
    if (api == null ||
        content.locked ||
        content.basicSample ||
        content.startingSoon) return;
    if (!reset && (!jobsHasMore || loadingMore)) return;
    final gen = reset ? ++_jobsGen : _jobsGen;
    if (reset) {
      _jobsCursor = '';
      jobsHasMore = false;
      if (!booted || jobs.isEmpty) {
        loading = true;
      }
    } else {
      loadingMore = true;
    }
    error = null;
    notifyListeners();
    try {
      final end = rangeEndDay;
      final body = await api!.applications(
        from: dateKeyForDay(content.selectedDay),
        to: dateKeyForDay(
            end == null || end.isEmpty ? content.selectedDay : end),
        cursor: reset ? '' : _jobsCursor,
      );
      if (gen != _jobsGen) return;
      final parsed = _jobsFrom(body);
      if (reset) {
        jobs = parsed;
      } else {
        jobs = [...jobs, ...parsed];
      }
      _jobsCursor = '${body['nextCursor'] ?? ''}';
      jobsHasMore = body['hasMore'] == true;
      _applyAccess(body);
      content = _contentCopy(
        counts: [content.dayCount, savedTotal, responsesTotal],
        finiteDays: true,
      );
    } on ApiException catch (err) {
      if (gen != _jobsGen) return;
      error = err.message;
    } catch (err) {
      if (gen != _jobsGen) return;
      error = _failureMessage(err, 'Could not load applications.');
    }
    if (gen == _jobsGen) {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadSaved({required bool reset}) async {
    if (api == null) return;
    if (!reset && (!savedHasMore || loadingMore)) return;
    final gen = reset ? ++_savedGen : _savedGen;
    if (reset) {
      _savedCursor = '';
      savedHasMore = false;
    } else {
      loadingMore = true;
      notifyListeners();
    }
    savedError = null;
    try {
      final cursor = reset ? '' : _savedCursor;
      final body = await _retryOnce(() => api!.savedJobs(cursor: cursor));
      if (gen != _savedGen) return;
      final parsed = _jobsFrom(body);
      saved = reset ? parsed : [...saved, ...parsed];
      _savedCursor = '${body['nextCursor'] ?? ''}';
      savedHasMore = body['hasMore'] == true;
      _touchCounts();
    } catch (err) {
      if (gen != _savedGen) return;
      savedError = _failureMessage(err, 'Could not load saved jobs.');
    }
    if (gen == _savedGen) {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadResponses({required bool reset}) async {
    if (api == null) return;
    if (!reset && (!responsesHasMore || loadingMore)) return;
    final gen = reset ? ++_responsesGen : _responsesGen;
    if (reset) {
      _responsesCursor = '';
      responsesHasMore = false;
    } else {
      loadingMore = true;
      notifyListeners();
    }
    responsesError = null;
    try {
      final cursor = reset ? '' : _responsesCursor;
      final body =
          await _retryOnce(() => api!.applicationResponses(cursor: cursor));
      if (gen != _responsesGen) return;
      final parsed = _responsesFrom(body);
      if (reset) responses.clear();
      responses.addAll(parsed);
      _responsesCursor = '${body['nextCursor'] ?? ''}';
      responsesHasMore = body['hasMore'] == true;
      _touchCounts();
    } catch (err) {
      if (gen != _responsesGen) return;
      responsesError = _failureMessage(err, 'Could not load responses.');
    }
    if (gen == _responsesGen) {
      loadingMore = false;
      notifyListeners();
    }
  }

  void _touchCounts() {
    content = _contentCopy(
      counts: [
        content.dayCount,
        api == null ? saved.length : savedTotal,
        api == null ? responses.length : responsesTotal,
      ],
    );
  }

  RateValue _rateFrom(dynamic raw) {
    switch ('$raw') {
      case 'up':
        return RateValue.up;
      case 'down':
        return RateValue.down;
      default:
        return RateValue.none;
    }
  }

  /// Maps GET /api/me/applications* `jobs[]`. Prefer jobId (web shape); accept id.
  List<AppJob> _jobsFrom(Map<String, dynamic> body) {
    final rows = body['jobs'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map)
          if ('${row['jobId'] ?? row['id'] ?? ''}'.trim().isNotEmpty)
            AppJob(
              id: '${row['jobId'] ?? row['id']}'.trim(),
              company: '${row['company'] ?? row['companyName'] ?? ''}'.trim(),
              role:
                  '${row['role'] ?? row['jobTitle'] ?? row['title'] ?? ''}'.trim(),
              location: '${row['location'] ?? ''}'.trim(),
              industry: '${row['industry'] ?? row['jobCategory'] ?? ''}'
                      .trim()
                      .isEmpty
                  ? 'General'
                  : '${row['industry'] ?? row['jobCategory']}'.trim(),
              appliedLabel: _appliedLabel(
                '${row['appliedAt'] ?? row['applicationDate'] ?? ''}',
              ),
              appliedOn: _dateKeyFromIso(
                '${row['appliedAt'] ?? row['applicationDate'] ?? ''}',
              ),
              jobUrl: '${row['jobUrl'] ?? row['url'] ?? ''}'.trim(),
              resumeId: '${row['resumeId'] ?? ''}'.trim(),
              bookmarked: row['saved'] == true,
              showFirstStepBadge: row['showFirstStepBadge'] == true,
              rate: _rateFrom(row['rating']),
            ),
    ];
  }

  String _dateKeyFromIso(String iso) {
    final parsed = DateTime.tryParse(iso.trim());
    if (parsed == null) return '';
    final day = parsed.toUtc();
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  String? _appliedLabel(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    final day = parsed.toUtc();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return 'Applied ${day.day} ${months[day.month - 1]}';
  }

  List<AppResponse> _responsesFrom(Map<String, dynamic> body) {
    final rows = body['responses'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map)
          AppResponse(
            tag: _kindLabel('${row['kind'] ?? ''}'),
            pastel: _responsePastel('${row['kind'] ?? ''}'),
            title: '${row['title'] ?? ''}'.trim().isEmpty
                ? '${row['company'] ?? ''}'
                : '${row['title']}'.trim(),
            subtitle: '${row['company'] ?? ''}'.trim(),
            received: _prettyDay('${row['date'] ?? ''}'),
            due: _optionalDay('${row['dueDate'] ?? ''}'),
            proofUrl: '${row['proofUrl'] ?? ''}'.trim(),
          ),
    ];
  }

  static bool _transient(Object err) =>
      err is TimeoutException ||
      err is SocketException ||
      err is http.ClientException;

  /// Parallel boot requests to a dev server sometimes drop one connection.
  Future<T> _retryOnce<T>(Future<T> Function() send) async {
    try {
      return await send();
    } catch (err) {
      if (!_transient(err)) rethrow;
      return send();
    }
  }

  String _failureMessage(Object err, String fallback) {
    debugPrint('Applications load failed: ${err.runtimeType}: $err');
    if (err is ApiException) return err.message;
    if (err is TimeoutException)
      return 'The request timed out. Check the connection and try again.';
    if (err is SocketException || err is http.ClientException)
      return 'Could not reach the server.';
    if (err is FormatException)
      return 'The server sent a response the app could not read.';
    return fallback;
  }

  String _kindLabel(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Response';
    return text.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _responsePastel(String kind) {
    final text = kind.toLowerCase();
    if (text.contains('interview') || text.contains('screen')) return 'lav';
    return 'but';
  }

  String _prettyDay(String key) {
    final parsed = DateTime.tryParse(key.trim());
    if (parsed == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${parsed.day} ${months[parsed.month - 1]}';
  }

  String? _optionalDay(String key) {
    final pretty = _prettyDay(key);
    return pretty.isEmpty ? null : pretty;
  }

  void scheduleSearch(String query) {
    _searchTimer?.cancel();
    final text = query.trim();
    if (api == null) {
      setSearch(text);
      return;
    }
    if (text.length < 2) {
      searchResults = [];
      searchHasMore = false;
      searchLoading = false;
      _searchGen++;
      notifyListeners();
      return;
    }
    searchLoading = true;
    notifyListeners();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_runSearch(text, reset: true));
    });
  }

  Future<void> loadMoreSearch(String query) =>
      _runSearch(query.trim(), reset: false);

  Future<void> _runSearch(String query, {required bool reset}) async {
    if (api == null || query.length < 2) return;
    if (!reset && (!searchHasMore || searchLoading)) return;
    final gen = reset ? ++_searchGen : _searchGen;
    searchLoading = true;
    if (reset) {
      _searchCursor = '';
      searchHasMore = false;
    }
    notifyListeners();
    try {
      final body = await api!.searchApplications(
        company: query,
        cursor: reset ? '' : _searchCursor,
      );
      if (gen != _searchGen) return;
      final parsed = _jobsFrom(body);
      searchResults = reset ? parsed : [...searchResults, ...parsed];
      _searchCursor = '${body['nextCursor'] ?? ''}';
      searchHasMore = body['hasMore'] == true;
    } catch (err) {
      if (gen != _searchGen) return;
      if (reset) searchResults = [];
      error = _failureMessage(err, 'Could not search companies.');
    }
    if (gen == _searchGen) {
      searchLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJobDetail(AppJob job) async {
    if (api == null || job.id.isEmpty || job.description.isNotEmpty) return;
    detailLoadingJobId = job.id;
    notifyListeners();
    try {
      final body = await api!.applicationJob(job.id);
      final url = '${body['jobUrl'] ?? ''}';
      final description = '${body['description'] ?? ''}';
      for (final row in [...jobs, ...saved, ...byYouJobs, ...searchResults, job]) {
        if (row.id != job.id) continue;
        if (url.isNotEmpty) row.jobUrl = url;
        // Space sentinel = loaded empty so we do not refetch forever.
        row.description = description.isEmpty ? ' ' : description;
      }
      if (job.description.isEmpty) job.description = ' ';
    } catch (err) {
      error = _failureMessage(err, 'Could not load this job.');
    }
    if (detailLoadingJobId == job.id) detailLoadingJobId = null;
    notifyListeners();
  }

  void markResumeDownloaded(String resumeId) {
    if (resumeId.isEmpty) return;
    for (final job in [...jobs, ...saved, ...searchResults]) {
      if (job.resumeId == resumeId) job.showFirstStepBadge = false;
    }
    notifyListeners();
  }

  static const _weekNow = [
    DayPill(weekday: 'Mon', day: '3'),
    DayPill(weekday: 'Tue', day: '4'),
    DayPill(weekday: 'Wed', day: '5'),
    DayPill(weekday: 'Thu', day: '6'),
    DayPill(weekday: 'Fri', day: '7'),
    DayPill(weekday: 'Sat', day: '8', weekend: true),
    DayPill(weekday: 'Sun', day: '9', weekend: true),
    DayPill(weekday: 'Mon', day: '10'),
    DayPill(weekday: 'Tue', day: '11'),
    DayPill(weekday: 'Wed', day: '12'),
    DayPill(weekday: 'Thu', day: '13'),
    DayPill(weekday: 'Fri', day: '14'),
    DayPill(weekday: 'Sat', day: '15', weekend: true),
    DayPill(weekday: 'Sun', day: '16', weekend: true),
  ];

  static const _weekOct = [
    DayPill(weekday: 'Mon', day: '20'),
    DayPill(weekday: 'Tue', day: '21'),
    DayPill(weekday: 'Wed', day: '22'),
    DayPill(weekday: 'Thu', day: '23'),
    DayPill(weekday: 'Fri', day: '24'),
    DayPill(weekday: 'Sat', day: '25', weekend: true),
    DayPill(weekday: 'Sun', day: '26', weekend: true),
    DayPill(weekday: 'Mon', day: '27'),
    DayPill(weekday: 'Tue', day: '28'),
    DayPill(weekday: 'Wed', day: '29'),
    DayPill(weekday: 'Thu', day: '30'),
    DayPill(weekday: 'Fri', day: '31'),
    DayPill(weekday: 'Sat', day: '1', weekend: true),
    DayPill(weekday: 'Sun', day: '2', weekend: true),
  ];

  static const _weekNext = [
    DayPill(weekday: 'Mon', day: '10'),
    DayPill(weekday: 'Tue', day: '11'),
    DayPill(weekday: 'Wed', day: '12'),
    DayPill(weekday: 'Thu', day: '13'),
    DayPill(weekday: 'Fri', day: '14'),
    DayPill(weekday: 'Sat', day: '15', weekend: true),
    DayPill(weekday: 'Sun', day: '16', weekend: true),
    DayPill(weekday: 'Mon', day: '17', start: true),
    DayPill(weekday: 'Tue', day: '18'),
    DayPill(weekday: 'Wed', day: '19'),
    DayPill(weekday: 'Thu', day: '20'),
    DayPill(weekday: 'Fri', day: '21'),
    DayPill(weekday: 'Sat', day: '22', weekend: true),
    DayPill(weekday: 'Sun', day: '23', weekend: true),
  ];

  static final Map<AppsScreenState, AppsContent> _mocks = {
    AppsScreenState.activePremium: AppsContent(
      plan: 'premium',
      showRequests: true,
      counts: const [18, 4, 3],
      monthLabel: 'November 2026',
      days: _weekNow,
      selectedDay: '14',
      daySummaryLabel: 'Today',
      dayCount: 18,
      showReview: true,
    ),
    AppsScreenState.activeElite: AppsContent(
      plan: 'elite',
      showRequests: false,
      counts: const [18, 4, 3],
      monthLabel: 'November 2026',
      days: _weekNow,
      selectedDay: '14',
      daySummaryLabel: 'Today',
      dayCount: 18,
      showReview: true,
    ),
    AppsScreenState.paymentDue: AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: const [18, 4, 3],
      monthLabel: 'November 2026',
      days: _weekNow,
      selectedDay: '14',
      daySummaryLabel: 'Today',
      dayCount: 18,
      showReview: true,
      bannerKind: 'due',
    ),
    AppsScreenState.paused: AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: const [27, 4, 3],
      monthLabel: 'November 2026',
      days: _weekNow,
      selectedDay: '13',
      daySummaryLabel: 'Thu 13 Nov',
      dayCount: 27,
      showReview: false,
      bannerKind: 'pause',
    ),
    AppsScreenState.expired: AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: const [24, 4, 3],
      monthLabel: 'October 2026',
      days: _weekOct,
      selectedDay: '31',
      daySummaryLabel: 'Fri 31 Oct',
      dayCount: 24,
      showReview: false,
      ratingClosed: true,
      bannerKind: 'exp',
    ),
    AppsScreenState.locked: AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: const [0, 0, 0],
      monthLabel: 'November 2026',
      days: _weekNow,
      selectedDay: '14',
      daySummaryLabel: 'Today',
      dayCount: 18,
      showReview: false,
      locked: true,
    ),
    AppsScreenState.startingSoon: AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: const [0, 0, 0],
      monthLabel: 'November 2026',
      days: _weekNext,
      selectedDay: '',
      daySummaryLabel: '',
      dayCount: 0,
      showReview: false,
      startingSoon: true,
    ),
    AppsScreenState.basic: AppsContent(
      plan: 'premium',
      showRequests: false,
      counts: const [0, 0, 0],
      monthLabel: 'November 2026',
      days: _weekNow,
      selectedDay: '14',
      daySummaryLabel: 'Today',
      dayCount: 18,
      showReview: false,
      basicSample: true,
    ),
  };
}
