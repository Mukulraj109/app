import 'home_store.dart';

/// Weekend ribbon when ops (ET) is offline but the phone is already Mon–Fri.
const kTeamOfflineResumesLater =
    'Team offline · resumes later today (US Eastern)';

/// Flutter weekday: Monday=1 … Sunday=7.
bool deviceIsWeekday([DateTime? now]) {
  final day = (now ?? DateTime.now()).weekday;
  return day >= DateTime.monday && day <= DateTime.friday;
}

String? weekendStatusTextForDevice(String? apiLine, {DateTime? now}) {
  if (deviceIsWeekday(now)) return kTeamOfflineResumesLater;
  final line = (apiLine ?? '').trim();
  return line.isEmpty ? null : line;
}

const _knownBrands = [
  'google',
  'amazon',
  'meta',
  'apple',
  'microsoft',
  'nvidia',
  'netflix',
  'stripe',
  'airbnb',
  'uber',
  'capital one',
  'jpmorgan',
  'jp morgan',
  'goldman',
  'citi',
  'bank of america',
  'wells fargo',
  'chase',
  'kaiser',
  'unitedhealth',
  'hospital',
  'aetna',
  'anthem',
  'cigna',
  'insurance',
];

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

int _intOf(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  final match = RegExp(r'\d+').firstMatch('$value');
  return match == null ? 0 : int.parse(match.group(0)!);
}

/// Same labels as web `comingLabels.ts` — keep app/web in sync.
String comingKindLabel(String kind) {
  final key = kind.trim().toLowerCase();
  if (key == 'assessment') return 'Assessment';
  if (key == 'phone screening') return 'Phone screening';
  if (key == 'interview' || key.isEmpty) return 'Interview';
  return kind.trim();
}

/// Formats an ET `YYYY-MM-DD` coming-up date like the web card.
String formatComingWhen(String eventDate, {String? kind, DateTime? now}) {
  final event = eventDate.trim();
  if (event.isEmpty) return 'Date TBC';
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(event)) return event;
  final today = now ?? DateTime.now().toUtc();
  final todayKey =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final days = DateTime.parse('${event}T00:00:00Z')
      .difference(DateTime.parse('${todayKey}T00:00:00Z'))
      .inDays;
  final due = kind?.toLowerCase() == 'assessment';
  if (days == 0) return due ? 'Due today' : 'Today';
  if (days == 1) return due ? 'Due tomorrow' : 'Tomorrow';
  if (days > 1) return due ? 'Due in $days days' : 'In $days days';
  return event;
}

/// Falcon and Falcon Lite have a 999-application plan cap, not a daily target.
bool _isFalconPlan(String planName, Map<String, dynamic> plan) {
  final key = planName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (key == 'falcon' || key == 'falconlite') return true;
  return plan.containsKey('cap') && plan['cap'] != null && _intOf(plan['cap']) == 999;
}

/// Plan applications since start. A missing `used` falls back to the lifetime
/// total so an old cached screen does not show 0. A real 0 stays 0.
int _falconUsed(Map<String, dynamic> plan, int lifetimeTotal) {
  if (!plan.containsKey('used') || plan['used'] == null) return lifetimeTotal;
  return _intOf(plan['used']);
}

String _planLabelFromScreen(Map<String, dynamic> json, Map<String, dynamic> plan) {
  final lite = _map(json['lite']);
  final journey = _map(lite['journey']);
  final planName = '${journey['planName'] ?? ''}'.trim();
  final day = _intOf(plan['day']);
  final total = _intOf(plan['total']);
  final meterLabel = '${plan['label'] ?? ''}'.trim();
  if (plan['paused'] == true) {
    if (planName.isNotEmpty) return '$planName · paused';
    return meterLabel.isNotEmpty ? meterLabel : 'Paused';
  }
  if (planName.isNotEmpty && total > 0) return '$planName · day $day of $total';
  if (planName.isNotEmpty) return planName;
  if (meterLabel.isNotEmpty) return meterLabel;
  if (total > 0) return 'Day $day of $total';
  return 'Your plan';
}

