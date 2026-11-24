import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firststep_mobile/features/home/focus_home_view.dart';
import 'package:firststep_mobile/features/home/home_live.dart';
import 'package:firststep_mobile/features/home/home_store.dart';
import 'package:firststep_mobile/features/home/widgets/hero_arc.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget _host(HomeStore store) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: [HomeTokens.light],
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Geologica'),
      ),
      home: Scaffold(
        body: FocusHomeView(homeStore: store),
      ),
    );
  }

  group('FocusHomeView by state', () {
    testWidgets('applying shows busy card, partner and company ticker',
        (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.applying);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('6 new applications · 1 interview added'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Latest: Stripe'), findsOneWidget);
    });

    testWidgets('done shows feedback card', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.done);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("How was today's batch?"), findsOneWidget);
    });

    testWidgets('weekend shows a rest label', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.weekend);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      final spec = store.content.hero!;
      expect(spec.status, HeroStatus.rest);
      expect(spec.statusText, isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long weekend status chip does not overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [HomeTokens.light],
            textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Geologica'),
          ),
          home: const Scaffold(
            body: Center(
              child: HeroArc(
                size: 280,
                spec: HeroSpec(
                  value: 0,
                  status: HeroStatus.rest,
                  statusText: 'No applications on weekends · Back Monday',
                  label: 'applications',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('falcon maxes the arc at /999', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.falcon);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text(' / 999'), findsOneWidget);
    });

    testWidgets('basic shows proof stats and the sell card', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.basic);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Let our team apply for you'), findsOneWidget);
      expect(find.text('Refer a friend, get \$15'), findsOneWidget);
    });

    testWidgets('expired shows the renew banner', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.expired);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      final banner = store.content.banner!;
      expect(banner.kind, 'expired');
      expect(banner.title, isNotEmpty);
    });

    testWidgets('alumni shows the celebration banner', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.alumni);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      expect(store.content.banner!.kind, 'alumni');
    });

    testWidgets('getting-ready shows the setup checklist', (tester) async {
      final store = HomeStore();
      store.setState(HomeScreenState.gettingReady);
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Get set up'), findsOneWidget);
    });

    testWidgets('preview icon is available and weekend state renders', (tester) async {
      final store = HomeStore();
      await tester.pumpWidget(_host(store));
      await tester.pump(const Duration(milliseconds: 400));

      // Debug-only picker entry point (release builds hide it via kDebugMode).
      expect(find.byTooltip('Preview states'), findsOneWidget);

      // Drive the same store path the sheet uses; avoids flaky modal scrolling.
      store.setState(HomeScreenState.weekend);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(store.state, HomeScreenState.weekend);
      expect(find.text('Rest day · back Monday'), findsOneWidget);
    });
  });

  test('home action copyWith can clear a follow-up after submit', () {
    const actions = HomeActions(
      milestoneId: 'm1',
      followupId: 'task-1',
      followupTitle: 'How did Stripe go?',
    );
    final next = actions.copyWith(followupId: '', followupTitle: '');
    expect(next.milestoneId, 'm1');
    expect(next.followupId, isEmpty);
    expect(next.hasAny, isTrue);
  });

  test('weekend status text avoids Back Monday on a local weekday', () {
    final monday = DateTime(2026, 11, 23, 6, 0);
    expect(
      weekendStatusTextForDevice(
        'No applications on weekends · Back Monday',
        now: monday,
      ),
      kTeamOfflineResumesLater,
    );
    final sunday = DateTime(2026, 11, 22, 18, 0);
    expect(
      weekendStatusTextForDevice(
        'No applications on weekends · Back Monday',
        now: sunday,
      ),
      'No applications on weekends · Back Monday',
    );
  });

  test('home screen payload prefers a known company and real totals', () {
    final content = homeContentFromScreen({
      'sections': {
        'liveRibbon': {'status': 'applying', 'count': 4, 'line': 'Applying'},
        'stats': [
          {'key': 'applications', 'value': 120},
          {'key': 'hours', 'value': '12 hr'},
        ],
        'today': {
          'preview': [
            {'company': 'Unknown Labs'},
            {'company': 'Kaiser Permanente'},
          ],
        },
        'engagement': {
          'digest': [
            {
              'title': 'H-1B filing window',
              'category': 'Immigration',
              'excerpt': 'Cap season notes',
              'href': 'https://example.com/h1b',
            },
          ],
        },
        'support': {'aicName': 'Priya', 'photo': 'https://cdn.example/priya.jpg'},
        'referrals': {'referralCode': 'SAI12', 'referralPoints': 2},
      },
      'activityPreview': [
        {'id': '1'},
        {'id': '2'},
      ],
    }, firstName: 'Sai');
    expect(content.firstName, 'Sai');
    expect(content.quietTotal, 120);
    expect(content.quietHours, 12);
    expect(content.hero!.companies, ['Kaiser Permanente']);
    expect(content.partner!.photoUrl, 'https://cdn.example/priya.jpg');
    expect(content.showBusy, isTrue);
    expect(content.showFeedback, isTrue);
    expect(content.proofStats, isNotNull);
    expect(content.news.single.title, 'H-1B filing window');
    expect(content.news.single.href, 'https://example.com/h1b');
    expect(content.showRefer, isTrue);
  });

  test('coming-up rows use backend kind/title/eventDate like the website', () {
    final content = homeContentFromScreen({
      'lite': {
        'journey': {'state': 'active', 'planName': 'Premium'},
      },
      'tracker': {
        'plan': {'day': 12, 'total': 60, 'paused': false, 'label': ''},
      },
      'sections': {
        'liveRibbon': {'status': 'done', 'count': 3, 'line': 'Done for today'},
        'stats': const [],
        'today': {'preview': const []},
        'comingUp': {
          'rows': [
            {
              'kind': 'interview',
              'company': 'Amazon',
              'title': 'SDE II',
              'eventDate': '2099-01-15',
            },
            {
              'kind': 'assessment',
              'company': 'Stripe',
              'title': 'OA',
              'eventDate': '',
            },
          ],
        },
        'engagement': {'digest': const []},
        'support': const {},
      },
    }, firstName: 'Sai');
    expect(content.planLabel, 'Premium · day 12 of 60');
    expect(content.upNextFirst!.type, 'Interview');
    expect(content.upNextFirst!.title, 'Amazon · SDE II');
    expect(content.upNextFirst!.when, isNot(contains('2099')));
    expect(content.upNextRest.first.type, 'Assessment');
    expect(content.upNextRest.first.when, 'Date TBC');
  });

  test('falcon dial shows plan usage out of 999, not today', () {
    final content = homeContentFromScreen({
      'lite': {
        'journey': {'state': 'active', 'planName': 'Falcon'},
      },
      'tracker': {
        'plan': {
          'day': 55,
          'total': 182,
          'paused': false,
          'used': 187,
          'cap': 999,
          'label': '',
        },
      },
      'sections': {
        'liveRibbon': {'status': 'applying', 'count': 0, 'line': 'Applying now'},
        'stats': [
          {'key': 'applications', 'value': 187},
          {'key': 'hours', 'value': 14},
        ],
        'today': {'preview': const []},
        'engagement': {'digest': const []},
        'support': const {},
      },
    }, firstName: 'Mukul');
    expect(content.planLabel, 'Falcon · day 55 of 182');
    expect(content.hero!.value, 187);
    expect(content.hero!.max, 999);
    expect(content.hero!.label, 'applications in your plan');
    expect(content.hero!.status, HeroStatus.applying);
    expect(content.quietTotal, 187);
    expect(content.quietHours, 14);
  });

  test('falcon lite with a real zero stays 0 / 999', () {
    final content = homeContentFromScreen({
      'lite': {
        'journey': {'state': 'active', 'planName': 'Falcon Lite'},
      },
      'tracker': {
        'plan': {'day': 1, 'total': 100, 'used': 0, 'cap': 999},
      },
      'sections': {
        'liveRibbon': {'status': 'applying', 'count': 0, 'line': ''},
        'stats': [
          {'key': 'applications', 'value': 40},
        ],
        'today': {'preview': const []},
        'engagement': {'digest': const []},
        'support': const {},
      },
    });
    expect(content.hero!.value, 0);
    expect(content.hero!.max, 999);
    expect(content.hero!.label, 'applications in your plan');
    expect(content.quietTotal, 40);
  });

  test('falcon without used falls back to the lifetime total', () {
    final content = homeContentFromScreen({
      'lite': {
        'journey': {'planName': 'Falcon'},
      },
      'tracker': {
        'plan': {'day': 10, 'total': 120},
      },
      'sections': {
        'liveRibbon': {'status': 'weekend', 'count': 0, 'line': 'Rest day'},
        'stats': [
          {'key': 'applications', 'value': 50},
        ],
        'today': {'preview': const []},
        'engagement': {'digest': const []},
        'support': const {},
      },
    });
    expect(content.hero!.value, 50);
    expect(content.hero!.max, 999);
    expect(content.hero!.label, 'applications in your plan');
    expect(content.hero!.muted, isTrue);
    expect(content.hero!.status, HeroStatus.rest);
  });

  test('premium dial stays on today and does not show /999', () {
    final content = homeContentFromScreen({
      'lite': {
        'journey': {'planName': 'Premium'},
      },
      'tracker': {
        'plan': {'day': 12, 'total': 60, 'used': 0, 'cap': null},
      },
      'sections': {
        'liveRibbon': {'status': 'applying', 'count': 4, 'line': 'Applying'},
        'stats': [
          {'key': 'applications', 'value': 120},
        ],
        'today': {'preview': const []},
        'engagement': {'digest': const []},
        'support': const {},
      },
    });
    expect(content.hero!.value, 4);
    expect(content.hero!.max, 30);
    expect(content.hero!.label, 'applications today');
    expect(content.quietTotal, 120);
  });

  test('comingKindLabel matches web comingLabels', () {
    expect(comingKindLabel('interview'), 'Interview');
    expect(comingKindLabel('assessment'), 'Assessment');
    expect(comingKindLabel('phone screening'), 'Phone screening');
  });
}
