import 'dart:io';

import 'package:flutter/foundation.dart';

/// Compile-time Auth0 / API settings (override via `--dart-define`).
///
/// Defaults match the FirstStep Mobile Native app in Auth0 tenant
/// `dev-0yrs1pb6s37h8s6u.us.auth0.com`. Never put a Client Secret here.
class AuthConfig {
  const AuthConfig({
    required this.domain,
    required this.clientId,
    required this.apiBaseUrl,
    required this.webAppUrl,
    required this.scheme,
    required this.githubEnabled,
    required this.whatsappUrl,
  });

  final String domain;
  final String clientId;
  final String apiBaseUrl;
  final String webAppUrl;
  final String scheme;
  final bool githubEnabled;

  /// Support chat. Empty until `--dart-define=WHATSAPP_URL=https://wa.me/...`.
  final String whatsappUrl;

  /// Auth0 Native application (public client id — safe in the app binary).
  static const defaultDomain = 'dev-0yrs1pb6s37h8s6u.us.auth0.com';
  static const defaultClientId = 'GqPHk4oOClQaMdxwMeLOc15awKEhknkS';
  static const defaultScheme = 'firststep';

  /// Android emulator → host machine. Override with API_BASE_URL for a device
  /// on LAN or a hosted API.
  static const defaultApiBaseUrl = 'http://10.0.2.2:5000';

  /// iOS Simulator → host machine. A physical iPhone still needs a LAN IP.
  static const iosSimulatorApiBaseUrl = 'http://127.0.0.1:5000';

  static const _apiBaseUrlFromEnvironment = String.fromEnvironment('API_BASE_URL');

  /// Android (and tests) keep [defaultApiBaseUrl]. iOS uses the simulator
  /// loopback host only when `API_BASE_URL` was not passed.
  static String resolveDefaultApiBaseUrl() {
    if (_apiBaseUrlFromEnvironment.isNotEmpty) {
      return _apiBaseUrlFromEnvironment;
    }
    if (!kIsWeb && Platform.isIOS) {
      return iosSimulatorApiBaseUrl;
    }
    return defaultApiBaseUrl;
  }

  static final fromEnvironment = AuthConfig(
    domain: const String.fromEnvironment(
      'AUTH0_DOMAIN',
      defaultValue: defaultDomain,
    ),
    clientId: const String.fromEnvironment(
      'AUTH0_CLIENT_ID',
      defaultValue: defaultClientId,
    ),
    apiBaseUrl: resolveDefaultApiBaseUrl(),
    webAppUrl: const String.fromEnvironment(
      'WEB_APP_URL',
      defaultValue: 'https://app.firststepjob.com',
    ),
    scheme: const String.fromEnvironment(
      'AUTH0_SCHEME',
      defaultValue: defaultScheme,
    ),
    githubEnabled: const bool.fromEnvironment('AUTH0_GITHUB', defaultValue: false),
    whatsappUrl: const String.fromEnvironment('WHATSAPP_URL', defaultValue: ''),
  );

  bool get isConfigured =>
      domain.trim().isNotEmpty &&
      clientId.trim().isNotEmpty &&
      apiBaseUrl.trim().isNotEmpty;

  Uri get apiRoot {
    final raw = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse(raw);
  }

  /// HTTPS origin for staff deep links. Rejects non-https overrides.
  String get safeWebAppOrigin {
    final raw = webAppUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'https://app.firststepjob.com';
    }
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
}
