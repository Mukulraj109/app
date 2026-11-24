part of '../focus_home_view.dart';

class _UpNext extends StatelessWidget {
  final String title;
  final UpNextFirst? first;
  final List<UpNextItem> rest;
  final AppState? appState;

  const _UpNext({
    required this.title,
    required this.first,
    required this.rest,
    this.appState,
  });

  Pastel? _tone(HomeTokens t, String type) {
    switch (type) {
      case 'Interview':
        return t.lavender;
      case 'Assessment':
        return t.butter;
      case 'Weekly task':
        return t.peach;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => appState?.setMainTabIndex(1),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: t.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (first != null) ...[
          _FirstUpNextCard(
            item: first!,
            tone: _tone(t, first!.type),
            appState: appState,
          ),
          const SizedBox(height: 10),
        ],
        if (rest.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.line),
              boxShadow: t.cardShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < rest.length; i++)
                  _UpNextRow(
                    item: rest[i],
                    tone: _tone(t, rest[i].type),
                    divider: i > 0,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FirstUpNextCard extends StatelessWidget {
  final UpNextFirst item;
  final Pastel? tone;
  final AppState? appState;

  const _FirstUpNextCard({
    required this.item,
    required this.tone,
    this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colored = tone != null;
    // Soft pastel surface — light blue wash motion, not a darkened card.
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colored
            ? (isDark
                ? Color.lerp(tone!.bg, const Color(0xFF1A2838), 0.55)
                : Color.lerp(tone!.bg, const Color(0xFFE8F2FA), 0.35))
            : t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colored ? tone!.bg.withValues(alpha: 0.5) : t.line),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeChip(
                label: item.type,
                fg: tone?.fg ?? t.ink,
                bg: colored
                    ? (isDark
                        ? const Color(0x33FFFFFF)
                        : Colors.white.withValues(alpha: 0.85))
                    : const Color(0xFFEBEBE4),
              ),
              const Spacer(),
              Text(
                item.when,
                style: TextStyle(
                  fontSize: 12.5,
                  color: t.mute,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: t.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.sub,
            style: TextStyle(
              fontSize: 13.5,
              color: t.mute,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: item.primaryLabel,
                  bg: t.ctaBg,
                  ink: t.ctaInk,
                  appState: appState,
                ),
              ),
              if (item.secondaryLabel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _PillButton(
                    label: item.secondaryLabel!,
                    bg: Colors.transparent,
                    ink: t.ink,
                    outline: true,
                    appState: appState,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (!colored) return card;
    return LiquidWash(
      fill: true,
      intensity: 0.95,
      child: card,
    );
  }
}

class _UpNextRow extends StatelessWidget {
  final UpNextItem item;
  final Pastel? tone;
  final bool divider;

  const _UpNextRow({
    required this.item,
    required this.tone,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final done = item.done || item.type == 'Done';
    final tile = done ? t.mint : (tone ?? Pastel(const Color(0xFFEBEBE4), t.ink));
    final meta = item.sub == null ? item.type : '${item.type} · ${item.sub}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: t.line))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tile.bg,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(_rowIcon(item.type), size: 18, color: tile.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: done ? t.mute : t.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: t.mute,
                  ),
                ),
                Text(
                  meta,
                  style: TextStyle(fontSize: 12.5, color: t.mute),
                ),
              ],
            ),
          ),
          if (item.when != null)
            Text(
              item.when!,
              style: TextStyle(fontSize: 12, color: t.mute),
            ),
        ],
      ),
    );
  }

  IconData _rowIcon(String type) {
    switch (type) {
      case 'Interview':
        return Icons.mic_none_rounded;
      case 'Assessment':
        return Icons.code_rounded;
      case 'Weekly task':
        return Icons.task_alt_rounded;
      case 'Done':
        return Icons.check_rounded;
      default:
        return Icons.description_outlined;
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _TypeChip({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color ink;
  final bool outline;
  final AppState? appState;

  const _PillButton({
    required this.label,
    required this.bg,
    required this.ink,
    this.outline = false,
    this.appState,
  });

  void _handle(BuildContext context) {
    HapticFeedback.selectionClick();
    final lower = label.toLowerCase();
    if (lower.contains('prep')) {
      openQuiz(context);
      return;
    }
    if (lower.contains('start') || lower.contains('pitch')) {
      openPitchTask(context);
      return;
    }
    if (lower.contains('detail')) {
      appState?.setMainTabIndex(1);
      return;
    }
    if (lower.contains('later') || lower.contains('dismiss')) {
      return;
    }
    if (lower.contains('talk') || lower.contains('help') || lower.contains('chat')) {
      openExternal(AppUrls.whatsapp);
      return;
    }
    if (lower.contains('plan') || lower.contains('renew') || lower.contains('restart')) {
      openExternal(AppUrls.plans);
      return;
    }
    if (lower.contains('book') || lower.contains('call')) {
      openExternal(AppUrls.booking);
      return;
    }
    if (lower.contains('refer')) {
      shareText(context, 'Join FirstStep with my link', AppUrls.referralFor(null));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outline ? Colors.transparent : bg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _handle(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: outline ? Border.all(color: ink, width: 1.5) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationPartner extends StatelessWidget {
  final PartnerInfo partner;
  final AppState? appState;

  const _ApplicationPartner({required this.partner, this.appState});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final hasName = partner.name != null;
    final name = hasName ? partner.name! : 'Your FirstStep team';
    final initial = name[0].toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Your application partner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.line),
            boxShadow: t.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasName ? null : t.tealSoft,
                      gradient: hasName
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4399A9), Color(0xFF06334A)],
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(color: t.card, spreadRadius: 3),
                        BoxShadow(
                          color: t.line,
                          spreadRadius: 4.5,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: partner.photoUrl != null && partner.photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              partner.photoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  hasName ? initial : 'FS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: hasName ? Colors.white : t.teal,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            hasName ? initial : 'FS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: hasName ? Colors.white : t.teal,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasName
                              ? 'Applies for you every weekday'
                              : "We're here on weekdays",
                          style: TextStyle(fontSize: 12.5, color: t.mute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (partner.leaveNotice != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: t.butter.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: t.butter.fg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          partner.leaveNotice!,
                          style: TextStyle(
                            fontSize: 13,
                            color: t.butter.fg,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (partner.hasWhatsApp) ...[
                    Expanded(
                      child: _PillButton(
                        label: 'Talk to ${partner.firstName}',
                        bg: t.wa,
                        ink: Colors.white,
                        appState: appState,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _PillButton(
                      label: 'Get help',
                      bg: Colors.transparent,
                      ink: t.ink,
                      outline: true,
                      appState: appState,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final VoidCallback? onOpenReview;

  const _FeedbackCard({this.onOpenReview});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onOpenReview,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.line),
            boxShadow: t.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How was today's batch?",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your answer goes to your team.',
                      style: TextStyle(fontSize: 12.5, color: t.mute),
                    ),
                  ],
                ),
              ),
              _Thumb(
                icon: Icons.thumb_up_alt_outlined,
                label: 'Good',
                onTap: onOpenReview,
              ),
              const SizedBox(width: 8),
              _Thumb(
                icon: Icons.thumb_down_alt_outlined,
                label: 'Not good',
                onTap: onOpenReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Thumb({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: t.card,
      shape: CircleBorder(side: BorderSide(color: t.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanks — $label'),
              backgroundColor: t.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: t.ink),
        ),
      ),
    );
  }
}


