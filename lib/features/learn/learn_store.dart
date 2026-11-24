import 'package:flutter/foundation.dart';

import 'badge_catalog.dart';

/// Dev states for Learn, matching 05-learn.html.
enum LearnScreenState { premium, elite, basic }

class LearnContent {
  final String plan; // premium | elite | basic
  final bool hasRole;
  final String? role;
  final bool hasInterview;
  final int streak;
  final int badges;
  final int weekDone; // of 3

  const LearnContent({
    required this.plan,
    required this.hasRole,
    this.role,
    required this.hasInterview,
    required this.streak,
    required this.badges,
    required this.weekDone,
  });

  bool get isPremium =>
      plan == 'premium' ||
      plan == 'Premium' ||
      plan == 'PremiumPlus' ||
      plan == 'Premium Plan';
}

class InterviewStory {
  final String company;
  final String role;
  final String round;
  final String outcome;
  final String by;
  final String meta;
  final String when;
  final String pastel; // lav | mint | but | sky | pch
  final String excerpt;
  final List<String> questions;
  final String how;
  final String tip;

  const InterviewStory({
    required this.company,
    required this.role,
    required this.round,
    required this.outcome,
    required this.by,
    required this.meta,
    required this.when,
    required this.pastel,
    required this.excerpt,
    this.questions = const [],
    this.how = '',
    this.tip = '',
  });
}

class LearnBadge {
  final String shape; // notch | orb | chevron | split
  final String color; // lav | mint | but | sky | pch
  final String glyph;
  final String name;
  final String how;
  final bool earned;

  const LearnBadge({
    required this.shape,
    required this.color,
    this.glyph = '',
    required this.name,
    required this.how,
    required this.earned,
  });
}

class LearnStore extends ChangeNotifier {
  LearnScreenState state;
  LearnContent content;
  bool qodAnswered = false;
  int? qodPicked;
  bool? qodWasCorrect;
  String qodExplanation = '';

  LearnStore({this.state = LearnScreenState.premium, bool signedIn = false})
      : content = signedIn
            ? const LearnContent(
                plan: 'basic',
                hasRole: false,
                hasInterview: false,
                streak: 0,
                badges: 0,
                weekDone: 0,
              )
            : mocks[LearnScreenState.premium]!;

  void setState(LearnScreenState next) {
    if (next == state) return;
    state = next;
    content = mocks[next]!;
    qodAnswered = false;
    qodPicked = null;
    qodWasCorrect = null;
    qodExplanation = '';
    usingLive = false;
    notifyListeners();
  }

  void answerQod(int index, {bool? correct, String explanation = '', int? streak}) {
    if (qodAnswered) return;
    qodAnswered = true;
    qodPicked = index;
    qodWasCorrect = correct;
    qodExplanation = explanation;
    if (streak != null) {
      content = LearnContent(
        plan: content.plan,
        hasRole: content.hasRole,
        role: content.role,
        hasInterview: content.hasInterview,
        streak: streak,
        badges: content.badges,
        weekDone: content.weekDone,
      );
    }
    notifyListeners();
  }

  bool usingLive = false;
  String liveQuestion = '';
  String liveQuestionId = '';
  List<String> liveOptions = const [];
  String questionTechStack = '';
  String topicTitle = '';
  String topicBody = '';
  String topicCategory = '';
  String topicDate = '';
  String weekKey = '';
  String pitchPrompt = 'Record a 60-second elevator pitch for your target role.';
  bool pitchDone = false;
  List<InterviewStory> liveStories = const [];
  List<LearnBadge> liveBadges = const [];
  int weekDoneCount = 0;
  int weekTotal = 10;
  String prepTitle = '';
  bool loadFailed = false;
  List<Map<String, dynamic>> skillChecks = const [];
  int topicsRead = 0;
  static const int topicsTarget = 3;

  void markTopicRead() {
    if (topicsRead >= topicsTarget) {
      notifyListeners();
      return;
    }
    topicsRead += 1;
    notifyListeners();
  }

  bool get topicsDone => topicsRead >= topicsTarget;

