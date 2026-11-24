part of '../learn_view.dart';

// --------------------------------------------------------------------------
// This week
// --------------------------------------------------------------------------

class _WeekCard extends StatelessWidget {
  final LearnContent content;
  final int weekDone;
  final int weekTotal;
  final bool pitchDone;
  final int topicsRead;
  final int topicsTarget;
  final VoidCallback onContinue;
  final VoidCallback onPitch;
  final VoidCallback onPickRole;
  final VoidCallback? onOpenTopic;

  const _WeekCard({
    required this.content,
    this.weekDone = 0,
    this.weekTotal = 10,
    this.pitchDone = false,
    this.topicsRead = 0,
    this.topicsTarget = 3,
    required this.onContinue,
    required this.onPitch,
    required this.onPickRole,
    this.onOpenTopic,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = t.peach;
    final done = weekDone;
    final total = weekTotal <= 0 ? 10 : weekTotal;
    final progress = (done / total).clamp(0.0, 1.0);
    final topicsDone = topicsRead >= topicsTarget;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CustomPaint(
                  painter: _WeekRingPainter(
                    progress: progress,
                    track: Colors.white.withValues(alpha: 0.7),
                    value: p.fg,
                  ),
                  child: Center(
                    child: Text(
                      '$done/$total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.fg,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This week',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                    Text(
                      content.hasRole
                          ? 'Resets Monday · ${content.role}'
                          : 'Questions and tasks matched to your role',
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
          if (!content.hasRole)
            _WeekItem(
              icon: Icons.person_outline_rounded,
              title: 'Pick your role to get weekly questions',
              sub: 'Takes 10 seconds',
              action: 'Pick role',
              onAction: onPickRole,
            )
          else ...[
            _WeekItem(
              icon: Icons.quiz_outlined,
              title: '10 questions: SQL & Python',
              sub: '$done of $total done',
              action: 'Continue',
              onAction: onContinue,
              progress: progress,
            ),
            _WeekItem(
              icon: Icons.mic_none_rounded,
              title: 'Record your 60-second pitch',
              sub: pitchDone ? 'Done · nice!' : 'Weekly task · 10 min',
              action: pitchDone ? null : 'Start',
              onAction: pitchDone ? null : onPitch,
              done: pitchDone,
            ),
            _WeekItem(
              icon: topicsDone ? Icons.check_rounded : Icons.menu_book_outlined,
              title: 'Read $topicsTarget Topics of the Day',
              sub: topicsDone
                  ? 'Done · nice!'
                  : '$topicsRead of $topicsTarget read',
              action: topicsDone ? null : 'Open',
              onAction: topicsDone ? null : onOpenTopic,
              done: topicsDone,
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final String? action;
  final VoidCallback? onAction;
  final double? progress;
  final bool done;

  const _WeekItem({
    required this.icon,
    required this.title,
    required this.sub,
    this.action,
    this.onAction,
    this.progress,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = t.peach;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: done ? t.mint.fg : p.fg),
          ),
          const SizedBox(width: 12),
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
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.ink.withValues(alpha: 0.7),
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.black.withValues(alpha: 0.07),
                      color: p.fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekRingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color value;

  _WeekRingPainter({
    required this.progress,
    required this.track,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 25.0;
    final trackP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = track;
    final valueP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
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
  bool shouldRepaint(covariant _WeekRingPainter old) =>
      old.progress != progress;
}

// --------------------------------------------------------------------------
// Prep / QOD / Topic
// --------------------------------------------------------------------------

class _PrepCard extends StatelessWidget {
  final VoidCallback onPrep;
  final String title;

  const _PrepCard({required this.onPrep, this.title = 'Upcoming interview'});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: t.lavender.bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.mic_none_rounded, color: t.lavender.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
                Text(
                  'Practise with a 15-min AI mock interview',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: t.ink.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onPrep,
            style: FilledButton.styleFrom(
              backgroundColor: t.ctaBg,
              foregroundColor: t.ctaInk,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Prep ↗'),
          ),
        ],
      ),
    );
  }
}

class _QuestionOfDay extends StatelessWidget {
  final int streak;
  final bool answered;
  final int? picked;
  final ValueChanged<int> onPick;
  final String question;
  final List<String> options;
  final String techStack;
  final bool signedIn;
  final bool? wasCorrect;
  final String explanation;

  const _QuestionOfDay({
    required this.streak,
    required this.answered,
    required this.picked,
    required this.onPick,
    this.question = '',
    this.options = const [],
    this.techStack = '',
    this.signedIn = false,
    this.wasCorrect,
    this.explanation = '',
  });

  static const _opts = [
    (0, 'A', 'RANK()'),
    (1, 'B', 'DENSE_RANK()'),
    (2, 'C', 'ROW_NUMBER()'),
    (3, 'D', 'NTILE()'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final useMock = !signedIn && question.isEmpty;
    final chip = techStack.isNotEmpty
        ? (techStack.length > 18 ? '${techStack.substring(0, 18)}…' : techStack)
        : (useMock ? 'SQL' : 'QOTD');
    if (signedIn && question.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question of the Day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.ink),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.line),
              ),
              child: Text(
                'No question for today yet. Pull to refresh later.',
                style: TextStyle(fontSize: 14, color: t.mute, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question of the Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: t.line),
              boxShadow: t.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.peach.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chip,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: t.peach.fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 15,
                            color: Color(0xFFF07B3F),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Keep your $streak-day streak',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: t.mute),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  useMock
                      ? 'Which window function gives each row a rank with no gaps after ties?'
                      : question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                    height: 1.4,
                  ),
                ),
                for (final o in (options.isEmpty && useMock
                    ? _opts
                    : [
                        for (var i = 0; i < options.length && i < 4; i++)
                          (i, ['A', 'B', 'C', 'D'][i], options[i]),
                      ]))
                  _QodOpt(
                    letter: o.$2,
                    text: o.$3,
                    enabled: !answered,
                    right: answered &&
                        (signedIn
                            ? wasCorrect == true && picked == o.$1
                            : o.$1 == 1),
                    wrong: answered &&
                        picked == o.$1 &&
                        (signedIn ? wasCorrect == false : o.$1 != 1),
                    onTap: () => onPick(o.$1),
                  ),
                if (answered) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      signedIn
                          ? (explanation.isEmpty ? 'Answer saved.' : explanation)
                          : 'DENSE_RANK()\nTies share a rank and the next rank follows straight on (1, 1, 2). RANK() would skip to 3.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QodOpt extends StatelessWidget {
  final String letter;
  final String text;
  final bool enabled;
  final bool right;
  final bool wrong;
  final VoidCallback onTap;

  const _QodOpt({
    required this.letter,
    required this.text,
    required this.enabled,
    required this.right,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    Color bg = t.card;
    Color fg = t.ink;
    Color border = t.line;
    TextDecoration? deco;
    if (right) {
      bg = t.mint.bg;
      fg = t.mint.fg;
      border = Colors.transparent;
    } else if (wrong) {
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
          onTap: enabled ? onTap : null,
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
                    color: right ? t.mint.fg : const Color(0xFFEBEBE4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: right ? t.mint.bg : t.ink,
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

class _TopicCard extends StatelessWidget {
  final VoidCallback onOpen;
  final String title;
  final String category;
  final bool signedIn;

  const _TopicCard({
    required this.onOpen,
    this.title = '',
    this.category = '',
    this.signedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final useMock = !signedIn && title.isEmpty;
    if (signedIn && title.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic of the Day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.ink),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.line),
              ),
              child: Text(
                'No topic for today yet.',
                style: TextStyle(fontSize: 14, color: t.mute),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic of the Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: t.card,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: t.line),
                  boxShadow: t.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: t.sky.bg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.menu_book_outlined,
                          color: t.sky.fg, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.sky.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '2-min read',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: t.sky.fg,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            useMock
                                ? 'What interviewers mean by "idempotent" pipelines'
                                : title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                              height: 1.3,
                            ),
                          ),
                          Text(
                            useMock
                                ? 'Data Engineer · new today'
                                : (category.isEmpty ? 'Today' : category),
                            style: TextStyle(fontSize: 12.5, color: t.mute),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


