import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_config.dart';
import '../auth/auth_service.dart';
import '../features/profile/profile_helpers.dart';
import 'bootstrap_models.dart';
import 'profile_models.dart';

export '../features/profile/profile_helpers.dart' show ianaForUtcOffset;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// One long-lived HTTP client with bootstrap dedupe and a single 401 refresh.
class ApiClient {
  ApiClient({
    required this.config,
    required AuthService authService,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  })  : _auth = authService,
        _http = httpClient ?? http.Client();

  final AuthConfig config;
  final AuthService _auth;
  final http.Client _http;
  final Duration timeout;

  AuthCredentials? _credentials;
  BootstrapResult? _bootstrapCache;
  Future<BootstrapResult>? _bootstrapInFlight;
  bool _refreshing = false;

  void setCredentials(AuthCredentials? credentials) {
    _credentials = credentials;
    _bootstrapCache = null;
  }

  AuthCredentials? get credentials => _credentials;

  void clearBootstrapCache() {
    _bootstrapCache = null;
    _bootstrapInFlight = null;
  }

  Future<BootstrapResult> bootstrap({
    String? referralCode,
    String entry = 'signup',
  }) {
    if (_bootstrapCache != null) return Future.value(_bootstrapCache);
    return _bootstrapInFlight ??= _runBootstrap(
      referralCode: referralCode,
      entry: entry,
    ).whenComplete(() => _bootstrapInFlight = null);
  }

  Future<BootstrapResult> _runBootstrap({
    String? referralCode,
    required String entry,
  }) async {
    final body = <String, dynamic>{'entry': entry};
    final code = referralCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      body['referralCode'] = code.length > 32 ? code.substring(0, 32) : code;
    }

