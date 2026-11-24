import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firststep_mobile/auth/auth_controller.dart';
import 'package:firststep_mobile/features/auth/auth_gate.dart';
import 'package:firststep_mobile/features/welcome/welcome_flow.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/data/models/tracker_state_model.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';
import 'package:firststep_mobile/theme/welcome_tokens.dart';

import 'auth_test_fakes.dart';

void main() {
  // Facts: AuthGate + FakeAuthService (not FirstStepMobileApp) — real Auth0
  // credentialsManager.hasValidCredentials hangs under flutter_test HttpClient.
  // Callers: flutter test. User: "build tet for backend and flutter app"
  testWidgets('AuthGate mounts WelcomeFlow when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = testAuthController();
    await auth.bootstrapOnLaunch();
    final appState = AppState();
    addTearDown(appState.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [WelcomeTokens.light, HomeTokens.light]),
      home: AuthGate(auth: auth, appState: appState),
    ));
    await tester.pump();

    expect(find.byType(WelcomeFlow), findsOneWidget);
  });

  testWidgets('AuthGate stays on welcome until Auth0 bootstrap succeeds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = testAuthController();
    await auth.bootstrapOnLaunch();
    final appState = AppState();
    addTearDown(appState.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [WelcomeTokens.light, HomeTokens.light]),
      home: AuthGate(auth: auth, appState: appState),
    ));
    await tester.pump();

    // Callers: flutter test → widget_test. AuthPhase enum (no schema).
    // User: "build tet for backend and flutter app"
    expect(find.byType(WelcomeFlow), findsOneWidget);
    expect(auth.phase, AuthPhase.signedOut);
  });

  test('AppState metrics and scenarios', () {
    final state = AppState();

    expect(state.mainTabIndex, 2);
    expect(state.visibleMetricKeys.length, 4);
    expect(state.tracker.status, LiveStatusType.applying);

    state.setMainTabIndex(0);
    expect(state.mainTabIndex, 0);

    state.setTrackerScenario(const TrackerState(
      status: LiveStatusType.weekend,
      todayCount: 0,
      todayCompanies: [],
    ));
    expect(state.tracker.status, LiveStatusType.weekend);
    expect(state.tracker.todayCount, 0);

    state.setTrackerScenario(const TrackerState(
      status: LiveStatusType.done,
      todayCount: 18,
      todayCompanies: ['Acme'],
    ));
    expect(state.tracker.status, LiveStatusType.done);
    expect(state.tracker.todayCount, 18);

    state.setVisibleMetrics([
      HomeMetricKey.totalApplied,
      HomeMetricKey.hoursSaved,
    ]);
    expect(state.visibleMetricKeys.length, 2);
    expect(state.metricValue(HomeMetricKey.hoursSaved), '31');
  });
}
