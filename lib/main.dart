import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'auth/auth_config.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_service.dart';
import 'features/auth/auth_gate.dart';
import 'state/app_state.dart';
import 'theme/firststep_theme.dart';
import 'theme/home_tokens.dart';
import 'theme/welcome_tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirstStepMobileApp());
}

class FirstStepMobileApp extends StatefulWidget {
  const FirstStepMobileApp({super.key});

  @override
  State<FirstStepMobileApp> createState() => _FirstStepMobileAppState();
}

class _FirstStepMobileAppState extends State<FirstStepMobileApp> {
  final AppState _appState = AppState();
  late final AuthConfig _authConfig;
  late final AuthService _authService;
  late final ApiClient _apiClient;
  late final AuthController _auth;
  bool _usePhoneMockup = true;

  @override
  void initState() {
    super.initState();
    _authConfig = AuthConfig.fromEnvironment;
    _authService = Auth0AuthService(_authConfig);
    _apiClient = ApiClient(config: _authConfig, authService: _authService);
    _auth = AuthController(
      config: _authConfig,
      authService: _authService,
      apiClient: _apiClient,
    );
    _appState.loadPrefs();
    _auth.push.configureHandlers(
      onForeground: (message) {
        final title = message.notification?.title ?? 'New notification';
        _appState.triggerFakePush(title);
      },
      onOpened: (_) => _appState.requestOpenBell(),
    );
    unawaited(_auth.push.ensureInitialized());
    _auth.bootstrapOnLaunch();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    _auth.dispose();
    _appState.dispose();
    super.dispose();
  }

  Future<void> _handleAppSignOutRequest() async {
    if (!_appState.signOutRequested) return;
    _appState.clearSignOutRequest();
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_appState, _auth]),
      builder: (context, _) {
        if (_appState.signOutRequested && _auth.phase == AuthPhase.candidate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleAppSignOutRequest();
          });
        }
        return MaterialApp(
          title: 'FirstStep Mobile',
          debugShowCheckedModeBanner: false,
          themeMode: _appState.themeMode,
          theme: FirstStepTheme.lightTheme.copyWith(
            scaffoldBackgroundColor: Colors.white,
            textTheme: FirstStepTheme.lightTheme.textTheme.apply(
              fontFamily: 'Geologica',
            ),
            extensions: [WelcomeTokens.light, HomeTokens.light],
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Geologica',
            ),
            scaffoldBackgroundColor: WelcomeTokens.dark.bg,
            extensions: [WelcomeTokens.dark, HomeTokens.dark],
          ),
          home: Builder(
            builder: (ctx) {
              final content = AuthGate(auth: _auth, appState: _appState);
              final screenWidth = MediaQuery.of(ctx).size.width;
              final isDesktopWeb = kIsWeb && screenWidth > 520;

              if (isDesktopWeb && _usePhoneMockup) {
                return _buildDesktopPhoneCanvas(content);
              }
              return content;
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopPhoneCanvas(Widget appChild) {
    return Scaffold(
      backgroundColor: const Color(0xFF071217),
      body: Stack(
        children: [
          Positioned(
            left: 40,
            top: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FirstStepColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FirstStepColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 13, color: FirstStepColors.neonTeal),
                      SizedBox(width: 6),
                      Text(
                        'FOCUS · ANDROID FRAME',
                        style: TextStyle(
                          color: FirstStepColors.neonTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'FirstStep Mobile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Auth0 · 5-tab shell',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
          Positioned(
            right: 40,
            top: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13222A),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1F3845)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                _usePhoneMockup ? Icons.fullscreen_rounded : Icons.phone_android_rounded,
                size: 16,
                color: FirstStepColors.neonTeal,
              ),
              label: Text(
                _usePhoneMockup ? 'Full Screen' : 'Android Frame',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: () => setState(() => _usePhoneMockup = !_usePhoneMockup),
            ),
          ),
          Center(
            child: Container(
              width: 412,
              height: 915,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF1A252C), width: 12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(child: appChild),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2C3E4A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 108,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