  void applyWeek(Map<String, dynamic> json, {bool notify = true}) {
    final question = json['question'];
    var questionStreak = 0;
    if (question is Map) {
      liveQuestionId = '${question['id'] ?? ''}';
      liveQuestion = '${question['question'] ?? ''}';
      questionTechStack = '${question['techStack'] ?? question['category'] ?? ''}'.trim();
      final options = question['options'];
      if (options is Map) {
        liveOptions = ['A', 'B', 'C', 'D']
            .map((key) => '${options[key] ?? ''}')
            .where((value) => value.isNotEmpty)
            .toList();
      } else {
        liveOptions = const [];
      }
      qodAnswered = question['answered'] == true;
      questionStreak = int.tryParse('${question['streak'] ?? ''}') ?? 0;
    } else {
      liveQuestionId = '';
      liveQuestion = '';
      liveOptions = const [];
      questionTechStack = '';
      qodAnswered = false;
    }
    final topic = json['topic'];
    if (topic is Map) {
      topicTitle = '${topic['title'] ?? ''}';
      topicBody = '${topic['body'] ?? ''}';
      topicCategory = '${topic['category'] ?? ''}';
      topicDate = '${topic['date'] ?? ''}';
    } else {
      topicTitle = '';
      topicBody = '';
      topicCategory = '';
      topicDate = '';
    }
    final pitch = json['pitch'];
    if (pitch is Map) {
      weekKey = '${json['weekKey'] ?? pitch['weekKey'] ?? weekKey}';
      final prompt = '${pitch['prompt'] ?? ''}';
      if (prompt.isNotEmpty) pitchPrompt = prompt;
      pitchDone = pitch['done'] == true;
    } else {
      weekKey = '${json['weekKey'] ?? weekKey}';
      pitchDone = false;
    }
    final challenge = json['challenge'];
    if (!pitchDone && challenge is Map) {
      pitchDone = '${challenge['status'] ?? ''}' == 'done';
    }
    final stories = json['stories'];
    if (stories is List) {
      liveStories = stories.whereType<Map>().map((raw) {
        final row = Map<String, dynamic>.from(raw);
        final questions = row['questions'];
        return InterviewStory(
          company: '${row['company'] ?? ''}',
          role: '${row['role'] ?? ''}',
          round: '${row['round'] ?? ''}',
          outcome: '${row['outcome'] ?? ''}',
          by: '${row['by'] ?? ''}',
          meta: '${row['meta'] ?? ''}',
          when: '${row['when'] ?? ''}',
          pastel: '${row['pastel'] ?? 'sky'}',
          excerpt: '${row['excerpt'] ?? ''}',
          questions: questions is List ? questions.map((item) => '$item').toList() : const [],
          how: '${row['how'] ?? ''}',
          tip: '${row['tip'] ?? ''}',
        );
      }).toList();
    }
    final badges = json['badges'];
    if (badges is List) {
      liveBadges = badges
          .whereType<Map>()
          .map((raw) => learnBadgeFromJson(Map<String, dynamic>.from(raw)))
          .toList();
    }
    final mcq = json['weeklyMcq'];
    var done = 0;
    var total = 10;
    if (mcq is Map) {
      total = int.tryParse('${mcq['total'] ?? mcq['count'] ?? 10}') ?? 10;
      if (total <= 0) total = 10;
      if (mcq['done'] == true) {
        done = total;
      } else {
        done = int.tryParse('${mcq['answered'] ?? mcq['completed'] ?? 0}') ?? 0;
        if (done <= 0 && mcq['started'] == true) {
          done = 0;
        }
      }
    }
    weekDoneCount = done;
    weekTotal = total;

    final roles = json['roles'];
    var role = '${json['role'] ?? ''}'.trim();
    if (role.isEmpty && roles is List && roles.isNotEmpty) {
      role = '${roles.first}'.trim();
    }

    final streak = int.tryParse('${json['streak'] ?? ''}') ?? questionStreak;

    final interview = json['upcomingInterview'] ?? json['interview'];
    var prep = '';
    if (interview is Map) {
      final title = '${interview['title'] ?? ''}'.trim();
      final company = '${interview['company'] ?? ''}'.trim();
      final label = '${interview['label'] ?? ''}'.trim();
      if (title.contains('·') || title.contains(company) || company.isEmpty) {
        prep = title.isNotEmpty ? title : (label.isNotEmpty ? label : company);
      } else if (title.isNotEmpty && company.isNotEmpty) {
        prep = '$company · $title';
      } else {
        prep = title.isNotEmpty ? title : (company.isNotEmpty ? company : label);
      }
    } else if (interview is String) {
      prep = interview.trim();
    }
    prepTitle = prep;

    final planRaw = '${json['plan'] ?? content.plan}'.trim();
    final plan = _normalizePlan(planRaw);

    final earned = liveBadges.where((badge) => badge.earned).length;
    content = LearnContent(
      plan: plan,
      hasRole: role.isNotEmpty,
      role: role.isEmpty ? null : role,
      hasInterview: prep.isNotEmpty,
      streak: streak,
      badges: earned,
      weekDone: done,
    );
    usingLive = true;
    loadFailed = false;
    if (notify) notifyListeners();
  }

