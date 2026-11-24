import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_client.dart';
import '../../../shared_widgets/app_nav.dart';
import '../../../theme/home_tokens.dart';
import '../learn_store.dart';
import '../widgets/badge_shape.dart';

export '../../profile/screens/profile_badges.dart' show openBadges;

void showLearnToast(BuildContext context, String msg) {
  final t = HomeTokens.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: t.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Bottom inset for sticky sheet footers.
/// Uses [MediaQuery.viewPadding] so 3-button / gesture nav bars are cleared
/// even when [showModalBottomSheet.useSafeArea] only protects the top edge.
EdgeInsets learnSheetFooterPadding(BuildContext context) {
  final bottom = MediaQuery.viewPaddingOf(context).bottom;
  return EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom);
}

Future<void> openQuiz(BuildContext context, {ApiClient? api, VoidCallback? onDone}) {
  if (api != null) return openLiveQuiz(context, api, onDone: onDone);
  final t = HomeTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(
        height: h,
        child: const _QuizFlowSheet(),
      );
    },
  );
}

Future<void> openShareStory(BuildContext context, {ApiClient? api, VoidCallback? onDone}) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final mq = MediaQuery.of(sheet);
      // Keyboard only here — system nav is handled on the sticky footer.
      final keyboard = mq.viewInsets.bottom;
      final h = (mq.size.height * 0.8).clamp(320.0, mq.size.height - mq.viewPadding.top - 8);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: h,
          child: _ShareStoryScreen(asSheet: true, api: api, onDone: onDone),
        ),
      );
    },
  );
}

Future<void> openStorySheet(BuildContext context, InterviewStory story) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: !kIsWeb && Platform.isIOS,
    backgroundColor: HomeTokens.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _StorySheet(story: story),
  );
}

Future<void> openTopicSheet(
  BuildContext context, {
  String title = '',
  String body = '',
  String category = '',
  String date = '',
  bool signedIn = false,
  VoidCallback? onMarkRead,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: !kIsWeb && Platform.isIOS,
    backgroundColor: HomeTokens.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TopicSheet(
      title: title,
      body: body,
      category: category,
      date: date,
      signedIn: signedIn,
      onMarkRead: onMarkRead,
    ),
  );
}

