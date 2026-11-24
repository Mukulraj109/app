import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firststep_mobile/api/bootstrap_models.dart';
import 'package:firststep_mobile/auth/auth_controller.dart';
import 'package:firststep_mobile/auth/auth_service.dart';
import 'package:firststep_mobile/features/auth/auth_gate.dart';
import 'package:firststep_mobile/features/auth/staff_website_banner.dart';
import 'package:firststep_mobile/features/shell/focus_shell.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';
import 'package:firststep_mobile/theme/welcome_tokens.dart';

import 'auth_test_fakes.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const [WelcomeTokens.light, HomeTokens.light],
    ),
    home: child,
  );
}

void main() {
  late FakeAuthService authService;
  late AppState appState;

  setUp(() {
    authService = FakeAuthService();
    appState = AppState();
  });

  tearDown(() {
    appState.dispose();
  });

  testWidgets('candidate destination mounts FocusShell', (tester) async {
    final auth = testAuthController(
      authService: authService,
      bootstrapResult: const BootstrapResult(destination: 'home'),
    );
    authService.stored = const AuthCredentials(idToken: 'id.token.value');
    await auth.bootstrapOnLaunch();

    await tester.pumpWidget(_wrap(AuthGate(auth: auth, appState: appState)));
    await tester.pump();

    expect(find.byType(FocusShell), findsOneWidget);
    expect(find.byType(StaffWebsiteBanner), findsNothing);
    auth.dispose();
  });

  testWidgets('staff portal shows banner and not FocusShell', (tester) async {
    final auth = testAuthController(
      authService: authService,
      bootstrapResult: const BootstrapResult(
        destination: 'portal',
        portalPath: '/super-admin/overview',
      ),
    );
    authService.stored = const AuthCredentials(idToken: 'id.token.value');
    await auth.bootstrapOnLaunch();

    await tester.pumpWidget(_wrap(AuthGate(auth: auth, appState: appState)));
    await tester.pump();

    expect(find.byType(StaffWebsiteBanner), findsOneWidget);
    expect(find.byType(FocusShell), findsNothing);
    expect(auth.staffWebsiteUrl, 'https://app.firststepjob.com/super-admin/overview');
    expect(auth.staffWebsiteUrl!.contains('token'), isFalse);
    expect(authService.stored, isNull);
    auth.dispose();
  });

  testWidgets('unknown destination mounts neither shell nor banner', (tester) async {
    final auth = testAuthController(
      authService: authService,
      bootstrapResult: const BootstrapResult(destination: 'weird'),
    );
    authService.stored = const AuthCredentials(idToken: 'id.token.value');
    await auth.bootstrapOnLaunch();

    await tester.pumpWidget(_wrap(AuthGate(auth: auth, appState: appState)));
    await tester.pump();

    expect(find.byType(FocusShell), findsNothing);
    expect(find.byType(StaffWebsiteBanner), findsNothing);
    expect(find.textContaining('Unable to continue'), findsOneWidget);
    auth.dispose();
  });
}
