import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../theme/home_tokens.dart';
import '../../learn/badge_catalog.dart';
import '../../learn/learn_store.dart';
import '../../learn/widgets/badge_shape.dart';
import '../profile_helpers.dart';
import 'profile_screens.dart';

/// Badges collection sheet (Profile → Rewards & badges; Learn → See all).
/// Layout matches 05-learn.html: close · centered title · summary · 3-col grid
/// with glossy shapes; earned shows "Earned", locked shows how-to-earn (never raw keys).
///
/// [streak] is optional — Profile does not invent a streak from badge count.
/// Learn passes the question-of-the-day streak when known.
///
/// Callers: profile_view.dart (_Rewards), learn_view.dart (week + see all).
Future<void> openBadges(
  BuildContext context, {
  int? streak,
  List<LearnBadge>? badges,
  ApiClient? api,
}) async {
  var rows = badges;
  var loadFailed = false;
  if (api != null) {
    try {
      final items = await api.getBadges();
      rows = [
        for (final item in items)
          learnBadgeFromApi(
            key: item.key,
            title: item.title,
            earned: item.earned,
          ),
      ];
    } catch (_) {
      loadFailed = true;
      rows ??= const [];
    }
  }
  if (!context.mounted) return;
  if (loadFailed) {
    showProfileToast(context, 'Could not refresh badges. Showing what we have.');
  }
  return showProfileBottomSheet<void>(
    context,
    heightFactor: 0.85,
    child: _BadgesSheet(
      streak: streak,
      badges: rows,
      loadFailed: loadFailed && (badges == null || badges.isEmpty),
    ),
  );
}

class _BadgesSheet extends StatelessWidget {
  final int? streak;
  final List<LearnBadge>? badges;
  final bool loadFailed;

  const _BadgesSheet({this.streak, this.badges, this.loadFailed = false});

  static double _badgeTileHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (148 * scale).clamp(148.0, 180.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final source = badgeRowsForSheet(badges, samples: sampleBadges);
    final earned = source.where((b) => b.earned).length;
    final tileHeight = _badgeTileHeight(context);
    final showStreak = streak != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        profileSheetGrabber(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: t.line.withValues(alpha: 0.55),
                  foregroundColor: t.ink,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
              const Expanded(
                child: Text(
                  'Badges',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$earned / ${source.length}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                            ),
                          ),
                          Text(
                            'Badges earned',
                            style: TextStyle(fontSize: 12, color: t.mute),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showStreak) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Color(0xFFF07B3F),
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '$streak days',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: t.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Current streak',
                              style: TextStyle(fontSize: 12, color: t.mute),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (source.isEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  loadFailed
                      ? 'Could not load badges. Pull open again when you are online.'
                      : 'No badges yet. Keep learning to unlock your first one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: t.mute),
                ),
              ],
              if (source.isNotEmpty) ...[
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 10,
                  mainAxisExtent: tileHeight,
                  children: [
                    for (final b in source)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          BadgeShape(
                            shape: b.shape,
                            colorKey: b.color,
                            glyph: b.glyph,
                            size: 74,
                            locked: !b.earned,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: t.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.earned ? 'Earned' : b.how,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              color: t.mute,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
