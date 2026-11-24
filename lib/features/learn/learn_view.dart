import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_client.dart';
import '../../shared_widgets/liquid_wash.dart';
import '../../shared_widgets/spring_entrance.dart';
import '../../state/app_state.dart';
import '../../theme/home_tokens.dart';
import '../home/home_refresh.dart';
import 'badge_catalog.dart';
import 'learn_store.dart';
import 'screens/learn_screens.dart';
import 'screens/pitch_page.dart';
import 'widgets/badge_shape.dart';

part 'widgets/learn_header.dart';
part 'widgets/learn_week.dart';
part 'widgets/learn_feed.dart';
class LearnTab extends StatefulWidget {
  final AppState? appState;
  final ApiClient? api;
  final String? webAppUrl;

  const LearnTab({super.key, this.appState, this.api, this.webAppUrl});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  late final LearnStore _store = LearnStore(signedIn: widget.api != null);
  final InFlightGate _loadGate = InFlightGate();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() {
    return _loadGate.run(() async {
      final api = widget.api;
      if (api == null) return;
      final showSpinner = !_store.usingLive;
      setState(() {
        _loading = showSpinner;
        if (showSpinner) _error = null;
      });
      try {
        final weekFuture = api.getLearnWeek();
        final checksFuture = api.getSkillChecks().then<Map<String, dynamic>?>((v) => v).catchError((_) => null);
        final storiesFuture = api.getInterviewStories().then<List<Map<String, dynamic>>?>((v) => v).catchError((_) => null);
        final week = await weekFuture;
        final checks = await checksFuture;
        final stories = await storiesFuture;
        if (!mounted) return;
        List<Map<String, dynamic>>? skillChecks;
        if (checks != null) {
          final list = checks['checks'] ?? checks['items'] ?? checks['skillChecks'];
          if (list is List) {
            skillChecks = list
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
          }
        }
        final mappedStories = stories
            ?.map(_storyFromJson)
            .toList();
        _store.applyLiveBatch(
          week: week,
          skillChecks: skillChecks,
          stories: mappedStories,
        );
        setState(() => _loading = false);
      } catch (_) {
        if (!mounted) return;
        if (_store.usingLive) {
          setState(() => _loading = false);
          return;
        }
        _store.markLoadFailed();
        setState(() {
          _loading = false;
          _error = 'Could not load Learn.';
        });
      }
    });
  }

