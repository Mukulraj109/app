// Pure helpers for Profile tab labeling and badge sheet source selection.

/// Status chip on the plan card (Basic → Free; paid → Active / Payment due / Renew).
String planStatusChipLabel({
  required bool isBasic,
  required bool paymentDue,
  required bool showRenew,
  required String status,
}) {
  if (isBasic) return 'Free';
  if (paymentDue) return 'Payment due';
  if (showRenew) return 'Renew';
  final key = status.trim().toLowerCase();
  if (key == 'inactive' ||
      key == 'paused' ||
      key == 'expired' ||
      key == 'canceled' ||
      key == 'cancelled') {
    if (status.trim().isEmpty) return 'Inactive';
    final raw = status.trim();
    return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
  }
  return 'Active';
}

/// Maps a UTC offset to an IANA zone the settings API accepts.
String ianaForUtcOffset(Duration offset) {
  if (offset == const Duration(hours: 5, minutes: 45)) return 'Asia/Kathmandu';
  if (offset == const Duration(hours: 5, minutes: 30)) return 'Asia/Kolkata';
  if (offset == const Duration(hours: 4)) return 'Asia/Dubai';
  if (offset == const Duration(hours: 3)) return 'Europe/Moscow';
  if (offset == const Duration(hours: 2)) return 'Europe/Athens';
  if (offset == const Duration(hours: 1)) return 'Europe/Berlin';
  if (offset == Duration.zero) return 'UTC';
  if (offset == const Duration(hours: -1)) return 'Atlantic/Azores';
  if (offset == const Duration(hours: -3)) return 'America/Sao_Paulo';
  if (offset == const Duration(hours: -5) ||
      offset == const Duration(hours: -4)) {
    return 'America/New_York';
  }
  if (offset == const Duration(hours: -6)) return 'America/Chicago';
  // Pacific standard (-8) and daylight (-7); Mountain standard is also -7.
  if (offset == const Duration(hours: -8) ||
      offset == const Duration(hours: -7)) {
    return 'America/Los_Angeles';
  }
  if (offset == const Duration(hours: -9)) return 'America/Anchorage';
  if (offset == const Duration(hours: -10)) return 'Pacific/Honolulu';
  if (offset == const Duration(hours: 8)) return 'Asia/Singapore';
  if (offset == const Duration(hours: 9)) return 'Asia/Tokyo';
  if (offset == const Duration(hours: 10)) return 'Australia/Sydney';
  if (offset == const Duration(hours: 12) ||
      offset == const Duration(hours: 13)) {
    return 'Pacific/Auckland';
  }
  return 'America/New_York';
}

/// When [apiRows] is null (no fetch), fall back to [samples] for offline demo.
/// When the API returned a list (even empty), keep it — never invent earned badges.
List<T> badgeRowsForSheet<T>(List<T>? apiRows, {required List<T> samples}) {
  if (apiRows == null) return samples;
  return apiRows;
}
