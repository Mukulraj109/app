part of '../applications_view.dart';

// --------------------------------------------------------------------------
// Banners / empty / lock
// --------------------------------------------------------------------------

class _Banner extends StatelessWidget {
  final String kind;
  final HomeTokens t;
  final AuthController? auth;
  const _Banner({required this.kind, required this.t, this.auth});

  @override
  Widget build(BuildContext context) {
    late String title;
    late String body;
    late IconData icon;
    late Color bg;
    late Widget actions;

    switch (kind) {
      case 'due':
        title = 'A payment is due';
        body = 'Finish checkout on the website to keep applications moving.';
        icon = Icons.warning_amber_rounded;
        bg = t.butter.bg;
        actions = AppUrls.whatsapp.isEmpty
            ? const SizedBox.shrink()
            : _BanBtn(
                label: 'Chat with us',
                filled: true,
                onTap: () => openExternal(AppUrls.whatsapp),
              );
        break;
      case 'pause':
        title = 'Applications are paused';
        body =
            'Everything here is still yours to view. Your AIC continues when your plan resumes.';
        icon = Icons.pause_circle_outline;
        bg = t.sky.bg;
        actions = _BanBtn(
          label: 'Raise a ticket',
          filled: false,
          onTap: () => openTicketsSheet(
            context,
            ProfileStore(),
            auth: auth,
          ),
        );
        break;
      default:
        title = 'Your plan has ended';
        body =
            'You can still view, download and share everything. Rating is closed.';
        icon = Icons.event_busy_outlined;
        bg = t.lavender.bg;
        actions = _BanBtn(
          label: 'Renew ↗',
          filled: true,
          onTap: () => openExternal(AppUrls.plans),
        );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: kind == 'pause' || kind == 'exp' || kind == 'expired'
            ? Border.all(color: t.line)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: t.ink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: t.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: t.ink.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                actions,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BanBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _BanBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    // Callers: _Banner in applications_view.dart. UI-only. User instruction:
    // "Match Applications to 04-applications.html" — banner CTA chrome.
    if (filled) {
      return Material(
        color: t.ctaBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: t.ctaInk,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.ink.withValues(alpha: 0.15)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: t.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartingSoon extends StatelessWidget {
  final HomeTokens t;
  const _StartingSoon({required this.t});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        '1',
        t.mint.bg,
        t.mint.fg,
        'Your AIC applies every weekday',
        'Each job appears here under its date.',
      ),
      (
        '2',
        t.lavender.bg,
        t.lavender.fg,
        'Every job comes with its resume',
        'Open it, download it or share it in one tap.',
      ),
      (
        '3',
        t.butter.bg,
        t.butter.fg,
        'Rate each application',
        '👍 or 👎 helps your AIC pick better jobs.',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.peach.bg,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(Icons.rocket_launch_outlined,
                color: t.peach.fg, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Your first applications arrive Mon 17 Nov',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "From then on, every weekday's applications show up here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: t.mute),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: steps[i].$2,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            steps[i].$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: steps[i].$3,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[i].$4,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.ink,
                                ),
                              ),
                              Text(
                                steps[i].$5,
                                style: TextStyle(
                                  fontSize: 12.5,
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
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => openDocumentPreview(
                context,
                title: 'Intake form',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: t.ctaBg,
                foregroundColor: t.ctaInk,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Finish your intake form →',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  final String secondary;
  final String primary;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;

  const _LockCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.secondary,
    required this.primary,
    required this.onSecondary,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: t.mute, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.ink,
                    side: BorderSide(color: t.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(secondary,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.navy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(primary,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


