part of '../learn_view.dart';

// --------------------------------------------------------------------------
// Header
// --------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final LearnContent content;
  final VoidCallback onBadges;
  final VoidCallback onPreview;

  const _Header({
    required this.content,
    required this.onBadges,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return LiquidWash(
      intensity: 1.2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Learn',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: t.ink,
                    ),
                  ),
                ),
                if (kDebugMode)
                  Tooltip(
                    message: 'Preview states',
                    child: IconButton(
                      onPressed: onPreview,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.science_outlined, color: t.ink),
                    ),
                  ),
                _StatPill(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF07B3F),
                  value: '${content.streak}',
                  onTap: onBadges,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.workspace_premium_outlined,
                  iconColor: t.lavender.fg,
                  value: '${content.badges}',
                  onTap: onBadges,
                ),
              ],
            ),
            Text(
              content.hasRole
                  ? '${content.role} · picked from your profile'
                  : 'Add your role in Profile to get picks for you',
              style: TextStyle(fontSize: 13, color: t.mute),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final VoidCallback onTap;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


