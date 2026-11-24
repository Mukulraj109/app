import 'package:flutter/foundation.dart';

/// Dev switcher states for Home. The 8 states from 02-homev2.html.
enum HomeScreenState {
  applying,
  done,
  weekend,
  falcon,
  gettingReady,
  basic,
  expired,
  alumni,
}

/// Hero status, per the HTML spec (never show times).
enum HeroStatus { applying, done, rest }

/// Hero arc data, honest ("18 / 25").
class HeroSpec {
  final int value;
  final int from; // count-up starts here, not 0
  final int? max; // null = no "/max" shown
  final String? unit; // e.g. '%'
  final HeroStatus status;
  final String? statusText; // rest / weekend label
  final List<String> companies;
  final String label;
  final String? sub; // done-state "Last: …" line
  final bool muted; // weekend rest arc: filled pills in calm grey

  const HeroSpec({
    required this.value,
    this.from = 0,
    this.max,
    this.unit,
    this.status = HeroStatus.rest,
    this.statusText,
    this.companies = const [],
    this.label = '',
    this.sub,
    this.muted = false,
  });

  /// Number of lit segments for the 12-segment arc.
  int get filledSegments =>
      max == null || max == 0
          ? 0
          : (value.toDouble() / max! * 12).round().clamp(0, 12);
}

/// One "Up next" item (interviews always first).
class UpNextItem {
  final String type; // Interview / Assessment / Weekly task / To do / Done
  final String? when;
  final String title;
  final String? sub;
  final bool done;

  const UpNextItem({
    required this.type,
    required this.title,
    this.when,
    this.sub,
    this.done = false,
  });
}

/// The big first "Up next" card.
class UpNextFirst {
  final String type;
  final String when;
  final String title;
  final String sub;
  final String primaryLabel; // "Prep 15 min" / "Start" …
  final String? secondaryLabel;

  const UpNextFirst({
    required this.type,
    required this.when,
    required this.title,
    required this.sub,
    required this.primaryLabel,
    this.secondaryLabel,
  });
}

/// Application partner ("never show AIC/In-Charge").
class PartnerInfo {
  final String? name; // null = "Your FirstStep team"
  final bool hasWhatsApp;
  final String? leaveNotice;
  final String? photoUrl;

  const PartnerInfo({
    this.name,
    this.hasWhatsApp = false,
    this.leaveNotice,
    this.photoUrl,
  });

  String get firstName => name?.split(' ').first ?? '';
}

/// Basic-plan "Let our team apply for you" card.
class SellCard {
  final List<String> miniChips;
  final List<String> actions;

  const SellCard({required this.miniChips, required this.actions});
}

/// Proof stats tiles (placeholders until sourced — README open item).
class ProofStats {
  final List<String> values;
  final List<String> captions;

  const ProofStats({required this.values, required this.captions});
}

/// A new-jobs teaser row.
class JobTeaser {
  final String letter;
  final String title;
  final String meta;
  final String pastel; // token name: 'lavender' | 'sky'

  const JobTeaser({
    required this.letter,
    required this.title,
    required this.meta,
    this.pastel = 'lavender',
  });
}

/// Discover news card.
/// Callers: news_pages, home_live, focus_home_view. Schema: id/title/href/saved
/// from GET /api/me/discover. User: "start fixing... android ready".
class NewsCard {
  final String id;
  final String category;
  final String pastel;
  final String title;
  final String readTime;
  final String body;
  final String href;
  final bool unavailable;
  final bool saved;

  const NewsCard({
    this.id = '',
    required this.category,
    required this.pastel,
    required this.title,
    required this.readTime,
    this.body = '',
    this.href = '',
    this.unavailable = false,
    this.saved = false,
  });

  NewsCard copyWith({bool? saved, String? href}) {
    return NewsCard(
      id: id,
      category: category,
      pastel: pastel,
      title: title,
      readTime: readTime,
      body: body,
      href: href ?? this.href,
      unavailable: unavailable,
      saved: saved ?? this.saved,
    );
  }
}

/// State banner (expired / alumni / none).
class StateBanner {
  final String kind; // 'expired' | 'alumni'
  final String title;
  final String body;
  final List<String> actions;

  const StateBanner({
    required this.kind,
    required this.title,
    required this.body,
    this.actions = const [],
  });
}

/// Everything Home renders, per state.
class HomeContent {
  final String firstName;
  final String planLabel; // top-bar sub line
  final HeroSpec? hero;
  final int quietTotal;
  final int quietHours;
  final bool showBusy;
  final String busyText;
  final bool showFeedback;
  final UpNextFirst? upNextFirst;
  final String upNextTitle;
  final List<UpNextItem> upNextRest;
  final bool showDiscover;
  final PartnerInfo? partner;
  final StateBanner? banner;
  final SellCard? sell;
  final ProofStats? proofStats;
  final List<JobTeaser> newJobs;
  final bool showRefer;
  final List<NewsCard> news;
  final bool liveNews;