Future<void> openInterviewPrep(
  BuildContext context, {
  String? webAppUrl,
  required bool isPremium,
}) {
  final root = (webAppUrl ?? '').replaceAll(RegExp(r'/+$'), '');
  if (isPremium && root.isNotEmpty) {
    final uri = Uri.tryParse('$root/interview-prep/ai-voice-interview');
    if (uri != null) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  return openWebSheet(context, webKey: 'ai', isPremium: isPremium);
}

Future<void> openWebSheet(
  BuildContext context, {
  required String webKey,
  required bool isPremium,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: HomeTokens.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final h = MediaQuery.sizeOf(sheet).height * 0.8;
      return SizedBox(
        height: h,
        child: _WebSheet(webKey: webKey, isPremium: isPremium),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Quiz (80% bottom sheet)
// ---------------------------------------------------------------------------

Future<void> openSkillCheck(
  BuildContext context,
  ApiClient api,
  String slug, {
  VoidCallback? onDone,
}) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) {
      final mq = MediaQuery.of(sheet);
      final h = (mq.size.height * 0.85).clamp(
        320.0,
        mq.size.height - mq.viewPadding.top - 8,
      );
      return SizedBox(
        height: h,
        child: _SkillCheckQuiz(api: api, slug: slug, onDone: onDone),
      );
    },
  );
}

class _SkillCheckQuiz extends StatefulWidget {
  const _SkillCheckQuiz({required this.api, required this.slug, this.onDone});
  final ApiClient api;
  final String slug;
  final VoidCallback? onDone;

  @override
  State<_SkillCheckQuiz> createState() => _SkillCheckQuizState();
}

class _SkillCheckQuizState extends State<_SkillCheckQuiz> {
  List<Map<String, dynamic>> _questions = const [];
  final Map<String, String> _answers = {};
  String _title = 'Skill check';
  int _index = 0;
  bool _loading = true;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await widget.api.startSkillCheck(widget.slug);
      final raw = json['questions'];
      final questions = raw is List
          ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _title = '${json['title'] ?? widget.slug}'.trim().isEmpty
            ? 'Skill check'
            : '${json['title'] ?? widget.slug}'.trim();
        _questions = questions;
        _loading = false;
        if (questions.isEmpty) _error = 'This skill check has no questions yet.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not start this skill check.';
      });
    }
  }

  Future<void> _submit() async {
    try {
      // Web parity: answers are option text strings, not A/B/C/D letters.
      final json = await widget.api.submitSkillCheck(widget.slug, _answers);
      if (!mounted) return;
      setState(() => _result = '${json['score'] ?? json['correct'] ?? 'Saved'}');
      widget.onDone?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not submit this skill check.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_result != null) {
      return Padding(
        padding: learnSheetFooterPadding(context).copyWith(left: 24, right: 24, top: 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: t.mute),
              ),
            ),
            const Spacer(),
            Text(
              'Score $_result',
              style: TextStyle(color: t.ink, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Badges you earned show under Learn → Badges.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.mute, fontSize: 14),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
    if (_error != null || _questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? 'No questions', style: TextStyle(color: t.ink)),
        ),
      );
    }
    final question = _questions[_index];
    final options = _skillCheckOptions(question['options']);
    final id = '${question['id'] ?? _index}';
    final prompt = '${question['prompt'] ?? question['question'] ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: t.mute),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              Text(
                'Question ${_index + 1} / ${_questions.length}',
                style: TextStyle(color: t.mute, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                prompt.isEmpty ? 'Question ${_index + 1}' : prompt,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink, height: 1.35),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _answers[id] = options[i]),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.ink,
                      backgroundColor: _answers[id] == options[i] ? t.tealSoft : null,
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${options[i]}',
                      style: const TextStyle(fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: learnSheetFooterPadding(context),
          child: FilledButton(
            onPressed: _answers[id] == null
                ? null
                : () {
                    if (_index + 1 >= _questions.length) {
                      _submit();
                    } else {
                      setState(() => _index += 1);
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: t.ctaBg,
              foregroundColor: t.ctaInk,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_index + 1 >= _questions.length ? 'Submit' : 'Next'),
          ),
        ),
      ],
    );
  }
}

/// Skill-check options are a string[] on the API (web stores the chosen string).
List<String> _skillCheckOptions(dynamic options) {
  if (options is List) {
    return options.map((item) => '$item'.trim()).where((text) => text.isNotEmpty).toList();
  }
  if (options is Map) {
    return ['A', 'B', 'C', 'D']
        .map((key) => '${options[key] ?? ''}'.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }
  return const [];
}

/// Backend skill checks use string[] options; weekly MCQ uses A–D maps.
Map<String, String> _optionMap(dynamic options) {
  if (options is Map) {
    return {
      for (final entry in options.entries)
        if ('${entry.value}'.trim().isNotEmpty) '${entry.key}': '${entry.value}',
    };
  }
  if (options is List) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final map = <String, String>{};
    for (var i = 0; i < options.length && i < letters.length; i++) {
      final text = '${options[i]}'.trim();
      if (text.isNotEmpty) map[letters[i]] = text;
    }
    return map;
  }
  return const {};
}

Future<void> openLiveQuiz(BuildContext context, ApiClient api, {VoidCallback? onDone}) {
  final t = HomeTokens.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(sheet).height * 0.8,
      child: _LiveQuiz(api: api, onDone: onDone),
    ),
  );
}

class _LiveQuiz extends StatefulWidget {
  const _LiveQuiz({required this.api, this.onDone});
  final ApiClient api;
  final VoidCallback? onDone;

  @override
  State<_LiveQuiz> createState() => _LiveQuizState();
}

