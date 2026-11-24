import 'learn_store.dart';

/// Visual presentation for badges — shapes/glyphs/how-to-earn from 05-learn.html,
/// keyed to live API badge keys from `BADGE_CATALOG`.
class BadgeVisual {
  final String shape;
  final String color;
  final String glyph;
  final String how;

  const BadgeVisual({
    required this.shape,
    required this.color,
    this.glyph = '',
    required this.how,
  });
}

const Map<String, BadgeVisual> kBadgeVisuals = {
  // Live backend catalog
  'first_skill_check': BadgeVisual(
    shape: 'notch',
    color: 'lav',
    glyph: '1',
    how: 'Complete your first skill check',
  ),
  'qotd_streak_7': BadgeVisual(
    shape: 'orb',
    color: 'pch',
    glyph: '7',
    how: 'Answer 7 days in a row',
  ),
  'qotd_streak_30': BadgeVisual(
    shape: 'orb',
    color: 'sky',
    glyph: '30',
    how: 'Answer 30 days in a row',
  ),
  'qotd_streak_100': BadgeVisual(
    shape: 'orb',
    color: 'mint',
    glyph: '100',
    how: 'Answer 100 days in a row',
  ),
  'skill_bronze': BadgeVisual(
    shape: 'notch',
    color: 'but',
    glyph: 'Br',
    how: 'Reach bronze on a skill check',
  ),
  'skill_silver': BadgeVisual(
    shape: 'notch',
    color: 'sky',
    glyph: 'Ag',
    how: 'Reach silver on a skill check',
  ),
  'skill_gold': BadgeVisual(
    shape: 'notch',
    color: 'pch',
    glyph: 'Au',
    how: 'Reach gold on a skill check',
  ),
  'weekly_warrior': BadgeVisual(
    shape: 'chevron',
    color: 'mint',
    how: 'Finish weekly challenges',
  ),
  'interview_ready': BadgeVisual(
    shape: 'chevron',
    color: 'lav',
    how: 'Finish an AI mock interview',
  ),
  // HTML / mock aliases
  'sql_ace': BadgeVisual(
    shape: 'notch',
    color: 'lav',
    glyph: 'SQL',
    how: 'Score 7+ on a SQL week',
  ),
  'pitch_ready': BadgeVisual(
    shape: 'chevron',
    color: 'mint',
    how: 'Record your pitch',
  ),
  'first_story': BadgeVisual(
    shape: 'split',
    color: 'but',
    how: 'Share an interview story',
  ),
  'python_pro': BadgeVisual(
    shape: 'notch',
    color: 'mint',
    glyph: 'PY',
    how: 'Score 8+ on a Python week',
  ),
  'helpful': BadgeVisual(
    shape: 'split',
    color: 'pch',
    how: '5 people found your story helpful',
  ),
  'perfect_10': BadgeVisual(
    shape: 'notch',
    color: 'sky',
    glyph: '10',
    how: 'Get 10/10 in a week',
  ),
};

/// Builds a Learn badge for UI from API (or week) payload — never shows raw keys.
LearnBadge learnBadgeFromApi({
  required String key,
  String title = '',
  required bool earned,
}) {
  final trimmedKey = key.trim();
  final visual = kBadgeVisuals[trimmedKey];
  final name = title.trim().isNotEmpty
      ? title.trim()
      : _fallbackTitle(trimmedKey);
  return LearnBadge(
    shape: visual?.shape ?? 'notch',
    color: visual?.color ?? (earned ? 'mint' : 'sky'),
    glyph: visual?.glyph ?? '',
    name: name,
    how: visual?.how ?? 'Keep learning to unlock this badge',
    earned: earned,
  );
}

LearnBadge learnBadgeFromJson(Map<String, dynamic> row) {
  return learnBadgeFromApi(
    key: '${row['key'] ?? ''}',
    title: '${row['title'] ?? row['name'] ?? ''}',
    earned: row['earned'] == true,
  );
}

/// Shelf shows at most 4 badges like 05-learn.html (earned first, then locked).
List<LearnBadge> badgeShelfPreview(List<LearnBadge> all, {int max = 4}) {
  if (all.isEmpty) return const [];
  final earned = all.where((b) => b.earned).toList();
  final locked = all.where((b) => !b.earned).toList();
  return [...earned, ...locked].take(max).toList();
}

String _fallbackTitle(String key) {
  if (key.isEmpty) return 'Badge';
  return key
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