  const HomeContent({
    required this.firstName,
    required this.planLabel,
    this.hero,
    this.quietTotal = 0,
    this.quietHours = 0,
    this.showBusy = false,
    this.busyText = '',
    this.showFeedback = false,
    this.upNextFirst,
    this.upNextTitle = 'Up next',
    this.upNextRest = const [],
    this.showDiscover = false,
    this.partner,
    this.banner,
    this.sell,
    this.proofStats,
    this.newJobs = const [],
    this.showRefer = false,
    this.news = const [],
    this.liveNews = false,
  });
}

class HomeActions {
  final String milestoneId;
  final String milestoneTitle;
  final String nudgeId;
  final String nudgeTitle;
  final String followupId;
  final String followupTitle;

  const HomeActions({
    this.milestoneId = '',
    this.milestoneTitle = '',
    this.nudgeId = '',
    this.nudgeTitle = '',
    this.followupId = '',
    this.followupTitle = '',
  });

  bool get hasAny =>
      milestoneId.isNotEmpty || nudgeId.isNotEmpty || followupId.isNotEmpty;

  HomeActions copyWith({
    String? milestoneId,
    String? milestoneTitle,
    String? nudgeId,
    String? nudgeTitle,
    String? followupId,
    String? followupTitle,
  }) {
    return HomeActions(
      milestoneId: milestoneId ?? this.milestoneId,
      milestoneTitle: milestoneTitle ?? this.milestoneTitle,
      nudgeId: nudgeId ?? this.nudgeId,
      nudgeTitle: nudgeTitle ?? this.nudgeTitle,
      followupId: followupId ?? this.followupId,
      followupTitle: followupTitle ?? this.followupTitle,
    );
  }
}

class HomeStore extends ChangeNotifier {
  HomeScreenState state;
  HomeContent content;
  bool live = false;
  bool loadFailed = false;
  bool awaitingLive;
  HomeActions actions = const HomeActions();

  HomeStore({
    this.state = HomeScreenState.applying,
    HomeContent? content,
    this.awaitingLive = false,
  }) : content = content ??
            (awaitingLive
                ? const HomeContent(firstName: '', planLabel: '')
                : mocks[HomeScreenState.applying]!);

  set stateContent(HomeContent value) => content = value;

  void showLoadFailed() {
    awaitingLive = false;
    // Stale-while-revalidate: a failed poll must not wipe a screen we already painted.
    if (live) {
      notifyListeners();
      return;
    }
    loadFailed = true;
    live = false;
    notifyListeners();
  }

  void setState(HomeScreenState next) {
    if (next == state && !live) return;
    live = false;
    state = next;
    content = mocks[next]!;
    notifyListeners();
  }

  void showLive(HomeContent next, {HomeActions? actions}) {
    loadFailed = false;
    awaitingLive = false;
    if (actions != null) this.actions = actions;
    content = next;
    live = true;
    notifyListeners();
  }

  void updateActions(HomeActions next) {
    actions = next;
    notifyListeners();
  }

