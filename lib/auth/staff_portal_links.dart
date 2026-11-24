/// Allowlisted staff portal paths from backend STAFF_PORTALS.
const kStaffPortalPaths = <String>{
  '/super-admin/overview',
  '/application-incharge/dashboard',
  '/job-collector/dashboard',
};

/// Build an https website URL for a staff portal path, or null if not allowlisted.
String? staffWebsiteUrl({
  required String webAppOrigin,
  required String? portalPath,
}) {
  final path = (portalPath ?? '').trim();
  if (!kStaffPortalPaths.contains(path)) return null;
  final origin = webAppOrigin.replaceAll(RegExp(r'/+$'), '');
  return '$origin$path';
}
