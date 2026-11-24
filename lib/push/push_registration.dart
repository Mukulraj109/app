import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Required top-level entry for background messages. UI routing happens on tap.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

/// Registers / unregisters the FCM token with POST/DELETE /api/me/devices.
/// Soft-fails when Firebase is not configured (no real google-services.json yet).
class PushRegistration {
  PushRegistration(this._api);

  final ApiClient _api;
  String? _token;
  bool _ready = false;
  StreamSubscription<String>? _refreshSub;
  void Function(RemoteMessage message)? _onOpened;
  void Function(RemoteMessage message)? _onForeground;
  bool _handlersAttached = false;

  String? get token => _token;

  /// Foreground banner + tap routing. Safe before Firebase is configured.
  void configureHandlers({
    void Function(RemoteMessage message)? onForeground,
    void Function(RemoteMessage message)? onOpened,
  }) {
    _onForeground = onForeground;
    _onOpened = onOpened;
  }

  Future<void> ensureInitialized() async {
    if (_ready) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      if (!_handlersAttached) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        FirebaseMessaging.onMessage.listen((message) {
          _onForeground?.call(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          _onOpened?.call(message);
        });
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null) {
          _onOpened?.call(initial);
        }
        _handlersAttached = true;
      }
      _ready = true;
    } catch (error, stack) {
      debugPrint('PushRegistration: Firebase not ready ($error)');
      debugPrint('$stack');
      _ready = false;
    }
  }

  Future<void> registerAfterLogin() async {
    await ensureInitialized();
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      _token = token;
      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'unknown';
      await _api.registerDevice(
        token: token,
        platform: platform,
        provider: 'fcm',
      );
      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen((next) async {
        _token = next;
        try {
          await _api.registerDevice(
            token: next,
            platform: platform,
            provider: 'fcm',
          );
        } catch (_) {}
      });
    } catch (error) {
      debugPrint('PushRegistration.registerAfterLogin failed: $error');
    }
  }

  Future<void> unregisterOnLogout() async {
    final token = _token;
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (token == null || token.isEmpty) return;
    try {
      await _api.removeDevice(token: token);
    } catch (_) {}
    _token = null;
  }
}
