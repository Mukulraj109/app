import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firststep_mobile/features/applications/applications_store.dart';
import 'package:firststep_mobile/features/applications/applications_view.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

void main() {
  Widget host() {
    return MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
      home: const Scaffold(body: ApplicationsTab()),
    );
  }

  testWidgets('Applied shows day summary and Stripe card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('18 applications'), findsOneWidget);
    expect(find.text('Data Engineer'), findsWidgets);
    expect(find.textContaining('Stripe'), findsWidgets);
    expect(find.text('Resume'), findsWidgets);
  });

  testWidgets('tapping Stripe opens job sheet with Job posting', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    final stripe = find.textContaining('Stripe · Seattle');
    await tester.ensureVisible(stripe);
    await tester.pump();
    await tester.tap(stripe);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    // Smoke: navy Job posting pill label (HTML .post). User:
    // "Match Applications to 04-applications.html"
    expect(find.text('Job posting'), findsOneWidget);
    expect(find.text('How was this application?'), findsOneWidget);
    expect(find.textContaining('Tailored for this job'), findsOneWidget);
    expect(find.text('RESUME USED'), findsOneWidget);
  });

  testWidgets('Review shows stacked cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    final review = find.text('Review');
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Review today'), findsOneWidget);
    expect(find.textContaining('Data Engineer'), findsWidgets);
    expect(find.text('Skip'), findsOneWidget);
  });

  test('rateUp toggles mint on an unrated job', () {
    final store = ApplicationsStore();
    final job = store.jobs.firstWhere((j) => j.company == 'Capital One');
    expect(job.rate, RateValue.none);
    store.rateUp(job);
    expect(job.rate, RateValue.up);
  });

  testWidgets('flask switches to Elite with no Resume chip', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Resume'), findsWidgets);

    await tester.longPress(find.text('Applications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Active · Elite (no resumes)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Resume'), findsNothing);
    expect(find.textContaining('18 applications'), findsOneWidget);
  });

  test('locked mock content is flagged', () {
    final store = ApplicationsStore();
    store.setState(AppsScreenState.locked);
    expect(store.content.locked, isTrue);
  });

  testWidgets('preview switches to locked card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.longPress(find.text('Applications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final locked = find.text('Downgraded (locked)').last;
    await tester.ensureVisible(locked);
    await tester.pump();
    await tester.tap(locked);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final title = find.text('Your applications are locked');
    await tester.ensureVisible(title);
    await tester.pump();
    expect(title, findsOneWidget);
    expect(find.text('See plans ↗'), findsOneWidget);
  });

  test('day range label after two taps', () {
    final store = ApplicationsStore();
    store.selectDay('10');
    expect(store.rangeEndDay, isNull);
    store.selectDay('14');
    expect(store.rangeEndDay, '14');
    expect(store.rangeLabel, contains('to'));
  });
}
