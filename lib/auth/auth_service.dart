import 'package:auth0_flutter/auth0_flutter.dart';

import 'auth_config.dart';

/// Credentials the app needs for API calls (ID token preferred).
class AuthCredentials {
  const AuthCredentials({
    required this.idToken,
    this.accessToken,
    this.expiresAt,
  });

  final String idToken;
  final String? accessToken;
  final DateTime? expiresAt;
}

abstract class AuthService {
  Future<AuthCredentials?> restore();
  Future<AuthCredentials> loginWithConnection(String connection);
  Future<AuthCredentials> refresh();
  Future<void> clearCredentials();
  Future<void> logout();
}

class Auth0AuthService implements AuthService {
  Auth0AuthService(this.config) : _auth0 = Auth0(config.domain, config.clientId);

  final AuthConfig config;
  final Auth0 _auth0;

  static const _scopes = {'openid', 'profile', 'email', 'offline_access'};
  static const _tokenSkew = Duration(seconds: 30);

  WebAuthentication get _web => _auth0.webAuthentication(scheme: config.scheme);

  @override
  Future<AuthCredentials?> restore() async {
    final has = await _auth0.credentialsManager.hasValidCredentials();
    if (!has) return null;
    final creds = await _auth0.credentialsManager.credentials();
    return _map(creds);
  }

  @override
  Future<AuthCredentials> loginWithConnection(String connection) async {
    final creds = await _web.login(
      scopes: _scopes,
      parameters: {'connection': connection},
    );
    return _map(creds);
  }

  @override
  Future<AuthCredentials> refresh() async {
    final creds = await _auth0.credentialsManager.credentials(
      minTtl: _tokenSkew.inSeconds,
    );
    return _map(creds);
  }

  @override
  Future<void> clearCredentials() async {
    await _auth0.credentialsManager.clearCredentials();
  }

  @override
  Future<void> logout() async {
    // Clear local session first so the app can leave authenticated UI immediately.
    await clearCredentials();
    try {
      // Federated Auth0 logout can open a browser tab and hang on device.
      await _web.logout().timeout(const Duration(seconds: 4));
    } catch (_) {
      // Local clear already done; ignore browser/timeout failures.
    }
  }

  AuthCredentials _map(Credentials creds) {
    final idToken = creds.idToken.trim();
    if (idToken.isEmpty) {
      throw StateError('Auth0 did not return an ID token.');
    }
    return AuthCredentials(
      idToken: idToken,
      accessToken: creds.accessToken,
      expiresAt: creds.expiresAt,
    );
  }
}
