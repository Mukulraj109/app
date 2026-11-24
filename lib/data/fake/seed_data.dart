import '../models/user_model.dart';
import '../models/tracker_state_model.dart';
import '../models/interview_model.dart';
import '../models/task_model.dart';

class SeedData {
  static const UserProfile user = UserProfile(
    id: 'usr_arjun_01',
    name: 'Arjun Mehta',
    email: 'arjun.mehta@example.com',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=250',
    planName: 'Premium Plus',
    planDay: 42,
    planTotalDays: 100,
    usedApplicationsToday: 28,
    dailyApplicationCap: 40,
    referralCode: 'ARJUN7K',
    referralPoints: 140,
    aic: AicProfile(
      name: 'Priya Nair',
      role: 'Senior Application Incharge',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=250',
      currentFocus: 'Targeting Senior Frontend & Full-Stack roles at Series B-D startups',
      whatsappNumber: '+1 (555) 839-2041',
      ticketUrl: 'https://firststep.careers/support/ticket/new',
    ),
  );

  static const TrackerState defaultTracker = TrackerState(
    status: LiveStatusType.applying,
    todayCount: 12,
    todayCompanies: ['Stripe', 'Notion', 'Datadog', 'Linear', 'Figma', 'Ramp', 'Vercel', 'Supabase'],
  );

  static const DashboardMetrics metrics = DashboardMetrics(
    totalApplications: 486,
    weekApplications: 39,
    upcomingInterviews: 2,
    hoursSaved: 31,
    responsesReceived: 14,
    offers: 0,
    replied: 6,
  );

  static final List<InboxItem> inboxItems = [
    const InboxItem(
      id: 'in_01',
      title: 'Priya submitted 4 applications',
      body: 'Stripe, Notion, Datadog, and Linear went out this morning.',
      timeLabel: '2h ago',
      kind: InboxKind.aicUpdate,
    ),
    const InboxItem(
      id: 'in_02',
      title: 'Framer replied about interview time',
      body: 'Choose a slot for Thursday system design.',
      timeLabel: '2h ago',
      kind: InboxKind.interview,
    ),
    const InboxItem(
      id: 'in_03',
      title: 'Stripe application closes in 2 days',
      body: 'Draft is waiting in your applications queue.',
      timeLabel: 'Today',
      kind: InboxKind.deadline,
    ),
    const InboxItem(
      id: 'in_04',
      title: 'Question of the day is ready',
      body: 'Keep your 7-day streak alive — 1 quick answer.',
      timeLabel: 'Morning',
      kind: InboxKind.qotd,
    ),
    const InboxItem(
      id: 'in_05',
      title: 'Weekly summary',
      body: '39 applications this week · 2 interviews upcoming.',
      timeLabel: 'Yesterday',
      kind: InboxKind.system,
      isRead: true,
    ),
  ];

  static final List<NeedsYouItem> needsYou = [
    const NeedsYouItem(
      id: 'need_01',
      title: 'Framer replied about interview time',
      subtitle: '2 hours ago',
      badge: 'Reply',
    ),
    const NeedsYouItem(
      id: 'need_02',
      title: 'Stripe application closes in 2 days',
      subtitle: 'Draft in queue',
      badge: 'Review',
    ),
  ];

  static final List<InterviewEvent> interviews = [
    const InterviewEvent(
      id: 'int_01',
      company: 'Figma',
      role: 'Senior Frontend Engineer',
      kind: InterviewKind.systemDesign,
      status: InterviewStatus.confirmed,
      dateTimeLabel: 'Tomorrow · 2:00 PM ET',
      dateBadge: 'In 24h',
      hasAiPrepReady: true,
    ),
    const InterviewEvent(
      id: 'int_02',
      company: 'Datadog',
      role: 'Product Engineer (Web Platform)',
      kind: InterviewKind.technicalScreen,
      status: InterviewStatus.dateTbc,
      dateTimeLabel: 'Next Week (Scheduling)',
      dateBadge: 'Date TBC',
      hasAiPrepReady: true,
    ),
  ];

  static const QuestionOfTheDay qotd = QuestionOfTheDay(
    id: 'qotd_01',
    question: 'How do you handle debounce vs throttle in high-frequency event streams like search autocomplete?',
    options: [
      'Debounce delays execution until silence; Throttle ensures steady periodic calls.',
      'Throttle delays execution until silence; Debounce fires continuously.',
      'Both are functionally identical in JS runtime loops.',
      'Debounce runs only in Web Workers; Throttle runs on UI thread.',
    ],
    correctOptionIndex: 0,
    currentStreak: 7,
  );

  static const WeeklyChallenge challenge = WeeklyChallenge(
    id: 'chal_01',
    title: 'Record a 60-Second Video Intro',
    description: 'Share your background and passion project for hiring managers to review before screening.',
    minutes: 15,
  );

  static final List<DailyTask> dailyTasks = [
    const DailyTask(
      id: 'task_01',
      title: 'Review 3 tailored resume versions',
      description: 'Priya updated your bullet points for Stripe and Notion submissions.',
      timeEstimate: '5 mins',
    ),
    const DailyTask(
      id: 'task_02',
      title: 'Complete Figma AI Mock Interview',
      description: 'System design session generated specifically for Figma web team questions.',
      timeEstimate: '20 mins',
    ),
  ];

  static const List<String> userBadges = [
    'First Day',
    '100 Applications',
    '7-Day Streak',
    'Interview Ready',
  ];
}
