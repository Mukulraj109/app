import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/features/applications/applications_store.dart';
import 'package:firststep_mobile/features/applications/screens/apps_extra_pages.dart';
import 'package:firststep_mobile/features/home/screens/news_pages.dart';
import 'package:firststep_mobile/features/learn/screens/learn_screens.dart';
import 'package:firststep_mobile/features/profile/screens/help_pages.dart';
import 'package:firststep_mobile/features/profile/screens/profile_screens.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

Widget _host(Widget home) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
    home: home,
  );
}

void main() {
  testWidgets('FAQ opens from Settings', (tester) async {
    final app = AppState();
    await tester.pumpWidget(
      _host(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openSettings(context, app),
            child: const Text('go'),
          ),
        ),
      )),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Settings & help'), findsWidgets);

    await tester.tap(find.text('FAQ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Plans, Pricing & Refund'), findsOneWidget);
    expect(find.text('About FirstStep'), findsWidgets);
  });

  testWidgets('Notifications page opens', (tester) async {
    await tester.pumpWidget(
      _host(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openNotifications(context),
            child: const Text('bell'),
          ),
        ),
      )),
    );
    await tester.tap(find.text('bell'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('AI news'), findsOneWidget);
  });

  testWidgets('Badges screen opens', (tester) async {
    await tester.pumpWidget(
      _host(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openBadges(context, streak: 7),
            child: const Text('badges'),
          ),
        ),
      )),
    );
    await tester.tap(find.text('badges'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Badge'), findsWidgets);
  });

  testWidgets('Applications search finds a company', (tester) async {
    final store = ApplicationsStore();
    await tester.pumpWidget(
      _host(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openApplicationsSearch(context, store),
            child: const Text('search'),
          ),
        ),
      )),
    );
    await tester.tap(find.text('search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Stripe');
    await tester.pump();
    expect(find.textContaining('Stripe'), findsWidgets);
  });

  testWidgets('Sign out confirm exists in Settings', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = AppState();
    await tester.pumpWidget(
      _host(SettingsHelpPage(appState: app)),
    );
    await tester.pump();
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('News feed opens', (tester) async {
    await tester.pumpWidget(
      _host(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openNewsFeed(context),
            child: const Text('news'),
          ),
        ),
      )),
    );
    await tester.tap(find.text('news'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('News'), findsWidgets);
    expect(find.textContaining('H-1B'), findsOneWidget);
  });

  testWidgets('Document preview opens', (tester) async {
    await tester.pumpWidget(
      _host(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openDocumentPreview(
              context,
              title: 'Intake form',
              subtitle: 'PDF',
            ),
            child: const Text('doc'),
          ),
        ),
      )),
    );
    await tester.tap(find.text('doc'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Intake form'), findsWidgets);
  });
}
