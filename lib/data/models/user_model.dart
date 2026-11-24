class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String planName;
  final int planDay;
  final int planTotalDays;
  final int usedApplicationsToday;
  final int dailyApplicationCap;
  final String referralCode;
  final int referralPoints;
  final AicProfile aic;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.planName,
    required this.planDay,
    required this.planTotalDays,
    required this.usedApplicationsToday,
    required this.dailyApplicationCap,
    required this.referralCode,
    required this.referralPoints,
    required this.aic,
  });

  int get daysLeft => (planTotalDays - planDay).clamp(0, 999);
  double get planProgress => (planDay / planTotalDays).clamp(0.0, 1.0);
}

class AicProfile {
  final String name;
  final String role;
  final String avatarUrl;
  final String currentFocus;
  final String whatsappNumber;
  final String ticketUrl;

  const AicProfile({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.currentFocus,
    required this.whatsappNumber,
    required this.ticketUrl,
  });
}
