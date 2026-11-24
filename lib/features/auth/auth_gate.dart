import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../features/onboarding/onboarding_flow.dart';
import '../../features/shell/focus_shell.dart';
import '../../features/welcome/welcome_flow.dart';
import '../../state/app_state.dart';
import 'checkout_redirect_screen.dart';
import 'staff_website_banner.dart';

/// Routes by AuthController phase. Fail closed until bootstrap succeeds.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.appState,
  });

  final AuthController auth;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        switch (auth.phase) {
          case AuthPhase.booting:
          case AuthPhase.authenticating:
          case AuthPhase.bootstrapping:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF023345))),
            );
          case AuthPhase.staffBlocked:
            return StaffWebsiteBanner(
              websiteUrl: auth.staffWebsiteUrl,
              onSignOut: () => auth.signOut(),
            );
          case AuthPhase.candidate:
            if (auth.needsCheckout) {
              return CheckoutRedirectScreen(auth: auth);
            }
            if (auth.showOnboarding) {
              return OnboardingFlow(auth: auth, appState: appState);
            }
            return FocusShell(appState: appState, auth: auth);
          case AuthPhase.error:
            return _AuthErrorScreen(
              message: auth.errorMessage ?? 'Something went wrong.',
              onRetry: () => auth.dismissErrorToSignedOut(),
            );
          case AuthPhase.signedOut:
            return WelcomeFlow(
              onFinished: () {},
              currentThemeMode: appState.themeMode,
              onThemeModeChanged: appState.setThemeMode,
              auth: auth,
            );
        }
      },
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF023345),
                ),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
