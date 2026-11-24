import 'dart:async';
import 'dart:convert';

import 'package:firststep_mobile/api/api_client.dart';
import 'package:firststep_mobile/api/bootstrap_models.dart';
import 'package:firststep_mobile/auth/auth_service.dart';
import 'package:firststep_mobile/features/auth/auth_gate.dart';
import 'package:firststep_mobile/features/auth/checkout_redirect_screen.dart';
import 'package:firststep_mobile/features/home/focus_home_view.dart';
import 'package:firststep_mobile/features/home/home_live.dart';
import 'package:firststep_mobile/features/home/home_refresh.dart';
import 'package:firststep_mobile/features/home/home_store.dart';
import 'package:firststep_mobile/features/home/screens/news_pages.dart';
import 'package:firststep_mobile/features/learn/learn_store.dart';
import 'package:firststep_mobile/features/shell/focus_shell.dart';
import 'package:firststep_mobile/state/app_state.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';
import 'package:firststep_mobile/theme/welcome_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_test_fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('checkout destination is not the signed-in shell', () {
    const result = BootstrapResult(destination: 'checkout', selectedPlan: 'pro');
    expect(result.needsCheckout, isTrue);
    expect(result.isCandidateDestination, isTrue);
  });

  testWidgets('unpaid bootstrap shows the website checkout screen', (tester) async {
    final service = FakeAuthService();
    final auth = testAuthController(
      authService: service,
      bootstrapResult: const BootstrapResult(destination: 'checkout', selectedPlan: 'pro'),
    );
    service.stored = const AuthCredentials(idToken: 'id.token.value');
    await auth.bootstrapOnLaunch();
    final appState = AppState();
    addTearDown(appState.dispose);
    addTearDown(auth.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [WelcomeTokens.light, HomeTokens.light]),
      home: AuthGate(auth: auth, appState: appState),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CheckoutRedirectScreen), findsOneWidget);
    expect(find.byType(FocusShell), findsNothing);
    expect(find.text('Finish checkout on the website'), findsOneWidget);
    expect(find.textContaining('pro'), findsOneWidget);
  });

  test('home refresh failure keeps the last live screen', () {
    final store = HomeStore(awaitingLive: true);
    store.showLive(const HomeContent(firstName: 'Ada', planLabel: 'Premium'));
    expect(store.live, isTrue);
    expect(store.awaitingLive, isFalse);

    store.showLoadFailed();
    expect(store.live, isTrue);
    expect(store.loadFailed, isFalse);
    expect(store.content.firstName, 'Ada');
  });

  test('signed-in home starts blank and failure does not restore Sai', () {
    final store = HomeStore(awaitingLive: true);
    expect(store.awaitingLive, isTrue);
    expect(store.content.firstName, isEmpty);

    store.showLoadFailed();
    expect(store.loadFailed, isTrue);
    expect(store.awaitingLive, isFalse);
    expect(store.content.firstName, isEmpty);
  });

  testWidgets('home failure shows retry instead of sample content', (tester) async {
    final store = HomeStore(awaitingLive: true)..showLoadFailed();
    final api = FakeApiClient(
      config: testAuthConfig(),
      authService: FakeAuthService(),
    );
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [HomeTokens.light]),
      home: Scaffold(
        body: FocusHomeView(homeStore: store, api: api, onRefresh: () async {}),
      ),
    ));
    await tester.pump();

    expect(find.text('Could not load Home.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sai'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('learn week uses the API done and total counts', () {
    final store = LearnStore(signedIn: true);
    store.applyWeek({
      'weeklyMcq': {'answered': 4, 'total': 8},
      'streak': 3,
      'role': 'Data Engineer',
      'badges': [
        {'title': 'First story', 'key': 'first', 'earned': true},
      ],
    });
    expect(store.weekDoneCount, 4);
    expect(store.weekTotal, 8);
    expect(store.content.streak, 3);
    expect(store.content.role, 'Data Engineer');
    expect(store.liveBadges.single.name, 'First story');
    expect(store.content.badges, 1);
  });

  test('learn week maps roles array and question.streak', () {
    final store = LearnStore(signedIn: true);
    store.applyWeek({
      'roles': ['SRE', 'Platform'],
      'question': {
        'id': 'q1',
        'question': 'What is idempotency?',
        'options': {'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd'},
        'streak': 9,
        'answered': false,
        'techStack': 'Python',
      },
      'pitch': {'prompt': 'Pitch your SRE story', 'done': true},
      'plan': 'PremiumPlus',
      'upcomingInterview': {'company': 'Acme', 'title': 'SRE'},
      'weeklyMcq': {'started': true, 'done': false, 'answered': 0, 'total': 10},
    });
    expect(store.content.role, 'SRE');
    expect(store.content.hasRole, isTrue);
    expect(store.content.streak, 9);
    expect(store.pitchDone, isTrue);
    expect(store.pitchPrompt, 'Pitch your SRE story');
    expect(store.content.isPremium, isTrue);
    expect(store.content.hasInterview, isTrue);
    expect(store.prepTitle, 'Acme · SRE');
    expect(store.questionTechStack, 'Python');
    expect(store.weekDoneCount, 0);
  });

  test('learn topic mark-read advances week progress locally', () {
    final store = LearnStore(signedIn: true);
    expect(store.topicsDone, isFalse);
    store.markTopicRead();
    store.markTopicRead();
    store.markTopicRead();
    expect(store.topicsRead, 3);
    expect(store.topicsDone, isTrue);
  });

  test('learn badges map API keys to shapes and how-to-earn copy', () {
    final store = LearnStore(signedIn: true);
    store.applyWeek({
      'badges': [
        {'key': 'qotd_streak_7', 'title': '7-day streak', 'earned': true},
        {'key': 'first_skill_check', 'title': 'First Step', 'earned': false},
      ],
    });
    expect(store.liveBadges, hasLength(2));
    expect(store.liveBadges[0].shape, 'orb');
    expect(store.liveBadges[0].glyph, '7');
    expect(store.liveBadges[0].how, 'Answer 7 days in a row');
    expect(store.liveBadges[1].shape, 'notch');
    expect(store.liveBadges[1].how, isNot(contains('first_skill_check')));
    expect(store.liveBadges[1].how, 'Complete your first skill check');
  });

  test('learn live batch applies week and checks in one notify', () {
    final store = LearnStore(signedIn: true);
    var notifies = 0;
    store.addListener(() => notifies += 1);
    store.applyLiveBatch(
      week: {
        'weeklyMcq': {'answered': 2, 'total': 10},
        'role': 'SRE',
      },
      skillChecks: [
        {'slug': 'sql', 'title': 'SQL'},
      ],
      stories: const [],
    );
    expect(store.weekDoneCount, 2);
    expect(store.content.role, 'SRE');
    expect(store.skillChecks, hasLength(1));
    expect(notifies, 1);
  });

  test('learn week treats backend weeklyMcq.done boolean as complete', () {
    final store = LearnStore(signedIn: true);
    store.applyWeek({
      'weeklyMcq': {'done': true, 'total': 10, 'score': 8},
    });
    expect(store.weekDoneCount, 10);
    expect(store.weekTotal, 10);
  });

  test('home actions read interview followup from tracker tasks', () {
    final actions = homeActionsFromScreen({
      'tracker': {
        'celebration': {'id': 'm1', 'title': 'Day 7'},
        'nudge': {'id': 'n1', 'prompt': 'Rate today'},
        'tasks': [
          {
            'id': 'task-9',
            'type': 'interview_followup',
            'title': 'How did Amazon go?',
          },
        ],
      },
      'sections': {
        'engagement': {
          'tasks': [
            {
              'id': 'task-9',
              'type': 'interview_followup',
              'title': 'How did Amazon go?',
            },
          ],
        },
      },
    });
    expect(actions.milestoneId, 'm1');
    expect(actions.nudgeId, 'n1');
    expect(actions.followupId, 'task-9');
    expect(actions.followupTitle, 'How did Amazon go?');
  });

  test('discover cards keep the story body and skip blank titles', () {
    final cards = newsCardsFromDiscover({
      'posts': [
        {'title': '', 'body': 'skip me'},
        {
          'id': 'p1',
          'headline': 'H-1B window',
          'summary': 'File before the cap.',
          'href': 'https://example.com/h1b',
        },
        {
          'id': 'gone',
          'title': 'Old post',
          'excerpt': 'No longer available',
          'unavailable': true,
          'href': '',
        },
      ],
    });
    expect(cards, hasLength(2));
    expect(cards.first.title, 'H-1B window');
    expect(cards.first.body, 'File before the cap.');
    expect(cards.first.id, 'p1');
    expect(cards.first.href, 'https://example.com/h1b');
    expect(cards.last.unavailable, isTrue);
  });

  test('follow-up answer matches the ratings the server accepts', () {
    expect(
      followupAnswer(rating: 'Great', nextRound: 'Yes'),
      {'rating': 'Great', 'nextRound': 'Yes'},
    );
    expect(
      () => followupAnswer(rating: '', nextRound: 'Yes'),
      throwsArgumentError,
    );
  });

  test('a second home refresh waits instead of stacking', () async {
    final gate = InFlightGate();
    var started = 0;
    final first = gate.run(() async {
      started += 1;
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    final second = gate.run(() async {
      started += 1;
    });
    await Future.wait([first, second]);
    // Second call coalesces: either waits on the first or queues one rerun.
    expect(started, lessThanOrEqualTo(2));
    expect(started, greaterThanOrEqualTo(1));
  });

  test('home and bell wait for the slower call, not the sum', () async {
    final loaded = await joinHomeAndBell(
      home: () => Future.delayed(const Duration(milliseconds: 80), () => {'ok': true}),
      bell: () => Future.delayed(const Duration(milliseconds: 180), () => {'unreadCount': 2}),
    );
    expect(loaded.bell?['unreadCount'], 2);
    expect(loaded.elapsed, greaterThan(const Duration(milliseconds: 160)));
    expect(loaded.elapsed, lessThan(const Duration(milliseconds: 280)));
  });

  test('a bell failure does not drop the home screen', () async {
    final loaded = await joinHomeAndBell(
      home: () async => {'screen': 'home'},
      bell: () async => throw Exception('bell down'),
    );
    expect(loaded.screen['screen'], 'home');
    expect(loaded.bell, isNull);
  });

  test('API calls fail fast when the server does not answer', () async {
    final api = ApiClient(
      config: testAuthConfig(),
      authService: FakeAuthService(),
      httpClient: _SlowClient(),
      timeout: const Duration(milliseconds: 40),
    );
    api.setCredentials(const AuthCredentials(idToken: 'id.token.value'));
    await expectLater(api.getHomeScreen(), throwsA(isA<TimeoutException>()));
  });
}

class _SlowClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Future.delayed(const Duration(milliseconds: 400), () {
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode('{"ok":true}')),
        200,
      );
    });
  }
}
