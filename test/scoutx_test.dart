import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firststep_mobile/features/scoutx/scoutx_data.dart';
import 'package:firststep_mobile/features/scoutx/scoutx_landing.dart';
import 'package:firststep_mobile/features/shell/focus_shell.dart';
import 'package:firststep_mobile/features/shell/tabs/scoutx_tab.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/theme/firststep_theme.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'firststep_nav_labels_seen_v1': true,
    });
  });

  testWidgets('ScoutX tab shows landing hero, not coming soon',
      (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        theme: FirstStepTheme.lightTheme,
        home: Scaffold(
          body: ScoutXTab(appState: appState),
        ),
      ),
    );
    await tester.pump();
    // Let entrance / counter animations settle without draining forever.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ScoutXLanding), findsOneWidget);
    expect(find.text('Every career page.'), findsWidgets);
    expect(find.textContaining('Beta · Go Live January 1'), findsWidgets);
    expect(find.text('Go to dashboard'), findsWidgets);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('See how it works and Watch the product are present',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FirstStepTheme.lightTheme,
        home: const Scaffold(body: ScoutXLanding()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('See how it works'), findsOneWidget);
    expect(find.text('Watch the product'), findsOneWidget);
  });

  test('ScoutX CTA opens the FirstStep website page', () {
    expect(scoutXWebUrl, 'https://firststepjob.com/scoutx');
  });

  testWidgets('shell ScoutX tab shows dashboard CTA without a PIN sheet',
      (tester) async {
    final appState = AppState()..setMainTabIndex(3);
    await tester.pumpWidget(
      MaterialApp(
        theme: FirstStepTheme.lightTheme.copyWith(
          extensions: [HomeTokens.light],
        ),
        home: FocusShell(appState: appState),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(appState.mainTabIndex, 3);
    expect(find.text('Every career page.'), findsWidgets);
    expect(find.text('Go to dashboard'), findsWidgets);
    expect(find.text('ScoutX invite-only beta'), findsNothing);
    expect(find.text('Beta user PIN'), findsNothing);
  });
}
