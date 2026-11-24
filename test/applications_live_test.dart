import 'dart:convert';

import 'package:firststep_mobile/api/api_client.dart';
import 'package:firststep_mobile/auth/auth_config.dart';
import 'package:firststep_mobile/auth/auth_service.dart';
import 'package:firststep_mobile/features/applications/applications_store.dart';
import 'package:firststep_mobile/features/applications/applications_view.dart';
import 'package:firststep_mobile/theme/home_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('a failed live load stays empty and keeps the server message', () async {
    final store = ApplicationsStore(api: _client(status: 500, body: _error));
    await store.startLive();
    expect(store.jobs, isEmpty);
    expect(store.saved, isEmpty);
    expect(store.responses, isEmpty);
    expect(store.jobs.any((job) => job.company == 'Stripe'), isFalse);
    expect(store.error, 'Database timed out');
    store.dispose();
  });

  test('a live load shows only the rows the api returned', () async {
    final store = ApplicationsStore(api: _client(status: 200, body: _ok));
    await store.startLive();
    expect(store.error, isNull);
    expect(store.jobs.map((job) => job.company), ['']);
    expect(store.jobs.any((job) => job.company == 'Stripe'), isFalse);
    expect(store.firstStepTotal, 12);
    expect(store.savedTotal, 2);
    expect(store.responsesTotal, 1);
    expect(store.content.counts[1], 2);
    expect(store.content.counts[2], 1);
    expect(store.jobsHasMore, isTrue);
    expect(store.responses, hasLength(1));
    expect(store.responses.single.tag, 'Interview');
    expect(store.responses.single.received, '12 Nov');
    expect(store.responses.single.due, isNull);
    store.scheduleSearch('a');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(store.searchResults, isEmpty);
    store.dispose();
  });

  test('one dropped responses connection is retried', () async {
    final store = ApplicationsStore(
        api: _client(status: 200, body: _ok, dropResponses: 1));
    await store.startLive();
    expect(store.responsesError, isNull);
    expect(store.responses, hasLength(1));
    store.dispose();
  });

  test('a responses failure stays on the Responses pane', () async {
    final store = ApplicationsStore(
        api: _client(status: 200, body: _ok, dropResponses: 99));
    await store.startLive();
    expect(store.jobs, hasLength(1));
    expect(store.paneError, isNull);
    store.setPane(AppsPane.responses);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(store.paneError, 'Could not reach the server.');
    store.setPane(AppsPane.applied);
    expect(store.paneError, isNull);
    store.dispose();
  });

  testWidgets(
      'signed-in applications page has no sample cards and survives tab changes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
      home:
          Scaffold(body: ApplicationsTab(api: _client(status: 200, body: _ok))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.textContaining('Stripe'), findsNothing);
    expect(find.textContaining('Capital One'), findsNothing);
    expect(find.text('412'), findsNothing);
    expect(find.textContaining('by you'), findsOneWidget);
    expect(find.text('Insights'), findsNothing);
    expect(find.textContaining('12'), findsWidgets);
    expect(find.textContaining('by FirstStep'), findsOneWidget);
    expect(find.text('?'), findsWidgets);

    await tester.tap(find.textContaining('Saved').first);
    await tester.pump();
    await tester.tap(find.textContaining('Responses').first);
    await tester.pump();
    await tester.tap(find.textContaining('Applied').first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('a live store shows a user-source company and hides the sample', () async {
    final store = ApplicationsStore(api: _client(status: 200, body: (path) {
      if (path.contains('source=user')) {
        return {
          'jobs': [
            {
              'jobId': 'mine_1',
              'company': 'Acme',
              'role': 'Engineer',
              'saved': false,
            },
          ],
          'hasMore': false,
        };
      }
      return _ok(path);
    }));
    await store.startLive();
    await store.loadByYou(reset: true);
    expect(store.byYouJobs.map((job) => job.company), ['Acme']);
    expect(store.byYouJobs.any((job) => job.company == 'Vercel'), isFalse);
    expect(store.byYouCount, 4);
    store.dispose();
  });

  testWidgets('log application uses navy and closes without a framework error',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light().copyWith(extensions: [HomeTokens.light]),
      home: Scaffold(
        body: ApplicationsTab(api: _client(status: 200, body: (path) {
          if (path.contains('/applications/mine')) {
            final now = DateTime.now().toUtc();
            final key =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            return {
              'jobId': 'mine_2',
              'company': 'Acme',
              'role': 'Engineer',
              'saved': false,
              'appliedAt': '${key}T00:00:00.000Z',
            };
          }
          return _ok(path);
        })),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('By you'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Log application'),
    );
    expect(
      button.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF06334A),
    );

    await tester.tap(find.text('Log application'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Acme');
    await tester.enterText(find.byType(TextField).at(1), 'Engineer');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Log application'), findsOneWidget);
  });

  test('a failed By you load stays empty', () async {
    final store = ApplicationsStore(
        api: _client(status: 200, body: _ok, failUserSource: true));
    await store.startLive();
    await store.loadByYou(reset: true);
    expect(store.byYouJobs, isEmpty);
    expect(store.byYouError, isNotNull);
    store.dispose();
  });

  test('review yes posts feedback and advances', () async {
    final http = _Http(status: 200, body: _ok);
    final store = ApplicationsStore(api: _clientFromHttp(http));
    await store.startLive();
    expect(store.jobs, isNotEmpty);
    store.openReview();
    final job = store.reviewQueue.first;
    final ok = await store.rateUp(job);
    expect(ok, isTrue);
    store.bumpReviewIndex();
    expect(job.rate, RateValue.up);
    expect(
      http.posts.any((path) => path.contains('/feedback')),
      isTrue,
    );
    store.dispose();
  });

  test('hydrates rating from the api card', () async {
    final store = ApplicationsStore(api: _client(status: 200, body: (path) {
      if (path.contains('/month') ||
          path.contains('/saved-jobs') ||
          path.contains('/responses') ||
          path.contains('/job-requests')) {
        return _ok(path);
      }
      return {
        'access': 'full',
        'state': 'active',
        'hasMore': false,
        'jobs': [
          {
            'jobId': 'job-rated',
            'company': 'RatedCo',
            'role': 'Engineer',
            'saved': false,
            'rating': 'down',
          },
        ],
      };
    }));
    await store.startLive();
    expect(store.jobs.single.rate, RateValue.down);
    expect(store.unratedCount, 0);
    store.dispose();
  });

  test('job requests stay visible after month refresh', () async {
    final store = ApplicationsStore(api: _client(status: 200, body: _ok));
    await store.startLive();
    expect(store.requests, isNotEmpty);
    expect(store.content.showRequests, isTrue);
    await store.loadMonth(store.loadedMonthKey, force: true);
    expect(store.content.showRequests, isTrue);
    await store.loadJobs(reset: true);
    expect(store.content.showRequests, isTrue);
    expect(store.requests.first.host, 'figma.com');
    store.dispose();
  });
}

Map<String, dynamic> _error(String path) => {'error': 'Database timed out'};

Map<String, dynamic> _ok(String path) {
  if (path.contains('/month')) {
    return {
      'access': 'full',
      'state': 'active',
      'total': 12,
      'byYouCount': 4,
      'savedCount': 2,
      'responsesCount': 1,
      'days': [
        {'date': '2026-11-20', 'count': 1},
      ],
    };
  }
  if (path.contains('/saved-jobs')) {
    return {'jobs': [], 'hasMore': false, 'access': 'full', 'state': 'active'};
  }
  if (path.contains('/responses')) {
    return {
      'responses': [
        {
          'kind': 'interview',
          'title': 'Software Engineer',
          'company': 'Google',
          'date': '2026-11-12',
          'dueDate': '',
          'proofUrl': '',
        },
      ],
      'hasMore': false,
    };
  }
  if (path.contains('/job-requests')) {
    return {
      'requests': [
        {
          'id': 'req-1',
          'url': 'https://www.figma.com/careers/role',
          'status': 'sent',
          'source': 'paste',
          'createdAt': '2026-11-13T00:00:00.000Z',
        },
      ],
    };
  }
  if (path.contains('/feedback') || path.contains('/save')) {
    return {'saved': true};
  }
  return {
    'access': 'full',
    'state': 'active',
    'hasMore': true,
    'nextCursor': 'next',
    'jobs': [
      {
        'jobId': 'job-1',
        'company': '',
        'role': 'Data Engineer',
        'location': 'Remote',
        'saved': false,
        'rating': '',
      },
    ],
  };
}

ApiClient _clientFromHttp(_Http http) {
  final api = ApiClient(
    config: AuthConfig.fromEnvironment,
    authService: _Auth(),
    httpClient: http,
  );
  api.setCredentials(const AuthCredentials(idToken: 'header.payload.sig'));
  return api;
}

ApiClient _client({
  required int status,
  required Map<String, dynamic> Function(String path) body,
  int dropResponses = 0,
  bool failUserSource = false,
}) {
  return _clientFromHttp(_Http(
    status: status,
    body: body,
    dropResponses: dropResponses,
    failUserSource: failUserSource,
  ));
}

class _Auth implements AuthService {
  @override
  Future<void> clearCredentials() async {}

  @override
  Future<AuthCredentials> loginWithConnection(String connection) async {
    return const AuthCredentials(idToken: 'header.payload.sig');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthCredentials> refresh() async {
    return const AuthCredentials(idToken: 'header.payload.sig');
  }

  @override
  Future<AuthCredentials?> restore() async => null;
}

class _Http extends http.BaseClient {
  _Http({
    required this.status,
    required this.body,
    this.dropResponses = 0,
    this.failUserSource = false,
  });

  final int status;
  final Map<String, dynamic> Function(String path) body;
  final bool failUserSource;
  int dropResponses;
  final List<String> posts = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    if (request.method == 'POST') posts.add(url);
    if (request.url.path.endsWith('/responses') && dropResponses > 0) {
      dropResponses--;
      throw http.ClientException(
          'Connection closed before full header was received', request.url);
    }
    if (url.contains('%3F')) {
      throw StateError('query string was encoded into the path: $url');
    }
    if (request.url.path.endsWith('/responses') &&
        !request.url.query.contains('cursor=')) {
      throw StateError('empty cursor lost its equals: ${request.url}');
    }
    final payload = utf8.encode(jsonEncode(body(url)));
    final code = failUserSource && url.contains('source=user') ? 500 : status;
    return http.StreamedResponse(Stream.value(payload), code);
  }
}