  static String _normalizePlan(String raw) {
    final lower = raw.toLowerCase();
    if (lower == 'premium' ||
        lower == 'premiumplus' ||
        lower == 'premium plus' ||
        lower == 'premium plan') {
      return 'premium';
    }
    if (lower == 'elite' ||
        lower == 'falcon' ||
        lower == 'falconlite' ||
        lower == 'essentials') {
      return 'elite';
    }
    if (lower == 'basic' || lower == 'normal plan' || lower.isEmpty) {
      return 'basic';
    }
    return lower;
  }

  void setSkillChecks(List<Map<String, dynamic>> checks, {bool notify = true}) {
    skillChecks = checks;
    if (notify) notifyListeners();
  }

  void setStories(List<InterviewStory> stories, {bool notify = true}) {
    liveStories = stories;
    if (notify) notifyListeners();
  }

  /// Applies week + optional side loads with a single rebuild.
  void applyLiveBatch({
    required Map<String, dynamic> week,
    List<Map<String, dynamic>>? skillChecks,
    List<InterviewStory>? stories,
  }) {
    applyWeek(week, notify: false);
    if (skillChecks != null) setSkillChecks(skillChecks, notify: false);
    if (stories != null && stories.isNotEmpty && liveStories.isEmpty) {
      setStories(stories, notify: false);
    }
    notifyListeners();
  }

  void markLoadFailed() {
    if (usingLive) {
      notifyListeners();
      return;
    }
    loadFailed = true;
    usingLive = false;
    liveQuestion = '';
    liveQuestionId = '';
    liveOptions = const [];
    topicTitle = '';
    topicBody = '';
    liveStories = const [];
    liveBadges = const [];
    skillChecks = const [];
    content = const LearnContent(
      plan: 'basic',
      hasRole: false,
      hasInterview: false,
      streak: 0,
      badges: 0,
      weekDone: 0,
    );
    notifyListeners();
  }

  static const Map<LearnScreenState, LearnContent> mocks = {
    LearnScreenState.premium: LearnContent(
      plan: 'premium',
      hasRole: true,
      role: 'Data Engineer',
      hasInterview: true,
      streak: 7,
      badges: 3,
      weekDone: 2,
    ),
    LearnScreenState.elite: LearnContent(
      plan: 'elite',
      hasRole: true,
      role: 'Data Engineer',
      hasInterview: false,
      streak: 3,
      badges: 1,
      weekDone: 1,
    ),
    LearnScreenState.basic: LearnContent(
      plan: 'basic',
      hasRole: false,
      hasInterview: false,
      streak: 0,
      badges: 0,
      weekDone: 0,
    ),
  };
}