  InterviewStory _storyFromJson(Map<String, dynamic> row) {
    final questions = row['questions'];
    return InterviewStory(
      company: '${row['company'] ?? ''}',
      role: '${row['role'] ?? ''}',
      round: '${row['round'] ?? ''}',
      outcome: '${row['outcome'] ?? ''}',
      by: '${row['by'] ?? ''}',
      meta: '${row['meta'] ?? ''}',
      when: '${row['when'] ?? ''}',
      pastel: '${row['pastel'] ?? 'sky'}',
      excerpt: '${row['excerpt'] ?? ''}',
      questions: questions is List ? questions.map((item) => '$item').toList() : const [],
      how: '${row['how'] ?? ''}',
      tip: '${row['tip'] ?? ''}',
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _openStatePicker() {
    final t = HomeTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Preview Learn state',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              for (final s in LearnScreenState.values)
                ListTile(
                  title: Text(
                    _stateLabel(s),
                    style: TextStyle(color: t.ink, fontWeight: FontWeight.w500),
                  ),
                  trailing: _store.state == s
                      ? Icon(Icons.check_rounded, color: t.teal)
                      : null,
                  onTap: () {
                    _store.setState(s);
                    Navigator.pop(sheet);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _stateLabel(LearnScreenState s) {
    switch (s) {
      case LearnScreenState.premium:
        return 'Premium (interview coming)';
      case LearnScreenState.elite:
        return 'Elite (no interview)';
      case LearnScreenState.basic:
        return 'Basic · no role set';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final signedIn = widget.api != null;
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final c = _store.content;
        return RefreshIndicator(
          color: t.teal,
          onRefresh: _load,
          child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 128),
          children: [
            if (_loading || _error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    if (_loading) const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                    if (_error != null) Text(_error!, textAlign: TextAlign.center),
                    if (_error != null) TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            if (signedIn && _error != null && !_loading) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Pull to retry when you are back online.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.mute, fontSize: 14),
                ),
              ),
            ] else ...[
            SpringEntrance(
              index: 0,
              child: _Header(
                content: c,
                onBadges: () => openBadges(
                  context,
                  streak: c.streak,
                  badges: widget.api != null ? _store.liveBadges : null,
                  api: widget.api,
                ),
                onPreview: _openStatePicker,
              ),
            ),
            SpringEntrance(
              index: 1,
                child: _WeekCard(
                  content: c,
                  weekDone: _store.weekDoneCount,
                  weekTotal: _store.weekTotal,
                  pitchDone: _store.pitchDone,
                  topicsRead: _store.topicsRead,
                  topicsTarget: LearnStore.topicsTarget,
                onContinue: () => openQuiz(
                  context,
                  api: widget.api,
                  onDone: _load,
                ),
                onPitch: () => openPitchTask(
                  context,
                  prompt: _store.pitchPrompt,
                  weekKey: _store.weekKey,
                  api: widget.api,
                  onDone: _load,
                ),
                onPickRole: () => widget.appState?.requestProfileRoles(),
                onOpenTopic: () => openTopicSheet(
                  context,
                  title: _store.topicTitle,
                  body: _store.topicBody,
                  category: _store.topicCategory,
                  date: _store.topicDate,
                  signedIn: signedIn,
                  onMarkRead: _store.markTopicRead,
                ),
              ),
            ),
            if (c.hasInterview)
              SpringEntrance(
                index: 2,
                child: _PrepCard(
                  title: _store.prepTitle.isEmpty ? 'Upcoming interview' : _store.prepTitle,
                  onPrep: () async {
                    await openInterviewPrep(
                      context,
                      webAppUrl: widget.webAppUrl,
                      isPremium: c.isPremium,
                    );
                    final api = widget.api;
                    if (!context.mounted || api == null) return;
                    final mark = await showDialog<bool>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                        title: const Text('Mock interview'),
                        content: const Text('Mark this AI interview as complete?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Not yet')),
                          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Complete')),
                        ],
                      ),
                    );
                    if (mark == true) {
                      try {
                        await api.completeMockInterview();
                        await _load();
                      } catch (_) {
                        if (!context.mounted) return;
                        showLearnToast(context, 'Could not mark the interview complete.');
                      }
                    }
                  },
                ),
              ),
            SpringEntrance(
              index: 3,
              child: _QuestionOfDay(
                streak: c.streak,
                answered: _store.qodAnswered,
                picked: _store.qodPicked,
                question: _store.liveQuestion,
                options: _store.liveOptions,
                techStack: _store.questionTechStack,
                signedIn: signedIn,
                wasCorrect: _store.qodWasCorrect,
                explanation: _store.qodExplanation,
                onPick: (i) async {
                  HapticFeedback.selectionClick();
                  final api = widget.api;
                  final id = _store.liveQuestionId;
                  var correct = false;
                  var explanation = '';
                  int? streak;
                  if (api != null && id.isNotEmpty && i >= 0 && i < 4) {
                    try {
                      final result = await api.answerQuestionOfDay(
                        questionId: id,
                        answer: ['A', 'B', 'C', 'D'][i],
                      );
                      correct = result['correct'] == true;
                      explanation = '${result['explanation'] ?? ''}'.trim();
                      streak = int.tryParse('${result['streak'] ?? ''}');
                    } catch (_) {
                      if (!context.mounted) return;
                      showLearnToast(context, 'Could not check that answer.');
                      return;
                    }
                  } else if (api == null) {
                    correct = i == 1;
                  } else {
                    return;
                  }
                  _store.answerQod(
                    i,
                    correct: api == null ? null : correct,
                    explanation: explanation,
                    streak: streak,
                  );
                  if (!context.mounted) return;
                  final shown = streak ?? c.streak;
                  showLearnToast(
                    context,
                    correct
                        ? 'Correct! 🔥 $shown-day streak'
                        : 'Not quite. Streak kept: $shown days',
                  );
                },
              ),
            ),
            SpringEntrance(
              index: 4,
              child: _TopicCard(
                title: _store.topicTitle,
                category: _store.topicCategory,
                signedIn: signedIn,
                onOpen: () => openTopicSheet(
                  context,
                  title: _store.topicTitle,
                  body: _store.topicBody,
                  category: _store.topicCategory,
                  date: _store.topicDate,
                  signedIn: signedIn,
                  onMarkRead: _store.markTopicRead,
                ),
              ),
            ),
            SpringEntrance(
              index: 5,
              child: _StoriesSection(
                stories: _store.liveStories,
                allowSamples: !signedIn,
                onStory: (s) => openStorySheet(context, s),
                onShare: () => openShareStory(
                  context,
                  api: widget.api,
                  onDone: _load,
                ),
              ),
            ),
            SpringEntrance(
              index: 6,
                child: _BadgeShelf(
                  badges: widget.api != null ? _store.liveBadges : null,
                  onSeeAll: () => openBadges(
                    context,
                    streak: c.streak,
                    badges: widget.api != null ? _store.liveBadges : null,
                    api: widget.api,
                  ),
                ),
            ),
            if (_store.skillChecks.isNotEmpty && widget.api != null)
              SpringEntrance(
                index: 7,
                child: _SkillChecksSection(
                  checks: _store.skillChecks,
                  onOpen: (slug) => openSkillCheck(
                    context,
                    widget.api!,
                    slug,
                    onDone: _load,
                  ),
                ),
              ),
            SpringEntrance(
              index: 8,
              child: _LaptopCard(
                isPremium: c.isPremium,
                onOpen: (key) => openWebSheet(
                  context,
                  webKey: key,
                  isPremium: c.isPremium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'New questions every Monday · Topic of the Day every morning',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: t.mute),
              ),
            ),
            ],
          ],
          ),
        );
      },
    );
  }
}
