import 'dart:async';

/// Dedupes overlapping refreshes. A second caller waits for the in-flight job
/// (or a single queued rerun) instead of stacking another network round-trip.
class InFlightGate {
  Future<void>? _inFlight;
  bool _rerun = false;

  bool get running => _inFlight != null;

  Future<void> run(Future<void> Function() job) {
    if (_inFlight != null) {
      _rerun = true;
      return _inFlight!;
    }
    late final Future<void> current;
    current = () async {
      try {
        do {
          _rerun = false;
          await job();
        } while (_rerun);
      } finally {
        if (identical(_inFlight, current)) _inFlight = null;
      }
    }();
    _inFlight = current;
    return current;
  }
}

class HomeBellLoad {
  const HomeBellLoad({
    required this.screen,
    required this.bell,
    required this.elapsed,
  });

  final Map<String, dynamic> screen;
  final Map<String, dynamic>? bell;
  final Duration elapsed;
}

/// Starts home and bell together so the wait is the slower call, not the sum.
Future<HomeBellLoad> joinHomeAndBell({
  required Future<Map<String, dynamic>> Function() home,
  required Future<Map<String, dynamic>> Function() bell,
}) async {
  final watch = Stopwatch()..start();
  final homeFuture = home();
  final bellFuture = () async {
    try {
      return await bell();
    } catch (_) {
      return null;
    }
  }();
  final screen = await homeFuture;
  final unread = await bellFuture;
  watch.stop();
  return HomeBellLoad(screen: screen, bell: unread, elapsed: watch.elapsed);
}

const followupRatings = ['Great', 'Okay', 'Not great', "Didn't happen"];
const followupRounds = ['Yes', 'No', 'Waiting'];

/// Body the follow-up route accepts. Empty maps are rejected by the API.
Map<String, String> followupAnswer({
  required String rating,
  required String nextRound,
}) {
  if (!followupRatings.contains(rating)) {
    throw ArgumentError('Choose how it went.');
  }
  return {
    'rating': rating,
    'nextRound': followupRounds.contains(nextRound) ? nextRound : '',
  };
}