  /// HTML-matched sample data (Sai · Premium · Day 12 of 30 · Priya).
  static const Map<HomeScreenState, HomeContent> mocks = {
    HomeScreenState.applying: HomeContent(
      firstName: 'Sai',
      planLabel: 'Premium · Day 12 of 30',
      hero: HeroSpec(
        value: 9,
        from: 6,
        max: 30,
        status: HeroStatus.applying,
        companies: ['Stripe', 'Capital One', 'Airbnb', 'Notion', 'Datadog'],
        label: 'applications today',
      ),
      quietTotal: 412,
      quietHours: 41,
      showBusy: true,
      busyText: '6 new applications · 1 interview added',
      upNextFirst: UpNextFirst(
        type: 'Interview',
        when: 'Tomorrow',
        title: 'Amazon · Data Engineer II',
        sub: 'Video interview with the hiring team',
        primaryLabel: 'Prep 15 min',
        secondaryLabel: 'Details',
      ),
      upNextRest: [
        UpNextItem(
          type: 'Assessment',
          title: 'HackerRank · Capital One',
          sub: 'SQL + Python',
          when: 'Due Fri',
        ),
        UpNextItem(
          type: 'Weekly task',
          title: 'Record your 60-second pitch',
          sub: 'Data Engineer',
          when: 'This week',
        ),
      ],
      showDiscover: true,
      partner: const PartnerInfo(name: 'Priya', hasWhatsApp: true),
    ),
    HomeScreenState.done: HomeContent(
      firstName: 'Sai',
      planLabel: 'Premium · Day 12 of 30',
      hero: const HeroSpec(
        value: 27,
        from: 20,
        max: 30,
        status: HeroStatus.done,
        label: 'applications today',
        sub: 'Last: Datadog · Notion · Airbnb',
      ),
      quietTotal: 430,
      quietHours: 43,
      showFeedback: true,
      upNextFirst: UpNextFirst(
        type: 'Interview',
        when: 'Tomorrow',
        title: 'Amazon · Data Engineer II',
        sub: 'Video interview with the hiring team',
        primaryLabel: 'Prep 15 min',
        secondaryLabel: 'Details',
      ),
      upNextRest: [
        UpNextItem(
          type: 'Weekly task',
          title: 'Record your 60-second pitch',
          sub: 'Data Engineer',
          when: 'This week',
        ),
      ],
      showDiscover: true,
      partner: const PartnerInfo(
        name: 'Priya',
        hasWhatsApp: true,
        leaveNotice:
            'Priya is off Thu–Fri. Arjun is covering, so your '
            'applications continue as usual.',
      ),
    ),
    HomeScreenState.weekend: HomeContent(
      firstName: 'Sai',
      planLabel: 'Premium · Day 14 of 30',
      hero: const HeroSpec(
        value: 128,
        from: 100,
        max: 150,
        status: HeroStatus.rest,
        statusText: 'Rest day · back Monday',
        label: 'applications this week',
        muted: true,
      ),
      quietTotal: 430,
      quietHours: 43,
      upNextFirst: UpNextFirst(
        type: 'Weekly task',
        when: 'Due Sun',
        title: 'Record your 60-second pitch',
        sub: 'A good weekend task · 10 minutes',
        primaryLabel: 'Start',
        secondaryLabel: 'Later',
      ),
      upNextRest: [
        const UpNextItem(
          type: 'Interview',
          title: 'Amazon · Data Engineer II',
          sub: 'Video',
          when: 'Mon',
        ),
      ],
      showDiscover: true,
      partner: const PartnerInfo(name: 'Priya', hasWhatsApp: true),
    ),
    HomeScreenState.falcon: HomeContent(
      firstName: 'Sai',
      planLabel: 'Falcon Lite · Day 41 of 100',
      hero: const HeroSpec(
        value: 412,
        from: 404,
        max: 999,
        status: HeroStatus.applying,
        companies: ['Stripe', 'Capital One', 'Airbnb'],
        label: 'applications in your plan',
      ),
      quietTotal: 412,
      quietHours: 41,
      upNextRest: [
        UpNextItem(
          type: 'Assessment',
          title: 'Codility · Stripe',
          sub: 'Data structures',
          when: 'Due Mon',
        ),
        UpNextItem(
          type: 'Weekly task',
          title: 'Update your LinkedIn headline',
          sub: '5 minutes',
          when: 'This week',
        ),
      ],
      showDiscover: true,
      // Falcon Lite: no WhatsApp group — team, never the AIC name.
      partner: const PartnerInfo(),
    ),
    HomeScreenState.gettingReady: HomeContent(
      firstName: 'Sai',
      planLabel: 'Premium · starts Mon 17 Nov',
      hero: const HeroSpec(
        value: 2,
        max: 4,
        status: HeroStatus.rest,
        statusText: 'Getting ready',
        label: 'setup steps done',
        sub: 'Your AIC starts Mon 17 Nov',
      ),
      upNextTitle: 'Get set up',
      upNextFirst: const UpNextFirst(
        type: 'To do',
        when: 'Needed to start',
        title: 'Fill your intake form',
        sub: 'About 8 minutes · tells your AIC what to apply for',
        primaryLabel: 'Start',
      ),
      upNextRest: [
        UpNextItem(
          type: 'To do',
          title: 'Join WhatsApp updates',
          sub: 'Required for interview alerts',
          when: '1 min',
        ),
        const UpNextItem(type: 'Done', title: 'Upload your resume', done: true),
        const UpNextItem(
          type: 'Done',
          title: 'Choose job categories',
          done: true,
        ),
      ],
      showDiscover: true,
      partner: const PartnerInfo(name: 'Priya', hasWhatsApp: true),
    ),
    HomeScreenState.basic: HomeContent(
      firstName: 'Sai',
      planLabel: 'Basic',
      hero: HeroSpec(
        value: 60,
        unit: '%',
        status: HeroStatus.rest,
        statusText: 'Job-ready score',
        label: 'Next: take the SQL skill check',
      ),
      upNextFirst: UpNextFirst(
        type: 'Weekly task',
        when: 'This week',
        title: 'Take the SQL skill check',
        sub: '10 minutes · Earn your first badge',
        primaryLabel: 'Start',
        secondaryLabel: 'Later',
      ),
      upNextRest: [
        UpNextItem(
          type: 'To do',
          title: 'Upload your resume',
          sub: '+20% job-ready',
        ),
        UpNextItem(
          type: 'Weekly task',
          title: 'Question of the day',
          sub: 'Data Engineer · 2 min',
        ),
        UpNextItem(
          type: 'Weekly task',
          title: 'Practice interview (MCQ)',
          sub: '15 questions',
        ),
      ],
      showDiscover: true,
      proofStats: const ProofStats(
        values: ['127', '15M+', '70'],
        captions: [
          'clients placed in 2026',
          'offers in 2026',
          'AICs applying every weekday',
        ],
      ),
      sell: const SellCard(
        miniChips: ['Stripe', 'Capital One', 'Airbnb', '+15 today'],
        actions: ['See plans', 'Book a call'],
      ),
      newJobs: const [
        JobTeaser(letter: 'R', title: 'Senior Data Engineer', meta: 'Rivian · Austin, TX'),
        JobTeaser(letter: 'D', title: 'Data Engineer', meta: 'Datadog · Remote', pastel: 'sky'),
      ],
      showRefer: true,
    ),
    HomeScreenState.expired: HomeContent(
      firstName: 'Sai',
      planLabel: 'Basic · plan ended 2 Nov',
      hero: const HeroSpec(
        value: 80,
        unit: '%',
        status: HeroStatus.rest,
        statusText: 'Job-ready score',
        label: 'Next: take the SQL skill check',
      ),
      banner: const StateBanner(
        kind: 'expired',
        title: 'Your plan ended on 2 Nov',
        body: 'Your 412 applications and resumes are still here to view.',
        actions: ['Renew', 'Refer a friend'],
      ),
      upNextFirst: const UpNextFirst(
        type: 'Weekly task',
        when: 'This week',
        title: 'Take the SQL skill check',
        sub: '10 minutes · Earn your first badge',
        primaryLabel: 'Start',
        secondaryLabel: 'Later',
      ),
      upNextRest: const [
        UpNextItem(
          type: 'To do',
          title: 'Upload your resume',
          sub: '+20% job-ready',
        ),
        UpNextItem(
          type: 'Weekly task',
          title: 'Question of the day',
          sub: 'Data Engineer · 2 min',
        ),
        UpNextItem(
          type: 'Weekly task',
          title: 'Practice interview (MCQ)',
          sub: '15 questions',
        ),
      ],
      newJobs: const [
        JobTeaser(letter: 'R', title: 'Senior Data Engineer', meta: 'Rivian · Austin, TX'),
      ],
      showDiscover: true,
      showRefer: true,
    ),
    HomeScreenState.alumni: HomeContent(
      firstName: 'Sai',
      planLabel: 'Alumni',
      hero: const HeroSpec(
        value: 612,
        status: HeroStatus.rest,
        statusText: 'Your FirstStep journey',
        label: 'applications sent for you',
        sub: '4 interviews · 1 offer',
      ),
      banner: const StateBanner(
        kind: 'alumni',
        title: 'Congrats on your offer 🎉',
        body: 'You have 14 days saved until 3 Mar. '
            'Restart anytime if you need us again.',
        actions: ['Refer a friend', 'Restart'],
      ),
      showDiscover: true,
      showRefer: true,
    ),
  };
}

/// Fixed sample news, Immigration first (HTML spec).
const List<NewsCard> sampleNews = [
  NewsCard(
    category: 'Immigration',
    pastel: 'sky',
    title: 'H-1B registration 2027: key dates and what to prepare',
    readTime: '4 min read',
  ),
  NewsCard(
    category: 'AI',
    pastel: 'lavender',
    title: 'How recruiters now use AI to screen resumes',
    readTime: '3 min read',
  ),
  NewsCard(
    category: 'Industry',
    pastel: 'mint',
    title: 'Fintech hiring picked up again this month',
    readTime: '2 min read',
  ),
];

/// The five bottom-nav tabs, Home in the middle (README decision: Home in
/// center, Learn replaces the old Inbox slot).
class HomeTab {
  final int index;
  final String label;
  const HomeTab(this.index, this.label);
}

const List<HomeTab> homeTabs = [
  HomeTab(0, 'Learn'),
  HomeTab(1, 'Applications'),

  HomeTab(2, 'Home'),
  HomeTab(3, 'ScoutX'),
  HomeTab(4, 'Profile'),
];

