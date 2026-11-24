enum LiveStatusType {
  applying,
  done,
  weekend,
  holiday,
  paused,
  leave,
  paymentDue,
  firstDay,
}

class TrackerState {
  final LiveStatusType status;
  final int todayCount;
  final List<String> todayCompanies;
  final String? resumeDate;
  final String? holidayName;
  final String? alertTitle;
  final String? alertMessage;

  const TrackerState({
    required this.status,
    required this.todayCount,
    required this.todayCompanies,
    this.resumeDate,
    this.holidayName,
    this.alertTitle,
    this.alertMessage,
  });

  String get headline {
    switch (status) {
      case LiveStatusType.applying:
        return 'Priya started applying for you today';
      case LiveStatusType.done:
        return 'Done for today · $todayCount applications sent';
      case LiveStatusType.weekend:
        return 'No applications on weekends · Back Monday';
      case LiveStatusType.holiday:
        return '${holidayName ?? "Official Holiday"} · Back next business day';
      case LiveStatusType.paused:
        return 'Applications currently paused by request';
      case LiveStatusType.leave:
        return 'Priya is on approved leave · Resumes ${resumeDate ?? "soon"}';
      case LiveStatusType.paymentDue:
        return 'Subscription renewal due soon';
      case LiveStatusType.firstDay:
        return 'Your first applications are going out today!';
    }
  }

  String get statusChipLabel {
    switch (status) {
      case LiveStatusType.applying:
        return 'Applying Live';
      case LiveStatusType.done:
        return 'Completed';
      case LiveStatusType.weekend:
        return 'Weekend';
      case LiveStatusType.holiday:
        return 'Holiday';
      case LiveStatusType.paused:
        return 'Paused';
      case LiveStatusType.leave:
        return 'Team Leave';
      case LiveStatusType.paymentDue:
        return 'Payment Due';
      case LiveStatusType.firstDay:
        return 'Day 1';
    }
  }
}

class DashboardMetrics {
  final int totalApplications;
  final int weekApplications;
  final int upcomingInterviews;
  final int hoursSaved;
  final int responsesReceived;
  final int offers;
  final int replied;

  const DashboardMetrics({
    required this.totalApplications,
    required this.weekApplications,
    required this.upcomingInterviews,
    required this.hoursSaved,
    this.responsesReceived = 0,
    this.offers = 0,
    this.replied = 0,
  });
}

class InboxItem {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final InboxKind kind;
  final bool isRead;

  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.kind,
    this.isRead = false,
  });

  InboxItem copyWith({bool? isRead}) {
    return InboxItem(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      kind: kind,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum InboxKind {
  aicUpdate,
  interview,
  deadline,
  qotd,
  system,
}

class NeedsYouItem {
  final String id;
  final String title;
  final String subtitle;
  final String badge;

  const NeedsYouItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}