String? _leaveNotice(Map<String, dynamic> leave) {
  if (leave.isEmpty) return null;
  final phase = '${leave['phase']}'.trim();
  if (phase.isEmpty) return null;
  final who = '${leave['aicName']}'.trim();
  final team = who.isEmpty ? 'Your FirstStep team' : who;
  final resume = '${leave['resumeOnLabel'] ?? leave['resumeOn']}'.trim();
  final note = '${leave['note']}'.trim();
  final credit = '${leave['creditLine']}'.trim();
  final seed = RegExp(r'seed(ed)?|dev seed', caseSensitive: false).hasMatch(note);
  final noteBit = (!seed && note.isNotEmpty) ? '$note ' : '';
  if (phase == 'upcoming') {
    final start = '${leave['fromLabel'] ?? leave['from']}'.trim();
    return '$noteBit$team will be on leave${start.isEmpty ? '' : ' starting $start'}.'
        '${resume.isEmpty ? '' : ' Applications resume $resume.'}'
        '${credit.isEmpty ? '' : ' $credit'}'
        .trim();
  }
  if (phase == 'bridge') {
    return '$noteBit$team is still away.'
        '${resume.isEmpty ? '' : ' Applications resume $resume.'}'
        '${credit.isEmpty ? '' : ' $credit'}'
        .trim();
  }
  return '$noteBit$team is on leave.'
      '${resume.isEmpty ? '' : ' Applications resume $resume.'}'
      '${credit.isEmpty ? '' : ' $credit'}'
      .trim();
}

StateBanner? _bannerFromJourney(Map<String, dynamic> journey, String journeyState) {
  final state = (journeyState.isNotEmpty ? journeyState : '${journey['state']}').trim().toLowerCase();
  if (state == 'expired' || state == 'ended') {
    return const StateBanner(
      kind: 'expired',
      title: 'Your plan has ended',
      body: 'Your applications and resumes are still here to view.',
      actions: ['See plans', 'Talk to us'],
    );
  }
  if (state == 'alumni' || journey['alum'] == true) {
    return const StateBanner(
      kind: 'alumni',
      title: 'You got the job — congrats',
      body: 'Your FirstStep history stays available. Refer a friend anytime.',
      actions: ['Refer a friend'],
    );
  }
  return null;
}

SellCard? _sellFromLite(Map<String, dynamic> lite, Map<String, dynamic> journey) {
  final state = '${journey['state']}'.trim().toLowerCase();
  // Match web JourneyHome basic/free sell path — never for active paid journeys.
  if (state != 'basic' && state != 'free') return null;
  final drop = _map(lite['jobDrop']);
  final roles = _list(drop['roles']);
  final chips = <String>[];
  for (final raw in roles) {
    final company = '${_map(raw)['company']}'.trim();
    if (company.isEmpty || chips.contains(company)) continue;
    chips.add(company);
    if (chips.length >= 3) break;
  }
  final hidden = _intOf(drop['hiddenCount']);
  if (hidden > 0) chips.add('+$hidden today');
  return SellCard(
    miniChips: chips.isEmpty ? const ['See today’s jobs'] : chips,
    actions: const ['See plans', 'Book a call'],
  );
}

HeroStatus _heroStatus(String status) {
  if (status == 'applying') return HeroStatus.applying;
  if (status == 'done') return HeroStatus.done;
  return HeroStatus.rest;
}

String? _heroStatusText(String status, String line) {
  final trimmed = line.trim();
  if (status == 'weekend') return weekendStatusTextForDevice(trimmed);
  if (trimmed.isEmpty) return null;
  if (status == 'holiday' ||
      status == 'paused' ||
      status == 'leave' ||
      status == 'leave_bridge' ||
      status == 'leave_upcoming' ||
      status == 'first_day' ||
      status == 'rest') {
    return trimmed;
  }
  return null;
}

