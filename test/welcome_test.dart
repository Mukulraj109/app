import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firststep_mobile/auth/auth_controller.dart';
import 'package:firststep_mobile/features/auth/auth_gate.dart';
import 'package:firststep_mobile/features/welcome/welcome_flow.dart';
import 'package:firststep_mobile/features/welcome/screens/splash_screen.dart';
import 'package:firststep_mobile/features/welcome/screens/intro_screen.dart';
import 'package:firststep_mobile/features/welcome/screens/sign_in_screen.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/theme/welcome_tokens.dart';

import 'auth_test_fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Welcome & Sign-in Flow Tests', () {
    testWidgets('SplashScreen renders and triggers onFinish callback', (tester) async {
      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [WelcomeTokens.light]),
          home: SplashScreen(
            onFinish: () => finished = true,
          ),
        ),
      );

      // Verify splash initial frame
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance time past 1850ms splash duration
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(finished, isTrue);
    });

    testWidgets('IntroScreen renders and advances to next slide or triggers onContinue', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [WelcomeTokens.light]),
          home: IntroScreen(
            onContinue: () => continued = true,
          ),
        ),
      );

      // Verify initial slide (Slide 1: Apply)
      expect(find.textContaining('We '), findsOneWidget);
      expect(find.text('apply'), findsOneWidget);
      expect(find.text('Your team is applying'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(continued, isTrue);
    });

    testWidgets('SignInScreen renders SSO buttons, 4 pillars, and referral field', (tester) async {
      final service = FakeAuthService();
      final auth = testAuthController(authService: service);
      bool themeToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [WelcomeTokens.light]),
          home: SignInScreen(
            auth: auth,
            onToggleTheme: () => themeToggled = true,
            isDarkMode: false,
          ),
        ),
      );

      // Check header slogan and pillars
      expect(find.text('Everything you need to land your US job.'), findsOneWidget);
      expect(find.text('Apply'), findsWidgets);
      expect(find.text('Find'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Stay informed'), findsOneWidget);

      // Check SSO 2x2 grid
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Last used'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);

      // Check referral code accordion
      expect(find.text('Have a referral code?'), findsOneWidget);
      await tester.tap(find.text('Have a referral code?'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.widgetWithText(ElevatedButton, 'Apply'), findsOneWidget);

      // Tap Google sign in — Auth0 path uses fake service + bootstrap
      await tester.tap(find.text('Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(service.loginCalls, 1);
      expect(service.lastConnection, 'google-oauth2');
      expect(auth.phase, AuthPhase.candidate);
      expect(themeToggled, isFalse);
      auth.dispose();
    });

    testWidgets('WelcomeFlow navigates from Splash to Intro to SignIn', (tester) async {
      final auth = testAuthController();

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeFlow(
            auth: auth,
            onFinished: () {},
          ),
        ),
      );

      // Starts on Splash
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for splash animation to complete
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 500));

      // Now on Intro
      expect(find.byType(IntroScreen), findsOneWidget);

      // Tap Continue to go to Sign In
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 500));

      // Now on Sign In
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      auth.dispose();
    });
  });

  group('Main App Shell Tests', () {
    // Facts: AuthGate + FakeAuthService — FirstStepMobileApp Auth0 restore
    // hangs under flutter_test. Callers: flutter test. User: "build tet..."
    testWidgets('AuthGate mounts WelcomeFlow when signed out', (tester) async {
      final auth = testAuthController();
      await auth.bootstrapOnLaunch();
      final appState = AppState();
      addTearDown(appState.dispose);
      addTearDown(auth.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [WelcomeTokens.light],
          ),
          home: AuthGate(auth: auth, appState: appState),
        ),
      );
      await tester.pump();

      expect(find.byType(WelcomeFlow), findsOneWidget);
    });
  });
}
