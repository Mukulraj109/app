/// Maps the phone's current UTC offset to an IANA zone the backend accepts.
///
/// Used when syncing `notificationTimezone` so home ribbon copy can respect
/// the viewer's local weekday while ops day stays US Eastern.
String deviceTimezone([DateTime? now]) {
  final offset = (now ?? DateTime.now()).timeZoneOffset;
  if (offset == const Duration(hours: 5, minutes: 30)) return 'Asia/Kolkata';
  if (offset == const Duration(hours: -5) ||
      offset == const Duration(hours: -4)) {
    return 'America/New_York';
  }
  if (offset == const Duration(hours: -8) ||
      offset == const Duration(hours: -7)) {
    return 'America/Los_Angeles';
  }
  if (offset == Duration.zero) return 'UTC';
  return 'America/New_York';
}

/// Flutter weekday: Monday=1 … Sunday=7.
bool deviceIsWeekday([DateTime? now]) {
  final day = (now ?? DateTime.now()).weekday;
  return day >= DateTime.monday && day <= DateTime.friday;
}

/// Weekend ribbon when ops (ET) is offline but the phone is already Mon–Fri.
const kTeamOfflineResumesLater =
    'Team offline · resumes later today (US Eastern)';