class _LiveQuizState extends State<_LiveQuiz> {
  List<Map<String, dynamic>> _questions = const [];
  final Map<String, String> _answers = {};
  int _index = 0;
  bool _loading = true;
  int? _score;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await widget.api.startWeeklyMcq();
      final raw = json['questions'];
      final questions = raw is List
          ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
        if (json['done'] == true) _score = int.tryParse('${json['score']}');
        if (questions.isEmpty && json['done'] != true) {
          _error = 'No SQL or Python questions are in the bank yet.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this week\'s questions.';
      });
    }
  }

  Future<void> _submit() async {
    try {
      final answers = _answers.entries.map((entry) => {'id': entry.key, 'answer': entry.value}).toList();
      final json = await widget.api.submitWeeklyMcq(answers);
      if (!mounted) return;
      setState(() => _score = int.tryParse('${json['score']}') ?? 0);
      widget.onDone?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not submit this week\'s questions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_score != null) {
      return Center(child: Text('Score $_score / ${_questions.length}', style: TextStyle(color: t.ink, fontSize: 20, fontWeight: FontWeight.w700)));
    }
    if (_error != null || _questions.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? 'No questions', style: TextStyle(color: t.ink))));
    }
    final question = _questions[_index];
    final options = question['options'];
    final map = options is Map ? Map<String, dynamic>.from(options) : const <String, dynamic>{};
    final id = '${question['id']}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${_index + 1} / ${_questions.length}', style: TextStyle(color: t.mute)),
          const SizedBox(height: 12),
          Text('${question['question']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink)),
          const SizedBox(height: 12),
          for (final letter in ['A', 'B', 'C', 'D'])
            if ('${map[letter] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => setState(() => _answers[id] = letter),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.ink,
                    backgroundColor: _answers[id] == letter ? t.tealSoft : null,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: Text('$letter. ${map[letter]}')),
                ),
              ),
          const Spacer(),
          FilledButton(
            onPressed: _answers[id] == null
                ? null
                : () {
                    if (_index + 1 >= _questions.length) {
                      _submit();
                    } else {
                      setState(() => _index += 1);
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: t.ctaBg, foregroundColor: t.ctaInk, minimumSize: const Size.fromHeight(48)),
            child: Text(_index + 1 >= _questions.length ? 'Submit' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _QuizFlowSheet extends StatefulWidget {
  const _QuizFlowSheet();

  @override
  State<_QuizFlowSheet> createState() => _QuizFlowSheetState();
}

class _QuizFlowSheetState extends State<_QuizFlowSheet> {
  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: t.card,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: _showResults
                ? _ResultsBody(
                    onDone: () => Navigator.pop(context),
                  )
                : _QuizBody(
                    onExit: () => Navigator.pop(context),
                    onNext: () => setState(() => _showResults = true),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuizBody extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onNext;

  const _QuizBody({required this.onExit, required this.onNext});

  @override
  State<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<_QuizBody> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Column(
      children: [
        _FullTop(
          title: "This week's questions",
          trailing: Text(
            '7/10',
            style: TextStyle(fontSize: 13, color: t.mute),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < 10; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == 9 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < 6
                          ? t.peach.fg
                          : i == 6
                              ? t.peach.bg
                              : t.line,
                      borderRadius: BorderRadius.circular(3),
                      border: i == 6
                          ? Border.all(color: t.peach.fg, width: 1.5)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  _Chip(label: 'Python', pastel: t.peach),
                  const SizedBox(width: 8),
                  Text('Data Engineer',
                      style: TextStyle(fontSize: 13, color: t.mute)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'What does this print?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.line),
                ),
                child: Text(
                  'nums = [1, 2, 3]\n'
                  'out = [n * 2 for n in nums if n % 2]\n'
                  'print(out)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: t.ink,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final e in const [
                (0, 'A', '[2, 4, 6]'),
                (1, 'B', '[2, 6]'),
                (2, 'C', '[4]'),
                (3, 'D', '[1, 3]'),
              ])
                _QuizOpt(
                  letter: e.$2,
                  text: e.$3,
                  state: _picked == null
                      ? null
                      : e.$1 == 1
                          ? true
                          : (_picked == e.$1 ? false : null),
                  onTap: () => setState(() => _picked = e.$1),
                ),
            ],
          ),
        ),
        Padding(
          padding: learnSheetFooterPadding(context),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onExit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.ink,
                    side: BorderSide(color: t.line),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Save & exit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.ctaBg,
                    foregroundColor: t.ctaInk,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizOpt extends StatelessWidget {
  final String letter;
  final String text;
  final bool? state; // true=right, false=wrong, null=neutral
  final VoidCallback onTap;

  const _QuizOpt({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    Color bg = t.card;
    Color fg = t.ink;
    Color border = t.line;
    TextDecoration? deco;
    if (state == true) {
      bg = t.mint.bg;
      fg = t.mint.fg;
      border = Colors.transparent;
    } else if (state == false) {
      bg = const Color(0xFFEBEBE4);
      fg = t.mute;
      border = Colors.transparent;
      deco = TextDecoration.lineThrough;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: state == true ? t.mint.fg : const Color(0xFFEBEBE4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: state == true ? t.mint.bg : t.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: fg,
                      decoration: deco,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class _ResultsBody extends StatelessWidget {
  final VoidCallback onDone;

  const _ResultsBody({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Column(
      children: [
        const _FullTop(title: "This week's results"),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(
                      progress: 0.7,
                      track: t.line,
                      value: t.peach.fg,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '7',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: t.ink,
                              height: 1,
                            ),
                          ),
                          Text(
                            'out of 10',
                            style: TextStyle(fontSize: 12, color: t.mute),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nice work, Sai',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "You beat last week's 5/10.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.mute),
              ),
              const SizedBox(height: 22),
              Text(
                'Topics to revisit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 8),
              _TopicRow(
                title: 'Window functions',
                sub: '2 questions missed',
                onLearn: () {
                  Navigator.pop(context);
                  openWebSheet(context, webKey: 'paths', isPremium: true);
                },
              ),
              _TopicRow(
                title: 'Python list comprehensions',
                sub: '1 question missed',
                onLearn: () {
                  Navigator.pop(context);
                  openWebSheet(context, webKey: 'paths', isPremium: true);
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.lavender.bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const BadgeShape(
                      shape: 'notch',
                      colorKey: 'lav',
                      glyph: 'SQL',
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Badge earned: SQL Ace',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                            ),
                          ),
                          Text(
                            'Score 7+ on a SQL week',
                            style: TextStyle(fontSize: 12.5, color: t.mute),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: learnSheetFooterPadding(context),
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: t.ctaBg,
              foregroundColor: t.ctaInk,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback onLearn;

  const _TopicRow({
    required this.title,
    required this.sub,
    required this.onLearn,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
                Text(sub, style: TextStyle(fontSize: 12.5, color: t.mute)),
              ],
            ),
          ),
          TextButton(
            onPressed: onLearn,
            child: Text('Learn', style: TextStyle(color: t.teal)),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color value;

  _ScoreRingPainter({
    required this.progress,
    required this.track,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final trackP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = track;
    final valueP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = value;
    canvas.drawCircle(c, r, trackP);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      valueP,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress;
}

// ---------------------------------------------------------------------------
// Share story
// ---------------------------------------------------------------------------

class _ShareStoryScreen extends StatefulWidget {
  final bool asSheet;
  final ApiClient? api;
  final VoidCallback? onDone;
  const _ShareStoryScreen({this.asSheet = false, this.api, this.onDone});

  @override
  State<_ShareStoryScreen> createState() => _ShareStoryScreenState();
}

class _ShareStoryScreenState extends State<_ShareStoryScreen> {
  String _round = 'Technical';
  String _outcome = 'Offer';
  String _duration = '1 hour';
  final _company = TextEditingController();
  final _role = TextEditingController();
  final _questions = TextEditingController();
  final _tip = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.api == null) {
      _company.text = 'Amazon';
      _role.text = 'Data Engineer II';
      _questions.text = 'Second highest salary per department (SQL)\nDesign a clickstream pipeline';
    }
  }

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    _questions.dispose();
    _tip.dispose();
    super.dispose();
  }

  static const _durations = [
    '15 min',
    '30 min',
    '1 hour',
    '2 hours',
    '3 hours',
    '4 hours',
    '6 hours',
    '8 hours',
  ];

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final form = ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const _FieldLabel('Company'),
                  _Inp(controller: _company),
                  const _FieldLabel('Role'),
                  _Inp(controller: _role),
                  const _FieldLabel('Round'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in [
                        'Phone screen',
                        'Technical',
                        'Onsite',
                        'Final',
                        'HR',
                      ])
                        _PickChip(
                          label: r,
                          on: _round == r,
                          onTap: () => setState(() => _round = r),
                        ),
                    ],
                  ),
                  const _FieldLabel('How long was it?'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in _durations) ...[
                          _PickChip(
                            label: d,
                            on: _duration == d,
                            onTap: () => setState(() => _duration = d),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const _FieldLabel('Questions they asked'),
                  _Area(controller: _questions),
                  const _FieldLabel('How did it go?'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final o in ['Offer', 'Rejected', 'Waiting'])
                        _PickChip(
                          label: o,
                          on: _outcome == o,
                          onTap: () => setState(() => _outcome = o),
                        ),
                    ],
                  ),
                  const _FieldLabel('One tip for others'),
                  _Area(
                    controller: _tip,
                    hint: 'What would you tell someone before this interview?',
                  ),
                  if (widget.api == null) ...[
                    const _FieldLabel('Tagged as'),
                    Row(
                      children: [
                        _Chip(label: 'Data Engineer', pastel: t.lavender),
                        const SizedBox(width: 6),
                        _Chip(label: '4 years', pastel: t.sky),
                        const SizedBox(width: 8),
                        Text(
                          'from your profile',
                          style: TextStyle(fontSize: 12.5, color: t.mute),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      'We tag the story from your profile after review.',
                      style: TextStyle(fontSize: 12.5, color: t.mute),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.butter.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const BadgeShape(
                          shape: 'split',
                          colorKey: 'but',
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earn a badge + rewards',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.ink,
                                ),
                              ),
                              Text(
                                'Once your story is approved, you get the "First story" badge and rewards dollars.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: t.ink.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.api == null
                        ? 'Shown with your first name (Sai). We review every story before it\'s published and remove anything personal or confidential.'
                        : 'Shown with your first name. We review every story before it\'s published and remove anything personal or confidential.',
                    style: TextStyle(fontSize: 12.5, color: t.mute, height: 1.4),
                  ),
                ],
    );

    final submit = Padding(
              padding: learnSheetFooterPadding(context),
              child: FilledButton(
                onPressed: () async {
                  final api = widget.api;
                  if (api != null && _company.text.trim().isEmpty) {
                    showLearnToast(context, 'Add the company before you submit.');
                    return;
                  }
                  if (api != null) {
                    try {
                      await api.submitInterviewStory({
                        'company': _company.text.trim(),
                        'role': _role.text.trim(),
                        'round': _round,
                        'outcome': _outcome,
                        'duration': _duration,
                        'questions': _questions.text.trim(),
                        'tip': _tip.text.trim(),
                      });
                    } catch (_) {
                      if (!context.mounted) return;
                      showLearnToast(context, 'Could not submit that story.');
                      return;
                    }
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  widget.onDone?.call();
                  showLearnToast(
                    context,
                    'Thanks! We’ll review your story and let you know when it’s live.',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: t.ctaBg,
                  foregroundColor: t.ctaInk,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text('Submit for review'),
              ),
            );

    if (widget.asSheet) {
      return Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: t.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Share your story',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: t.mute),
                ),
              ],
            ),
          ),
          Expanded(child: form),
          submit,
        ],
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            const _FullTop(title: 'Share your story'),
            Expanded(child: form),
            submit,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

class _StorySheet extends StatefulWidget {
  final InterviewStory story;

  const _StorySheet({required this.story});

  @override
  State<_StorySheet> createState() => _StorySheetState();
}

class _StorySheetState extends State<_StorySheet> {
  bool helpful = false;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final s = widget.story;
    final pastel = _pastelOf(t, s.pastel);
    final qs = s.questions.isEmpty
        ? const [
            'Python basics: lists, dicts and generators',
            'How Spark decides the number of partitions',
            'Why do you want to work here?',
          ]
        : s.questions;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _CompanyTile(letter: s.company[0], pastel: pastel),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.company} · ${s.role}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                      Text(
                        '${s.by} · ${s.meta} · ${s.when}',
                        style: TextStyle(fontSize: 12.5, color: t.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(label: s.round, pastel: t.lavender),
                const SizedBox(width: 6),
                _Chip(
                  label: s.outcome,
                  pastel: s.outcome == 'Offer'
                      ? t.mint
                      : s.outcome == 'Waiting'
                          ? t.butter
                          : Pastel(t.line, t.mute),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Questions they asked',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < qs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${i + 1}. ${qs[i]}',
                  style: TextStyle(fontSize: 13.5, color: t.ink, height: 1.4),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'How it went',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.how.isEmpty ? s.excerpt : s.how,
              style: TextStyle(fontSize: 13.5, color: t.ink, height: 1.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.butter.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                s.tip.isEmpty
                    ? 'Revise the basics the night before. They moved fast through the easy questions.'
                    : s.tip,
                style: TextStyle(
                  fontSize: 13.5,
                  color: t.butter.fg,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Was this helpful?',
                    style: TextStyle(fontSize: 13.5, color: t.mute)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => helpful = !helpful);
                    if (helpful) {
                      showLearnToast(context, 'Thanks — glad it helped.');
                    }
                  },
                  icon: Icon(
                    helpful
                        ? Icons.thumb_up_alt
                        : Icons.thumb_up_alt_outlined,
                    size: 18,
                    color: helpful ? t.teal : t.ink,
                  ),
                  label: Text(
                    helpful ? 'Helpful' : 'Mark helpful',
                    style: TextStyle(color: helpful ? t.teal : t.ink),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TopicSheet extends StatelessWidget {
  final String title;
  final String body;
  final String category;
  final String date;
  final bool signedIn;
  final VoidCallback? onMarkRead;

  const _TopicSheet({
    this.title = '',
    this.body = '',
    this.category = '',
    this.date = '',
    this.signedIn = false,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final useMock = !signedIn && title.isEmpty;
    final meta = [
      if (category.isNotEmpty) category,
      if (date.isNotEmpty) date,
    ].join(' · ');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Chip(label: 'Topic of the Day · 2-min read', pastel: t.sky),
            const SizedBox(height: 10),
            Text(
              useMock ? 'What interviewers mean by "idempotent" pipelines' : title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            Text(
              useMock
                  ? 'Data Engineer · today'
                  : (meta.isEmpty ? 'Topic of the Day' : meta),
              style: TextStyle(fontSize: 13, color: t.mute),
            ),
            const SizedBox(height: 14),
            Text(
              useMock
                  ? 'An idempotent job gives the same result whether it runs once or five times. If yesterday\'s load fails halfway and you re-run it, nothing should be duplicated.'
                  : body,
              style: TextStyle(fontSize: 14.5, color: t.ink, height: 1.5),
            ),
            if (useMock) ...[
              const SizedBox(height: 14),
              Text(
                'How to show it in an interview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1. Load into a staging table, then MERGE / upsert on a key.\n'
                '2. Partition by date and overwrite the whole partition on re-run.\n'
                '3. Use run IDs so a retry can tell what\'s already done.',
                style: TextStyle(fontSize: 14, color: t.ink, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.butter.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Say it in one line: "Every job I build can be safely re-run."',
                  style: TextStyle(fontSize: 13.5, color: t.butter.fg),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                onMarkRead?.call();
                Navigator.pop(context);
                showLearnToast(
                  context,
                  'Marked as read. Counts toward "Read 3 Topics of the Day".',
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Mark as read'),
            ),
          ],
        );
      },
    );
  }
}

class _WebSheet extends StatelessWidget {
  final String webKey;
  final bool isPremium;

  const _WebSheet({required this.webKey, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = switch (webKey) {
      'ai' => (
          'AI mock interview',
          'Talk through real interview questions with an AI interviewer and get feedback on your answers. Needs your camera and mic, about 15–45 minutes.',
          true,
          Icons.mic_none_rounded,
          t.lavender,
        ),
      'human' => (
          'Human mock interview',
          'Book a practice interview with a real interviewer and get honest feedback.',
          false,
          Icons.groups_outlined,
          t.sky,
        ),
      'code' => (
          'Coding practice',
          'Solve coding problems in a real editor with test cases, like the real thing.',
          true,
          Icons.code_rounded,
          t.mint,
        ),
      _ => (
          'Learning paths',
          'Step-by-step paths for your role. Pick one by your level and how much time you have each day.',
          false,
          Icons.route_outlined,
          t.peach,
        ),
    };
    final locked = info.$3 && !isPremium;
    final pastel = info.$5;

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomSafe),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: t.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: pastel.bg,
                shape: BoxShape.circle,
                border: Border.all(color: t.line),
              ),
              child: Icon(Icons.laptop_mac_rounded, size: 34, color: pastel.fg),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Works best on a laptop',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open it on firststepjob.com for the full experience.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: t.mute),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? t.bg : pastel.bg.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: pastel.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.line),
                  ),
                  child: Icon(info.$4, color: pastel.fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.$1,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: t.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.$2,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: t.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (locked) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.butter.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: t.butter.fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Included in Premium & Premium Plus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.butter.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (locked) ...[
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                openExternal(AppUrls.plans);
              },
              style: FilledButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('See plans'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.ink,
                side: BorderSide(color: t.line, width: 1.2),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Not now'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Open FirstStep on your laptop from the link below.',
                    ),
                    backgroundColor: t.ink,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('Email me the link'),
              style: FilledButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                openExternal(AppUrls.site);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open on web'),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.ink,
                side: BorderSide(color: t.line, width: 1.2),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _FullTop extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _FullTop({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: t.ink),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: trailing == null
                ? const SizedBox.shrink()
                : Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Pastel pastel;

  const _Chip({required this.label, required this.pastel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: pastel.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: pastel.fg,
        ),
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  final String letter;
  final Pastel pastel;

  const _CompanyTile({required this.letter, required this.pastel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pastel.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: pastel.fg,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: t.ink,
        ),
      ),
    );
  }
}

class _Inp extends StatelessWidget {
  final String initial;
  final TextEditingController? controller;
  const _Inp({this.initial = '', this.controller});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initial : null,
      style: TextStyle(color: t.ink, fontSize: 15),
      cursorColor: t.teal,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      decoration: InputDecoration(
        filled: true,
        fillColor: t.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.teal, width: 1.4),
        ),
      ),
    );
  }
}

class _Area extends StatelessWidget {
  final String initial;
  final String? hint;
  final TextEditingController? controller;
  const _Area({this.initial = '', this.hint, this.controller});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initial : null,
      maxLines: 3,
      style: TextStyle(color: t.ink, fontSize: 15, height: 1.35),
      cursorColor: t.teal,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.mute),
        filled: true,
        fillColor: t.bg,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.teal, width: 1.4),
        ),
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;

  const _PickChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? t.ctaBg : t.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? t.ctaBg : t.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? t.ctaInk : t.ink,
          ),
        ),
      ),
    );
  }
}

Pastel _pastelOf(HomeTokens t, String key) {
  switch (key) {
    case 'mint':
      return t.mint;
    case 'but':
      return t.butter;
    case 'sky':
      return t.sky;
    case 'pch':
      return t.peach;
    default:
      return t.lavender;
  }
}