/// Maps GET /api/me/home/screen into the mobile Home layout.
/// Field names match web (`kind` / `eventDate` / `lite.journey.planName`).
HomeContent homeContentFromScreen(
  Map<String, dynamic> json, {
  String firstName = '',
}) {
  final sections = _map(json['sections']);
  final tracker = _map(json['tracker']);
  final lite = _map(json['lite']);
  final journey = _map(lite['journey']);
  final ribbon = _map(sections['liveRibbon']);
  final today = _map(sections['today']);
  final engagement = _map(sections['engagement']);
  final support = _map(sections['support']);
  final referrals = _map(sections['referrals']);
  final plan = _map(tracker['plan']).isNotEmpty
      ? _map(tracker['plan'])
      : _map(_map(sections['account'])['plan']);
  final leave = _map(tracker['leave']);
  final stats = _list(sections['stats']);
  final alerts = _list(sections['alerts']);
  final journeyState = '${json['journeyState'] ?? journey['state'] ?? ''}'.trim();

  var applications = 0;
  var hours = 0;
  for (final raw in stats) {
    final stat = _map(raw);
    final key = '${stat['key']}';
    if (key == 'applications') applications = _intOf(stat['value']);
    if (key == 'hours') hours = _intOf(stat['value']);
  }

  final preview = _list(today['preview']);
  final companies = <String>[];
  for (final raw in preview) {
    final company = '${_map(raw)['company']}'.trim();
    if (company.isEmpty || companies.contains(company)) continue;
    companies.add(company);
  }
  final known = companies.where((name) {
    final lower = name.toLowerCase();
    return _knownBrands.any(lower.contains);
  }).toList();
  final shown = (known.isNotEmpty ? known : companies).take(6).toList();

  final activity = _list(json['activityPreview']);
  final count = _intOf(ribbon['count']);
  final status = '${ribbon['status']}';
  final ribbonLine = '${ribbon['line']}'.trim();

  final coming = _list(_map(sections['comingUp'])['rows']);
  UpNextFirst? first;
  final rest = <UpNextItem>[];
  for (final raw in coming) {
    final row = _map(raw);
    // Backend ComingRow: kind, company, title, eventDate (same as web).
    final kind = '${row['kind'] ?? row['responseType'] ?? ''}'.trim();
    final type = comingKindLabel(kind);
    final company = '${row['company'] ?? ''}'.trim();
    final role = '${row['title'] ?? row['jobTitle'] ?? row['role'] ?? ''}'.trim();
    final when = formatComingWhen(
      '${row['eventDate'] ?? row['whenLabel'] ?? ''}',
      kind: kind,
    );
    final title = company.isEmpty
        ? (role.isEmpty ? type : role)
        : (role.isEmpty ? company : '$company · $role');
    if (first == null) {
      first = UpNextFirst(
        type: type,
        when: when,
        title: title,
        sub: '${row['note'] ?? 'From your applications'}',
        primaryLabel: kind.toLowerCase() == 'assessment' ? 'Prep' : 'Open',
      );
    } else {
      rest.add(UpNextItem(
        type: type,
        title: title,
        when: when,
      ));
    }
  }

  final challenge = _map(sections['weeklyChallenge']);
  if ('${challenge['title']}'.isNotEmpty) {
    rest.add(UpNextItem(
      type: 'Weekly task',
      title: '${challenge['title']}',
      when: 'This week',
    ));
  }

  final news = <NewsCard>[];
  for (final raw in _list(engagement['digest'])) {
    final item = _map(raw);
    final title = '${item['title'] ?? item['headline'] ?? ''}'.trim();
    if (title.isEmpty) continue;
    final href = '${item['href'] ?? item['url'] ?? ''}'.trim();
    news.add(NewsCard(
      id: '${item['id'] ?? ''}'.trim(),
      category: '${item['category'] ?? item['topic'] ?? 'News'}',
      pastel: news.length.isEven ? 'sky' : 'mint',
      title: title,
      readTime: '${item['readTime'] ?? '2 min'}',
      body: '${item['excerpt'] ?? item['body'] ?? item['summary'] ?? ''}'.trim(),
      href: href,
    ));
  }

  final partnerName = '${support['aicName'] ?? ''}'.trim();
  final photo = '${support['photo'] ?? ''}'.trim();
  final leaveNotice = _leaveNotice(leave);
  final referralCode = '${referrals['referralCode'] ?? support['referralCode'] ?? ''}'.trim();
  final referralPoints = _intOf(referrals['referralPoints'] ?? support['referralPoints']);
  final showRefer = referralCode.isNotEmpty || referralPoints > 0;

  final banner = _bannerFromJourney(journey, journeyState);
  final sell = banner == null ? _sellFromLite(lite, journey) : null;

  // "How was today's batch?" → Applications review when AIC is actively applying.
  final showFeedback =
      (status == 'applying' || status == 'done') && count > 0;

  // Prefer live ribbon for active states; alerts feed partner/banner elsewhere.
  final alertTitles = alerts
      .map((raw) => '${_map(raw)['title']}'.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  ProofStats? proofStats;
  if (stats.isNotEmpty) {
    final values = <String>[];
    final captions = <String>[];
    for (final raw in stats) {
      final stat = _map(raw);
      final label = '${stat['label'] ?? stat['key'] ?? ''}'.trim();
      final value = '${stat['value'] ?? ''}'.trim();
      if (value.isEmpty && label.isEmpty) continue;
      values.add(value.isEmpty ? '—' : value);
      captions.add(label.isEmpty ? 'Stat' : label);
    }
    if (values.isNotEmpty) {
      proofStats = ProofStats(values: values, captions: captions);
    }
  }

  final jobDrop = _map(lite['jobDrop']);
  final newJobs = <JobTeaser>[];
  for (final raw in _list(jobDrop['roles'])) {
    final role = _map(raw);
    final title = '${role['title'] ?? role['jobTitle'] ?? ''}'.trim();
    if (title.isEmpty) continue;
    final company = '${role['company'] ?? ''}'.trim();
    final location = '${role['location'] ?? ''}'.trim();
    final seed = company.isNotEmpty ? company : title;
    final letter = seed.isEmpty ? '?' : seed[0].toUpperCase();
    newJobs.add(JobTeaser(
      letter: letter,
      title: title,
      meta: [
        if (company.isNotEmpty) company,
        if (location.isNotEmpty) location,
      ].join(' · '),
      pastel: newJobs.length.isEven ? 'lavender' : 'sky',
    ));
    if (newJobs.length >= 6) break;
  }

  final planName = '${journey['planName'] ?? ''}'.trim();
  final falcon = _isFalconPlan(planName, plan);
  final heroValue = falcon ? _falconUsed(plan, applications) : count;
  final cap = _intOf(plan['cap']);
  final heroMax = falcon
      ? (cap > 0 ? cap : 999)
      : (count == 0 ? null : (count < 30 ? 30 : count));
  final heroLabel = falcon
      ? 'applications in your plan'
      : (status == 'done' || status == 'applying' ? 'applications today' : 'applications');

  return HomeContent(
    firstName: firstName.trim().isEmpty ? 'there' : firstName.trim().split(' ').first,
    planLabel: _planLabelFromScreen(json, plan),
    hero: HeroSpec(
      value: heroValue,
      max: heroMax,
      status: _heroStatus(status),
      statusText: _heroStatusText(status, ribbonLine),
      companies: shown,
      label: heroLabel,
      sub: shown.isEmpty
          ? (alertTitles.isEmpty ? null : alertTitles.first)
          : 'Latest: ${shown.take(3).join(' · ')}',
      muted: status == 'weekend' || status == 'holiday' || status == 'paused',
    ),
    quietTotal: applications,
    quietHours: hours,
    showBusy: activity.isNotEmpty,
    busyText: activity.isEmpty
        ? ''
        : 'While you were away we logged ${activity.length} update${activity.length == 1 ? '' : 's'}',
    showFeedback: showFeedback,
    upNextFirst: first,
    upNextRest: rest,
    showDiscover: news.isNotEmpty,
    liveNews: true,
    news: news,
    banner: banner,
    sell: sell,
    proofStats: proofStats,
    newJobs: newJobs,
    showRefer: showRefer,
    partner: PartnerInfo(
      name: partnerName.isEmpty ? null : partnerName,
      hasWhatsApp: '${support['whatsappGroupUrl'] ?? ''}'.isNotEmpty,
      photoUrl: photo.isEmpty ? null : photo,
      leaveNotice: leaveNotice,
    ),
  );
}

HomeActions homeActionsFromScreen(Map<String, dynamic> json) {
  Map<String, dynamic> map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  final sections = map(json['sections']);
  final tracker = map(json['tracker']);
  final engagement = map(sections['engagement']);
  final celebration = map(tracker['celebration']).isNotEmpty
      ? map(tracker['celebration'])
      : (map(engagement['celebration']).isNotEmpty
          ? map(engagement['celebration'])
          : map(sections['celebration']));
  final nudge = map(tracker['nudge']).isNotEmpty
      ? map(tracker['nudge'])
      : (map(engagement['nudge']).isNotEmpty
          ? map(engagement['nudge'])
          : map(sections['nudge']));

  // Backend puts interview follow-ups in tracker.tasks / engagement.tasks
  // as {id, type: 'interview_followup', title}, not sections.followup.
  Map<String, dynamic> followup = map(sections['followup']);
  if (followup.isEmpty) followup = map(sections['task']);
  if (followup.isEmpty) {
    final pools = <dynamic>[
      ...((tracker['tasks'] is List) ? tracker['tasks'] as List : const []),
      ...((engagement['tasks'] is List) ? engagement['tasks'] as List : const []),
    ];
    for (final item in pools.whereType<Map>()) {
      final row = Map<String, dynamic>.from(item);
      final type = '${row['type'] ?? row['task_type'] ?? ''}'.toLowerCase();
      if (type.contains('followup') || type.contains('follow_up')) {
        followup = row;
        break;
      }
    }
    if (followup.isEmpty && pools.isNotEmpty && pools.first is Map) {
      followup = Map<String, dynamic>.from(pools.first as Map);
    }
  }

  return HomeActions(
    milestoneId: '${celebration['id'] ?? ''}'.trim(),
    milestoneTitle:
        '${celebration['title'] ?? celebration['line'] ?? celebration['label'] ?? 'Milestone'}'
            .trim(),
    nudgeId: '${nudge['_id'] ?? nudge['id'] ?? ''}'.trim(),
    nudgeTitle: '${nudge['title'] ?? nudge['prompt'] ?? 'How was that?'}'.trim(),
    followupId: '${followup['taskId'] ?? followup['id'] ?? ''}'.trim(),
    followupTitle:
        '${followup['title'] ?? followup['prompt'] ?? followup['description'] ?? 'Follow up'}'
            .trim(),
  );
}