    final json = await _postJson(
      '/api/me/bootstrap',
      body: body,
      authed: true,
    );
    final result = BootstrapResult.fromJson(json);
    _bootstrapCache = result;
    return result;
  }

  Future<Map<String, dynamic>> lookupReferral(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return {'found': false};
    return _getJson('/api/r/${Uri.encodeComponent(clean)}', authed: false);
  }

  Future<PlanSummary> getPlanSummary() async {
    final json = await _getJson('/api/me/plan-summary', authed: true);
    return PlanSummary.fromJson(json);
  }

  Future<RewardsSummary> getRewards() async {
    final json = await _getJson('/api/me/rewards', authed: true);
    return RewardsSummary.fromJson(json);
  }

  /// Same redeem request as web ProfileHub ($15 held until staff applies add-on).
  /// Callers: profile_view._redeemRewards. Keep [previousReferralCode] when
  /// POST /api/me/rewards/redeem omits referralCode ({balanceUsd, status}).
  Future<RewardsSummary> redeemRewards({
    double amountUsd = 15,
    String addOn = 'Resume add-on',
    String previousReferralCode = '',
  }) async {
    final json = await _postJson(
      '/api/me/rewards/redeem',
      body: {'amountUsd': amountUsd, 'addOn': addOn},
      authed: true,
    );
    final code = '${json['referralCode'] ?? ''}'.trim();
    return RewardsSummary.fromJson({
      'balanceUsd': json['balanceUsd'],
      'referralCode': code.isNotEmpty ? code : previousReferralCode,
      if (json['history'] != null) 'history': json['history'],
    });
  }

  Future<List<String>> getDoNotApply() async {
    final json = await _getJson('/api/me/do-not-apply', authed: true);
    final raw = json['companies'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if ('$item'.trim().isNotEmpty) '$item'.trim(),
    ];
  }

  Future<List<String>> putDoNotApply(List<String> companies) async {
    final json = await _putJson(
      '/api/me/do-not-apply',
      body: {'companies': companies},
      authed: true,
    );
    final raw = json['companies'];
    if (raw is! List) return companies;
    return [
      for (final item in raw)
        if ('$item'.trim().isNotEmpty) '$item'.trim(),
    ];
  }

  Future<List<BadgeItem>> getBadges() async {
    final list = await _getList('/api/me/badges', authed: true);
    return list
        .whereType<Map>()
        .map((item) => BadgeItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> getHomeScreen() {
    return _getJson('/api/me/home/screen', authed: true);
  }

  Future<Map<String, dynamic>> getLearnWeek() {
    return _getJson('/api/me/learn/week', authed: true);
  }

  Future<Map<String, dynamic>> getDiscover({String filter = 'all'}) {
    return _getJson('/api/me/discover?filter=$filter', authed: true);
  }

  Future<Map<String, dynamic>> getDiscoverUnread() {
    return _getJson('/api/me/discover/unread', authed: true);
  }

  Future<Map<String, dynamic>> markDiscoverViewed() {
    return _postJson('/api/me/discover/mark-viewed', body: {}, authed: true);
  }

  Future<Map<String, dynamic>> saveDiscoverPost(String postId, {bool remove = false}) {
    return _postJson('/api/me/discover/$postId/save', body: {'remove': remove}, authed: true);
  }

  Future<Map<String, dynamic>> submitDiscoverPost(Map<String, dynamic> body) {
    return _postJson('/api/me/discover/submissions', body: body, authed: true);
  }

  Future<Map<String, dynamic>> markMilestoneSeen(String id) {
    return _postJson('/api/me/milestones/$id/seen', body: {}, authed: true);
  }

  Future<Map<String, dynamic>> sendHomeFeedback({
    required String id,
    required String rating,
    String comment = '',
  }) {
    return _postJson('/api/me/feedback/$id', body: {
      'rating': rating,
      'comment': comment,
    }, authed: true);
  }

  Future<Map<String, dynamic>> answerTaskFollowup(String taskId, Map<String, dynamic> body) {
    return _postJson('/api/me/tasks/$taskId/followup', body: body, authed: true);
  }

  Future<Map<String, dynamic>> getJobRequests() async {
    // Backend returns a bare array; wrap so callers can keep using map keys.
    final response = await _sendAuthed(() async {
      final headers = await _headers(authed: true);
      return _http.get(_uri('/api/me/job-requests'), headers: headers).timeout(timeout);
    }, authed: true);
    return _decodeMapOrList(response, listKey: 'requests');
  }

  Future<Map<String, dynamic>> createJobRequest(String url) {
    return _postJson('/api/me/job-requests', body: {'url': url, 'source': 'paste'}, authed: true);
  }

  Future<Map<String, dynamic>> getSkillChecks() async {
    // Backend returns a bare array; wrap so Learn can read checks/items.
    final response = await _sendAuthed(() async {
      final headers = await _headers(authed: true);
      return _http.get(_uri('/api/me/skill-checks'), headers: headers).timeout(timeout);
    }, authed: true);
    return _decodeMapOrList(response, listKey: 'checks');
  }

  Future<Map<String, dynamic>> startSkillCheck(String slug) {
    return _postJson('/api/me/skill-checks/$slug/start', body: {}, authed: true);
  }

  Future<Map<String, dynamic>> submitSkillCheck(String slug, Map<String, dynamic> answers) {
    return _postJson('/api/me/skill-checks/$slug/submit', body: {'answers': answers}, authed: true);
  }

  Future<Map<String, dynamic>> completeMockInterview() {
    return _postJson('/api/me/mock-interviews/complete', body: {}, authed: true);
  }

  Future<Map<String, dynamic>> getTopicOfDay() {
    return _getJson('/api/me/topic-of-the-day', authed: true);
  }

  Future<Map<String, dynamic>> answerQuestionOfDay({
    required String questionId,
    required String answer,
  }) {
    return _postJson('/api/me/question-of-the-day', body: {
      'questionId': questionId,
      'answer': answer,
    }, authed: true);
  }

  Future<Map<String, dynamic>> startWeeklyMcq() {
    return _getJson('/api/me/learn/weekly-mcq', authed: true);
  }

  Future<Map<String, dynamic>> submitWeeklyMcq(List<Map<String, String>> answers) {
    return _postJson('/api/me/learn/weekly-mcq', body: {'answers': answers}, authed: true);
  }

  Future<Map<String, dynamic>> completeChallenge(String weekKey) {
    return _postJson('/api/me/challenge/done', body: {'weekKey': weekKey}, authed: true);
  }

  Future<Map<String, dynamic>> getBell({int limit = 30, int skip = 0}) {
    return _getJson('/api/me/bell?limit=$limit&skip=$skip', authed: true);
  }

  Future<Map<String, dynamic>> markBellRead(String id) {
    return _postJson('/api/me/bell/read', body: {'id': id}, authed: true);
  }

  Future<List<Map<String, dynamic>>> getInterviewStories() async {
    final json = await _getJson('/api/me/interview-stories', authed: true);
    final list = json['stories'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Interview story submissions for Learn — separate from Discover blog posts.
  Future<Map<String, dynamic>> submitInterviewStory(Map<String, dynamic> body) {
    return _postJson('/api/me/interview-stories', body: body, authed: true);
  }

  Future<IntakeProfileSummary> getIntakeProfile() async {
    final json = await _getJson('/api/me/intake-profile', authed: true);
    return IntakeProfileSummary.fromJson(json);
  }

  Future<PlanDetailsInfo> getPlanDetails() async {
    final json = await _getJson('/api/me/plan-details', authed: true);
    return PlanDetailsInfo.fromJson(json);
  }

  Future<DocumentsSummary> getDocuments() async {
    final json = await _getJson('/api/me/documents', authed: true);
    return DocumentsSummary.fromJson(json);
  }

  /// Prefers JWT-scoped `/api/me/documents/:id/preview`; falls back to legacy
  /// POST /firstStep/user/attachments/preview (same contract as website navbar).
  Future<String> previewAttachmentUrl({
    required String attachmentId,
    String? attachmentTitle,
  }) async {
    try {
      final me = await _getJson(
        '/api/me/documents/${Uri.encodeComponent(attachmentId)}/preview',
        authed: true,
      );
      final meUrl = '${me['url'] ?? ''}'.trim();
      if (meUrl.isNotEmpty) return meUrl;
    } on ApiException catch (error) {
      if (error.statusCode != 404 && error.statusCode != 405) rethrow;
    }

    final userId = _tokenSubject();
    if (userId == null || userId.isEmpty) {
      throw ApiException(401, 'Sign in again to preview this document.');
    }
    final body = <String, dynamic>{
      'user_id': userId,
      'attachment_id': attachmentId,
    };
    final title = attachmentTitle?.trim();
    if (title != null && title.isNotEmpty) {
      body['attachment_type'] = title;
    }
    final json = await _postJson(
      '/firstStep/user/attachments/preview',
      body: body,
      authed: true,
    );
    final url = '${json['url'] ?? ''}'.trim();
    if (url.isEmpty) {
      throw ApiException(
        404,
        '${json['message'] ?? json['error'] ?? 'Preview unavailable.'}',
      );
    }
    return url;
  }

  /// Authenticated binary download for Profile → My documents.
  Future<({List<int> bytes, String fileName, String contentType})>
      downloadDocument(String id) async {
    final response = await _sendAuthed(() async {
      final headers = await _headers(authed: true);
      headers['Accept'] = '*/*';
      return _http
          .get(
            _uri('/api/me/documents/${Uri.encodeComponent(id)}/download'),
            headers: headers,
          )
          .timeout(timeout);
    }, authed: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decodeMap(response);
      final message =
          '${decoded['error'] ?? decoded['message'] ?? 'Download failed.'}';
      throw ApiException(response.statusCode, message);
    }
    var fileName = 'document.pdf';
    final disposition = response.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
      if (match != null) fileName = match.group(1)!.trim();
    }
    return (
      bytes: response.bodyBytes,
      fileName: fileName,
      contentType: response.headers['content-type'] ?? 'application/pdf',
    );
  }

  Future<SupportTicketsSummary> getSupportTickets() async {
    final json = await _getJson('/api/me/requests', authed: true);
    return SupportTicketsSummary.fromJson(json);
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String description,
    String? reason,
  }) async {
    return _postJson(
      '/api/me/requests',
      body: {
        'type': 'support',
        'description': description,
        'source': 'mobile',
        'payload': {if (reason != null && reason.isNotEmpty) 'reason': reason},
      },
      authed: true,
    );
  }

  Future<AppProfileSummary> getAppProfile() async {
    final json = await _getJson('/api/me/app-profile', authed: true);
    return AppProfileSummary.fromJson(json);
  }

  Future<AppProfileSummary> putAppProfile(Map<String, dynamic> body) async {
    final json = await _putJson('/api/me/app-profile', body: body, authed: true);
    return AppProfileSummary.fromJson(json);
  }

  Future<PlanBenefitsSummary> getPlanBenefits() async {
    final json = await _getJson('/api/me/plan-benefits', authed: true);
    return PlanBenefitsSummary.fromJson(json);
  }

  Future<Map<String, dynamic>> patchProfile({required String displayName}) async {
    return _patchJson(
      '/api/me/profile',
      body: {'displayName': displayName},
      authed: true,
    );
  }

  Future<Map<String, dynamic>> deleteAccountRequest() async {
    return _postJson('/api/me/delete-account-request', body: {}, authed: true);
  }

  Future<List<CalendarHoliday>> getCalendar() async {
    final json = await _getJson('/api/me/calendar', authed: true);
    final raw = json['holidays'];
    final items = <CalendarHoliday>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          items.add(
            CalendarHoliday.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return items;
  }

  Future<Map<String, dynamic>> answerOnboarding({
    required String questionId,
    bool skipped = false,
    Object? value,
  }) async {
    return _putJson(
      '/api/me/onboarding/answer',
      body: {
        'questionId': questionId,
        'skipped': skipped,
        if (value != null) 'value': value,
      },
      authed: true,
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    return _getJson('/api/me/settings', authed: true);
  }

  Future<Map<String, dynamic>> putSettings(Map<String, dynamic> body) async {
    return _putJson('/api/me/settings', body: body, authed: true);
  }

  Future<Map<String, dynamic>> patchTheme(String theme) async {
    return _patchJson('/api/me/theme', body: {'theme': theme}, authed: true);
  }

  /// Same tap record the website uses before WhatsApp confirm webhook.
  Future<Map<String, dynamic>> recordWhatsappOptIn({String? phone}) async {
    return _postJson(
      '/api/me/whatsapp-opt-in',
      body: {
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      authed: true,
    );
  }

  Future<Map<String, dynamic>> registerDevice({
    required String token,
    required String platform,
    String provider = 'fcm',
  }) async {
    return _postJson(
      '/api/me/devices',
      body: {
        'token': token,
        'platform': platform,
        'provider': provider,
      },
      authed: true,
    );
  }

  Future<Map<String, dynamic>> applicationMonth(String month) {
    return _getJson('/api/me/applications/month?month=${Uri.encodeQueryComponent(month)}', authed: true);
  }

  Future<Map<String, dynamic>> applications({
    required String from,
    required String to,
    String cursor = '',
  }) {
    final query = 'from=${Uri.encodeQueryComponent(from)}&to=${Uri.encodeQueryComponent(to)}&cursor=${Uri.encodeQueryComponent(cursor)}';
    return _getJson('/api/me/applications?$query', authed: true);
  }

  Future<Map<String, dynamic>> userApplications({String cursor = ''}) {
    return _getJson(
      '/api/me/applications?source=user&cursor=${Uri.encodeQueryComponent(cursor)}',
      authed: true,
    );
  }

  Future<Map<String, dynamic>> logApplication({
    required String company,
    required String role,
    required String appliedOn,
    String jobUrl = '',
  }) {
    return _postJson(
      '/api/me/applications/mine',
      body: {
        'company': company,
        'role': role,
        'appliedOn': appliedOn,
        if (jobUrl.isNotEmpty) 'jobUrl': jobUrl,
      },
      authed: true,
    );
  }

  Future<Map<String, dynamic>> searchApplications({
    required String company,
    String cursor = '',
  }) {
    final query = 'company=${Uri.encodeQueryComponent(company)}&cursor=${Uri.encodeQueryComponent(cursor)}';
    return _getJson('/api/me/applications/search?$query', authed: true);
  }

  Future<Map<String, dynamic>> saveApplication(String jobId, {required bool saved}) {
    return _postJson(
      '/api/me/applications/${Uri.encodeComponent(jobId)}/save',
      body: {'saved': saved},
      authed: true,
    );
  }

  Future<Map<String, dynamic>> savedJobs({String cursor = ''}) {
    return _getJson('/api/me/saved-jobs?cursor=${Uri.encodeQueryComponent(cursor)}', authed: true);
  }

  Future<Map<String, dynamic>> applicationJob(String jobId) {
    return _getJson('/api/me/applications/job/${Uri.encodeComponent(jobId)}', authed: true);
  }

  Future<Map<String, dynamic>> applicationResponses({String cursor = ''}) {
    return _getJson('/api/me/responses?cursor=${Uri.encodeQueryComponent(cursor)}&limit=30', authed: true);
  }

  Future<void> applicationFeedback(String jobId, {required String rating, String reason = ''}) async {
    await _postJson(
      '/api/me/applications/${Uri.encodeComponent(jobId)}/feedback',
      body: {'rating': rating, if (reason.isNotEmpty) 'reason': reason},
      authed: true,
    );
  }

  Future<List<int>> downloadResumeFile(String resumeId) async {
    final response = await _sendAuthed(() async {
      final headers = await _headers(authed: true);
      return _http
          .post(
            _uri('/firstStep/resume/download'),
            headers: headers,
            body: jsonEncode({'resume_id': resumeId}),
          )
          .timeout(const Duration(seconds: 30));
    }, authed: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decodeMap(response);
      final message = '${decoded['error'] ?? decoded['message'] ?? 'Could not download the resume.'}';
      throw ApiException(response.statusCode, message);
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> removeDevice({required String token}) async {
    return _deleteJson(
      '/api/me/devices',
      body: {'token': token},
      authed: true,
    );
  }

  Future<Map<String, dynamic>> _getJson(String path, {required bool authed}) async {
    return _sendJson(() async {
      final headers = await _headers(authed: authed);
      return _http.get(_uri(path), headers: headers).timeout(timeout);
    }, authed: authed);
  }

  Future<List<dynamic>> _getList(String path, {required bool authed}) async {
    return _sendList(() async {
      final headers = await _headers(authed: authed);
      return _http.get(_uri(path), headers: headers).timeout(timeout);
    }, authed: authed);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> body,
    required bool authed,
  }) async {
    return _sendJson(() async {
      final headers = await _headers(authed: authed);
      return _http
          .post(
            _uri(path),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
    }, authed: authed);
  }

  Future<Map<String, dynamic>> _putJson(
    String path, {
    required Map<String, dynamic> body,
    required bool authed,
  }) async {
    return _sendJson(() async {
      final headers = await _headers(authed: authed);
      return _http
          .put(
            _uri(path),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
    }, authed: authed);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path, {
    required Map<String, dynamic> body,
    required bool authed,
  }) async {
    return _sendJson(() async {
      final headers = await _headers(authed: authed);
      return _http
          .patch(
            _uri(path),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
    }, authed: authed);
  }

  Future<Map<String, dynamic>> _deleteJson(
    String path, {
    required Map<String, dynamic> body,
    required bool authed,
  }) async {
    return _sendJson(() async {
      final headers = await _headers(authed: authed);
      return _http
          .delete(
            _uri(path),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
    }, authed: authed);
  }

  Future<Map<String, dynamic>> _sendJson(
    Future<http.Response> Function() send, {
    required bool authed,
  }) async {
    final response = await _sendAuthed(send, authed: authed);
    final decoded = _decodeMap(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = '${decoded['error'] ?? decoded['message'] ?? 'Request failed.'}';
      throw ApiException(response.statusCode, message);
    }
    return decoded;
  }

  Future<List<dynamic>> _sendList(
    Future<http.Response> Function() send, {
    required bool authed,
  }) async {
    final response = await _sendAuthed(send, authed: authed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decodeMap(response);
      final message = '${decoded['error'] ?? decoded['message'] ?? 'Request failed.'}';
      throw ApiException(response.statusCode, message);
    }
    return _decodeList(response);
  }

  Future<http.Response> _sendAuthed(
    Future<http.Response> Function() send, {
    required bool authed,
  }) async {
    var response = await send();
    if (response.statusCode == 401 && authed && !_refreshing) {
      _refreshing = true;
      try {
        final refreshed = await _auth.refresh();
        _credentials = refreshed;
      } catch (_) {
        _refreshing = false;
        throw ApiException(401, 'Session expired. Sign in again.');
      }
      _refreshing = false;
      response = await send();
    }
    return response;
  }

  Future<Map<String, String>> _headers({required bool authed}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authed) {
      final token = await _bearerToken();
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String> _bearerToken() async {
    var creds = _credentials;
    if (creds == null) {
      throw ApiException(401, 'Not signed in.');
    }
    if (_nearExpiry(creds)) {
      creds = await _auth.refresh();
      _credentials = creds;
    }
    return creds.idToken;
  }

  /// Decode Auth0 ID token `sub` (same identity web passes as user_id).
  String? _tokenSubject() {
    final token = _credentials?.idToken;
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      if (map is Map && map['sub'] is String) {
        return (map['sub'] as String).trim();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _nearExpiry(AuthCredentials creds) {
    final exp = creds.expiresAt;
    if (exp == null) return false;
    return !exp.isAfter(DateTime.now().add(const Duration(seconds: 30)));
  }

  Uri _uri(String path) {
    final root = config.apiRoot;
    final parsed = Uri.parse(path.startsWith('/') ? path : '/$path');
    final prefix = root.path.endsWith('/') ? root.path.substring(0, root.path.length - 1) : root.path;
    final combined = '$prefix${parsed.path}';
    return root.replace(
      path: combined.isEmpty ? '/' : combined,
      query: parsed.query.isEmpty ? null : parsed.query,
    );
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      final failed = response.statusCode < 200 || response.statusCode >= 300;
      return {
        'error': failed
            ? 'Request failed (${response.statusCode}).'
            : 'The server sent a response the app could not read.',
      };
    }
    return <String, dynamic>{};
  }

  /// Some journey GETs return a bare JSON array. Wrap it under [listKey].
  Map<String, dynamic> _decodeMapOrList(
    http.Response response, {
    required String listKey,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decodeMap(response);
      final message = '${decoded['error'] ?? decoded['message'] ?? 'Request failed.'}';
      throw ApiException(response.statusCode, message);
    }
    if (response.body.isEmpty) return {listKey: const <dynamic>[]};
    final decoded = jsonDecode(response.body);
    if (decoded is List) return {listKey: decoded};
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {listKey: const <dynamic>[]};
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    return const [];
  }

  void dispose() {
    _http.close();
  }
}

/// Maps the phone UTC offset to an IANA zone the settings API accepts.
String deviceTimezone([DateTime? now]) {
  return ianaForUtcOffset((now ?? DateTime.now()).timeZoneOffset);
}
