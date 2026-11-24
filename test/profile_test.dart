import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/api/bootstrap_models.dart';
import 'package:firststep_mobile/api/profile_models.dart';
import 'package:firststep_mobile/auth/auth_controller.dart';
import 'package:firststep_mobile/features/profile/profile_view.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

import 'auth_test_fakes.dart';

void main() {
  Future<AuthController> candidateAuth({
    PlanSummary plan = const PlanSummary(
      plan: 'Premium',
      categories: ['Data Engineer'],
    ),
  }) async {
    final service = FakeAuthService();
    final api = FakeApiClient(
      config: testAuthConfig(),
      authService: service,
      result: const BootstrapResult(
        destination: 'home',
        user: SessionUser(firstName: 'Sai', email: 'sai@example.com'),
      ),
      planSummary: plan,
      rewards: const RewardsSummary(balanceUsd: 30),
      badges: const [
        BadgeItem(key: 'a', title: 'A', earned: true),
        BadgeItem(key: 'b', title: 'B', earned: true),
        BadgeItem(key: 'c', title: 'C', earned: true),
      ],
    );
    final auth = AuthController(
      config: testAuthConfig(),
      authService: service,
      apiClient: api,
    );
    await auth.signInWithGoogle();
    expect(auth.phase, AuthPhase.candidate);
    return auth;
  }

  Widget host(AuthController auth) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
      home: Scaffold(
        body: ProfileTab(appState: AppState(), auth: auth),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('Premium shows plan benefit chips and live name', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth();
    await tester.pumpWidget(host(auth));
    await settle(tester);

    expect(find.text('Sai'), findsWidgets);
    expect(find.text('Your plan benefits'), findsOneWidget);
    expect(find.textContaining('Mock interview'), findsOneWidget);
    expect(find.textContaining('LinkedIn'), findsOneWidget);
    expect(find.byTooltip('Preview states'), findsNothing);
  });

  testWidgets('Premium Plus shows ScoutX benefit chip', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth(
      plan: const PlanSummary(
        plan: 'Premium Plus',
        categories: ['Data Engineer'],
      ),
    );
    await tester.pumpWidget(host(auth));
    await settle(tester);

    expect(find.text('Sai'), findsWidgets);
    expect(find.textContaining('ScoutX'), findsOneWidget);
    expect(find.textContaining('Portfolio'), findsOneWidget);
  });

  testWidgets('Premium shows intake and WhatsApp tile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth();
    await tester.pumpWidget(host(auth));
    await settle(tester);

    expect(find.text('Sai'), findsWidgets);
    expect(find.text('My WhatsApp group'), findsOneWidget);
    expect(find.text('From your intake'), findsOneWidget);
  });

  testWidgets('Basic plan hides WhatsApp and intake', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth(
      plan: const PlanSummary(plan: 'Normal Plan'),
    );
    await tester.pumpWidget(host(auth));
    await settle(tester);

    expect(find.text('Sai'), findsWidgets);
    expect(find.text('My WhatsApp group'), findsNothing);
    expect(find.text('From your intake'), findsNothing);
  });

  testWidgets('settings gear opens Settings & help', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth();
    await tester.pumpWidget(host(auth));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Settings & help'), findsWidgets);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('Location sheet stays usable with keyboard and closes cleanly',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth();
    await tester.pumpWidget(host(auth));
    await settle(tester);

    final location = find.widgetWithText(ListTile, 'Location');
    await tester.scrollUntilVisible(
      location,
      280,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.ensureVisible(location);
    await tester.pumpAndSettle();
    await tester.tap(location, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Save'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Austin, TX');

    final binding = tester.binding;
    binding.window.viewInsetsTestValue = const FakeViewPadding(bottom: 336);
    addTearDown(() => binding.window.clearViewInsetsTestValue());
    await tester.pump();

    expect(find.text('Save'), findsOneWidget);

    final sheetNav = Navigator.of(
      tester.element(find.text('Save')),
    );
    sheetNav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('Raise ticket message field closes without dispose assert',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = await candidateAuth();
    await tester.pumpWidget(host(auth));
    await settle(tester);

    await tester.tap(find.text('Support'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Raise a new ticket'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Change my details'));
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -240));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Update my city');

    await tester.tapAt(const Offset(12, 12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.takeException(), isNull);
  });
}
