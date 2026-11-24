import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firststep_mobile/shared_widgets/expanding_pill_nav.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

Widget _nav(
  int selected, [
  ValueChanged<int>? onSelected,
  EdgeInsets viewPadding = EdgeInsets.zero,
]) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        viewPadding: viewPadding,
        padding: viewPadding,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            ExpandingPillNav(
              selectedIndex: selected,
              onSelected: onSelected ?? (i) {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {'firststep_nav_labels_seen_v1': true}));

  testWidgets('tapping each slot reports its index', (tester) async {
    int? tapped;
    await tester.pumpWidget(_nav(2, (i) => tapped = i));
    await tester.pump();

    // Five nav-slot detectors, in tab order Learn..Profile.
    final slots = find.byType(GestureDetector);
    expect(slots, findsNWidgets(5));

    for (var i = 0; i < 5; i++) {
      tapped = null;
      await tester.tap(slots.at(i));
      await tester.pump();
      if (i == 2) {
        // Home is the selected slot — tapping it is a no-op by design.
        expect(tapped, isNull);
      } else {
        expect(tapped, i, reason: 'slot $i should report index $i');
      }
    }
  });

  testWidgets('tapping the already-selected slot is a no-op', (tester) async {
    int? tapped;
    await tester.pumpWidget(_nav(2, (i) => tapped = i));
    await tester.pump();

    await tester.tap(find.byType(GestureDetector).at(2)); // Home, already active
    await tester.pump();
    expect(tapped, isNull);
  });

  testWidgets('Applications label fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_nav(1));
    await tester.pump();

    expect(find.text('Applications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Learn hugs the left corner when active', (tester) async {
    await tester.pumpWidget(_nav(0));
    await tester.pump();

    expect(find.text('Learn'), findsOneWidget);
    final learn = tester.getRect(find.text('Learn'));
    final bar = tester.getRect(find.byType(Positioned).first);
    // Active Learn label sits in the left half of the bar.
    expect(learn.center.dx, lessThan(bar.center.dx));
  });

  testWidgets('Profile hugs the right corner when active', (tester) async {
    await tester.pumpWidget(_nav(4));
    await tester.pump();

    expect(find.text('Profile'), findsOneWidget);
    final profile = tester.getRect(find.text('Profile'));
    final bar = tester.getRect(find.byType(Positioned).first);
    // Active Profile label sits in the right half of the bar.
    expect(profile.center.dx, greaterThan(bar.center.dx));
  });

  testWidgets('active tab reveals its word, others stay icon-only',
      (tester) async {
    await tester.pumpWidget(_nav(3)); // ScoutX selected, coach seen
    await tester.pump();

    expect(find.text('ScoutX'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('first open still shows only the active label', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_nav(2));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    expect(find.text('Applications'), findsNothing);
    expect(find.text('ScoutX'), findsNothing);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('switching Profile to Applications lays out every frame',
      (tester) async {
    await tester.pumpWidget(_nav(4));
    await tester.pump();
    await tester.pumpWidget(_nav(1));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull, reason: 'frame $i');
    }
    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets('clears system gesture / nav inset', (tester) async {
    const inset = 34.0;
    await tester.pumpWidget(
      _nav(2, null, const EdgeInsets.only(bottom: inset)),
    );
    await tester.pump();

    final bar = tester.widget<Positioned>(find.byType(Positioned).first);
    expect(bar.bottom, 14 + inset);
  });
}
