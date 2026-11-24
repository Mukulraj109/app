part of '../learn_view.dart';

// --------------------------------------------------------------------------
// Stories / badges / laptop
// --------------------------------------------------------------------------

class _StoriesSection extends StatelessWidget {
  final ValueChanged<InterviewStory> onStory;
  final VoidCallback onShare;
  final List<InterviewStory> stories;

  final bool allowSamples;

  const _StoriesSection({
    required this.onStory,
    required this.onShare,
    this.stories = const [],
    this.allowSamples = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Interview stories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onShare,
                child: Text(
                  'Share yours',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (stories.isEmpty && !allowSamples)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'No published stories yet. Share yours to help the next candidate.',
              style: TextStyle(fontSize: 13, color: t.mute, height: 1.4),
            ),
          ),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final s in (stories.isEmpty
                  ? (allowSamples ? sampleStories : const <InterviewStory>[])
                  : stories)) ...[
                _StoryCard(story: s, onTap: () => onStory(s)),
                const SizedBox(width: 12),
              ],
              _ShareCard(onTap: onShare),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final InterviewStory story;
  final VoidCallback onTap;

  const _StoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final pastel = switch (story.pastel) {
      'mint' => t.mint,
      'but' => t.butter,
      'sky' => t.sky,
      'pch' => t.peach,
      _ => t.lavender,
    };
    final outPastel = story.outcome == 'Offer'
        ? t.mint
        : story.outcome == 'Waiting'
            ? t.butter
            : Pastel(t.line, t.mute);

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 262,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pastel.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      story.company[0],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: pastel.fg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${story.company} · ${story.role}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                        Text(
                          story.when,
                          style: TextStyle(fontSize: 12, color: t.mute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniChip(label: story.round, pastel: t.lavender),
                  _MiniChip(label: story.outcome, pastel: outPastel),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  story.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: t.ink,
                    height: 1.45,
                  ),
                ),
              ),
              Divider(color: t.line, height: 16),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.sky.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      story.by[0],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: t.sky.fg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${story.by} · ${story.meta}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: t.mute),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.line, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.ctaBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 22,
                    color: t.ctaInk,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your story',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              Text(
                'Help others prepare. Earn a badge and rewards.',
                style: TextStyle(fontSize: 12.5, color: t.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Pastel pastel;

  const _MiniChip({required this.label, required this.pastel});

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

/// Skill checks live below badges (not above the Learn header).
/// Phone Learn HTML has no skill-check block; web Learn hub does — this card
/// keeps the API wired without breaking the 05-learn.html top composition.
class _SkillChecksSection extends StatelessWidget {
  final List<Map<String, dynamic>> checks;
  final ValueChanged<String> onOpen;

  const _SkillChecksSection({required this.checks, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill checks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'About ten questions. Your score and badge show when you finish.',
            style: TextStyle(fontSize: 12.5, color: t.mute, height: 1.35),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: t.line),
              boxShadow: t.cardShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < checks.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.line),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final slug = '${checks[i]['slug'] ?? ''}'.trim();
                        if (slug.isNotEmpty) onOpen(slug);
                      },
                      borderRadius: BorderRadius.vertical(
                        top: i == 0 ? const Radius.circular(22) : Radius.zero,
                        bottom: i == checks.length - 1
                            ? const Radius.circular(22)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: t.lavender.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.track_changes_rounded,
                                color: t.lavender.fg,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${checks[i]['title'] ?? checks[i]['slug'] ?? 'Skill check'}',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: t.ink,
                                    ),
                                  ),
                                  Text(
                                    'Start this check',
                                    style: TextStyle(fontSize: 12.5, color: t.mute),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: t.mute),
                          ],
                        ),
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

class _BadgeShelf extends StatelessWidget {
  final VoidCallback onSeeAll;
  final List<LearnBadge>? badges;

  const _BadgeShelf({required this.onSeeAll, this.badges});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Your badges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: t.card,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: t.line),
                  boxShadow: t.cardShadow,
                ),
                child: Row(
                  children: [
                    for (final b in badgeShelfPreview(badges ?? shelfBadges))
                      Expanded(
                        child: Column(
                          children: [
                            BadgeShape(
                              shape: b.shape,
                              colorKey: b.color,
                              glyph: b.glyph,
                              size: 54,
                              locked: !b.earned,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: t.mute,
                              ),
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

class _LaptopCard extends StatelessWidget {
  final bool isPremium;
  final ValueChanged<String> onOpen;

  const _LaptopCard({required this.isPremium, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final rows = [
      (
        'paths',
        'Learning paths',
        'Pick a path by your level and the time you have',
        Icons.route_outlined,
        t.peach,
        false,
      ),
      (
        'ai',
        'AI mock interview',
        'Talk through real questions, get feedback',
        Icons.mic_none_rounded,
        t.lavender,
        true,
      ),
      (
        'human',
        'Human mock interview',
        'Book a practice interview with a real interviewer',
        Icons.groups_outlined,
        t.sky,
        false,
      ),
      (
        'code',
        'Coding practice',
        'Solve problems in a real editor',
        Icons.code_rounded,
        t.mint,
        true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.line),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.laptop_mac_rounded, color: t.mute),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Do more on your laptop',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                        Text(
                          'These open on firststepjob.com',
                          style: TextStyle(fontSize: 12.5, color: t.mute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final r in rows)
              InkWell(
                onTap: () => onOpen(r.$1),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: r.$5.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(r.$4, color: r.$5.fg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    r.$2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: t.ink,
                                    ),
                                  ),
                                ),
                                if (r.$6 && !isPremium) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: t.butter.bg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Premium',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: t.butter.fg,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              r.$3,
                              style: TextStyle(fontSize: 12.5, color: t.mute),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded, size: 16, color: t.mute),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

