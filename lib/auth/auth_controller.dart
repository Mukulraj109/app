import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/bootstrap_models.dart';
import '../push/push_registration.dart';
import 'auth_config.dart';
import 'auth_service.dart';
import 'staff_portal_links.dart' as portals;

enum AuthPhase {
  booting,
  signedOut,
  authenticating,
  bootstrapping,
  candidate,
  staffBlocked,
  error,
}

/// Owns Auth0 session + bootstrap gate for the app shell.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.config,
    required AuthService authService,
    required ApiClient apiClient,
    PushRegistration? pushRegistration,
  })  : _auth = authService,
        _api = apiClient,
        _push = pushRegistration ?? PushRegistration(apiClient);

  final AuthConfig config;
  final AuthService _auth;
  final ApiClient _api;
  final PushRegistration _push;

  AuthPhase _phase = AuthPhase.booting;
  String? _errorMessage;
  BootstrapResult? _bootstrap;
  SessionUser? _sessionUser;
  String? _staffWebsiteUrl;
  String? _pendingReferralCode;

  AuthPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  BootstrapResult? get bootstrap => _bootstrap;
  BootstrapResult? get lastBootstrap => _bootstrap;
  SessionUser? get sessionUser => _sessionUser;
  bool _onboardingComplete = false;

  bool get showOnboarding =>
      _phase == AuthPhase.candidate &&
      !_onboardingComplete &&
      (_bootstrap?.needsOnboarding ?? false);
  String? get staffWebsiteUrl => _staffWebsiteUrl;
  bool get githubEnabled => config.githubEnabled;
  bool get isConfigured => config.isConfigured;
  ApiClient get api => _api;
  PushRegistration get push => _push;

  bool get needsCheckout =>
      _phase == AuthPhase.candidate && (_bootstrap?.needsCheckout ?? false);

  Future<void> bootstrapOnLaunch() async {
    if (!config.isConfigured) {
      _phase = AuthPhase.signedOut;
      notifyListeners();
      return;
    }
    _phase = AuthPhase.booting;
    notifyListeners();
    try {
      final restored = await _auth.restore();
      if (restored == null) {
        _phase = AuthPhase.signedOut;
        notifyListeners();
        return;
      }
      _api.setCredentials(restored);
      await _runBootstrap();
    } catch (e) {
      await _safeClear();
      _phase = AuthPhase.signedOut;
      notifyListeners();
    }
  }

  void setPendingReferralCode(String? code) {
    final clean = code?.trim().toUpperCase() ?? '';
    _pendingReferralCode = clean.isEmpty ? null : clean;
  }

  Future<Map<String, dynamic>> lookupReferral(String code) {
    return _api.lookupReferral(code);
  }

  Future<void> signInWithGoogle() => _signIn('google-oauth2');

  /// Auth0 social connection name must be `apple` on the tenant.
  Future<void> signInWithApple() => _signIn('apple');

  /// Auth0 social connection name must be `linkedin` on the tenant.
  Future<void> signInWithLinkedIn() => _signIn('linkedin');

  Future<void> signInWithGitHub() {
    if (!config.githubEnabled) {
      _errorMessage = 'GitHub sign-in is not enabled.';
      _phase = AuthPhase.error;
      notifyListeners();
      return Future.value();
    }
    return _signIn('github');
  }

  Future<void> _signIn(String connection) async {
    if (!config.isConfigured) {
      _errorMessage =
          'Auth is not configured. Pass AUTH0_DOMAIN, AUTH0_CLIENT_ID, and API_BASE_URL.';
      _phase = AuthPhase.error;
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _phase = AuthPhase.authenticating;
    notifyListeners();
    try {
      final creds = await _auth.loginWithConnection(connection);
      _api.setCredentials(creds);
      await _runBootstrap();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _phase = AuthPhase.error;
      notifyListeners();
    }
  }

  Future<void> _runBootstrap() async {
    _phase = AuthPhase.bootstrapping;
    notifyListeners();
    try {
      final result = await _api.bootstrap(referralCode: _pendingReferralCode);
      _bootstrap = result;
      _sessionUser = result.user;
      if (result.isStaffPortal) {
        final url = portals.staffWebsiteUrl(
          webAppOrigin: config.safeWebAppOrigin,
          portalPath: result.portalPath,
        );
        await _auth.clearCredentials();
        _api.setCredentials(null);
        _api.clearBootstrapCache();
        _sessionUser = null;
        _staffWebsiteUrl = url;
        _phase = AuthPhase.staffBlocked;
        notifyListeners();
        return;
      }
      if (result.isCandidateDestination) {
        _staffWebsiteUrl = null;
        _phase = AuthPhase.candidate;
        notifyListeners();
        // Best-effort FCM register; never blocks login if Firebase is missing.
        unawaited(_push.registerAfterLogin());
        return;
      }
      await _safeClear();
      _errorMessage = 'Unable to continue with this account.';
      _phase = AuthPhase.error;
      notifyListeners();
    } catch (e) {
      await _safeClear();
      _errorMessage = _friendlyError(e);
      _phase = AuthPhase.error;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Drop app session first so welcome/sign-in shows without waiting on Auth0.
    _api.setCredentials(null);
    _api.clearBootstrapCache();
    _bootstrap = null;
    _sessionUser = null;
    _staffWebsiteUrl = null;
    _errorMessage = null;
    _onboardingComplete = false;
    _phase = AuthPhase.signedOut;
    notifyListeners();

    try {
      await _auth.clearCredentials();
    } catch (_) {
      await _safeClear();
    }

    // Push unregister + Auth0 browser logout can be slow — don't block UI.
    unawaited(_finishRemoteSignOut());
  }

  Future<void> _finishRemoteSignOut() async {
    try {
      await _push.unregisterOnLogout();
    } catch (_) {}
    try {
      await _auth.logout();
    } catch (_) {
      await _safeClear();
    }
  }

  Future<void> refreshBootstrap() async {
    _api.clearBootstrapCache();
    await _runBootstrap();
  }

  /// After PATCH /api/me/profile — keep in-memory session name in sync.
  void updateSessionDisplayName(String displayName) {
    final clean = displayName.trim();
    if (clean.isEmpty || _sessionUser == null) return;
    _sessionUser = _sessionUser!.copyWith(firstName: clean);
    notifyListeners();
  }

  void markOnboardingComplete() {
    _onboardingComplete = true;
    notifyListeners();
  }

  Future<void> dismissErrorToSignedOut() async {
    _errorMessage = null;
    _sessionUser = null;
    _phase = AuthPhase.signedOut;
    notifyListeners();
  }

  Future<void> _safeClear() async {
    try {
      await _auth.clearCredentials();
    } catch (_) {}
    _api.setCredentials(null);
    _api.clearBootstrapCache();
    _bootstrap = null;
    _sessionUser = null;
    _staffWebsiteUrl = null;
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    final text = e.toString();
    if (text.contains('a0.session.user_cancelled') ||
        text.toLowerCase().contains('cancelled')) {
      return 'Sign-in cancelled.';
    }
    return 'Sign-in failed. Try again.';
  }
}
