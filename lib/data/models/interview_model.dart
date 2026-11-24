enum InterviewKind {
  technicalScreen,
  systemDesign,
  hiringManager,
  takeHomeAssessment,
  behavioral,
}

enum InterviewStatus {
  confirmed,
  dateTbc,
  completed,
  cancelled,
}

class InterviewEvent {
  final String id;
  final String company;
  final String role;
  final InterviewKind kind;
  final InterviewStatus status;
  final String? dateTimeLabel;
  final String? dateBadge;
  final bool hasAiPrepReady;

  const InterviewEvent({
    required this.id,
    required this.company,
    required this.role,
    required this.kind,
    required this.status,
    this.dateTimeLabel,
    this.dateBadge,
    this.hasAiPrepReady = true,
  });

  String get kindLabel {
    switch (kind) {
      case InterviewKind.technicalScreen:
        return 'Technical Screen';
      case InterviewKind.systemDesign:
        return 'System Design';
      case InterviewKind.hiringManager:
        return 'Hiring Manager';
      case InterviewKind.takeHomeAssessment:
        return 'Take-Home Assessment';
      case InterviewKind.behavioral:
        return 'Behavioral Round';
    }
  }
}