const List<InterviewStory> sampleStories = [
  InterviewStory(
    company: 'Amazon',
    role: 'Data Engineer II',
    round: 'Technical',
    outcome: 'Offer',
    by: 'Priya',
    meta: 'Data Engineer · 4 yrs',
    when: 'Nov 2026',
    pastel: 'but',
    excerpt:
        'Two SQL questions, then design a pipeline for clickstream data. They cared a lot about how I handle late events.',
    questions: [
      'Find the second highest salary per department (SQL)',
      'Design a pipeline that ingests clickstream data in near real time',
      'How would you handle late-arriving events?',
      'Tell me about a time you disagreed with your manager',
    ],
    how:
        'Four rounds in one day. The system design round went deepest; they pushed on cost and failure handling.',
    tip:
        'Practise talking through trade-offs out loud. They wanted reasoning, not a perfect answer.',
  ),
  InterviewStory(
    company: 'Capital One',
    role: 'Data Engineer',
    round: 'Phone screen',
    outcome: 'Waiting',
    by: 'Arjun',
    meta: 'Data Engineer · 3 yrs',
    when: 'Nov 2026',
    pastel: 'sky',
    excerpt:
        '30 minutes with a recruiter, then 30 with an engineer. Python basics and one question on Spark partitions.',
    questions: [
      'Python basics: lists, dicts and generators',
      'How Spark decides the number of partitions',
      'Why do you want to work here?',
    ],
    how: 'Friendly round. Waiting on the next step.',
    tip: 'Revise the basics the night before. They moved fast through the easy questions.',
  ),
  InterviewStory(
    company: 'Snowflake',
    role: 'Analytics Engineer',
    round: 'Final',
    outcome: 'Rejected',
    by: 'Meera',
    meta: 'Analytics Engineer · 5 yrs',
    when: 'Oct 2026',
    pastel: 'mint',
    excerpt:
        'Case study on dbt models and a long behavioural round. Feedback was that I needed more stakeholder examples.',
  ),
];

const List<LearnBadge> sampleBadges = [
  LearnBadge(
    shape: 'notch',
    color: 'lav',
    glyph: 'SQL',
    name: 'SQL Ace',
    how: 'Score 7+ on a SQL week',
    earned: true,
  ),
  LearnBadge(
    shape: 'orb',
    color: 'pch',
    glyph: '7',
    name: '7-day streak',
    how: 'Answer 7 days in a row',
    earned: true,
  ),
  LearnBadge(
    shape: 'chevron',
    color: 'mint',
    name: 'Pitch ready',
    how: 'Record your pitch',
    earned: true,
  ),
  LearnBadge(
    shape: 'split',
    color: 'but',
    name: 'First story',
    how: 'Share an interview story',
    earned: false,
  ),
  LearnBadge(
    shape: 'orb',
    color: 'sky',
    glyph: '30',
    name: '30-day streak',
    how: 'Answer 30 days in a row',
    earned: false,
  ),
  LearnBadge(
    shape: 'notch',
    color: 'mint',
    glyph: 'PY',
    name: 'Python Pro',
    how: 'Score 8+ on a Python week',
    earned: false,
  ),
  LearnBadge(
    shape: 'chevron',
    color: 'lav',
    name: 'Interview ready',
    how: 'Finish an AI mock interview',
    earned: false,
  ),
  LearnBadge(
    shape: 'split',
    color: 'pch',
    name: 'Helpful',
    how: '5 people found your story helpful',
    earned: false,
  ),
  LearnBadge(
    shape: 'notch',
    color: 'sky',
    glyph: '10',
    name: 'Perfect 10',
    how: 'Get 10/10 in a week',
    earned: false,
  ),
];

const List<LearnBadge> shelfBadges = [
  LearnBadge(
    shape: 'notch',
    color: 'lav',
    glyph: 'SQL',
    name: 'SQL Ace',
    how: 'Score 7+ on a SQL week',
    earned: true,
  ),
  LearnBadge(
    shape: 'orb',
    color: 'pch',
    glyph: '7',
    name: '7-day streak',
    how: 'Answer 7 days in a row',
    earned: true,
  ),
  LearnBadge(
    shape: 'chevron',
    color: 'mint',
    name: 'Pitch ready',
    how: 'Record your pitch',
    earned: true,
  ),
  LearnBadge(
    shape: 'split',
    color: 'but',
    name: 'First story',
    how: 'Share an interview story',
    earned: false,
  ),
];
