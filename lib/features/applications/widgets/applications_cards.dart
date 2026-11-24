part of '../applications_view.dart';

// --------------------------------------------------------------------------
// Job card
// --------------------------------------------------------------------------

class _JobCard extends StatelessWidget {
  final AppJob job;
  final bool showResume;
  final bool ratingClosed;
  final VoidCallback onOpen;
  final VoidCallback onThumbUp;
  final VoidCallback onThumbDown;
  final VoidCallback onBookmark;

  const _JobCard({
    required this.job,
    required this.showResume,
    required this.ratingClosed,
    required this.onOpen,
    required this.onThumbUp,
    required this.onThumbDown,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = pastelOf(t, ApplicationsStore.pastelFor(job.industry));
    final coLine = job.appliedLabel == null
        ? '${job.company} · ${job.location}'
        : '${job.company} · ${job.location} · ${job.appliedLabel}';

    // Callers: applications_view.dart _appliedBody/_savedBody/_basicSample.
    // User: "Match Applications to 04-applications.html" — list job-card chrome.
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? t.card
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.line),
              boxShadow: t.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      job.company.isEmpty ? '?' : job.company[0],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.fg,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                job.role,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.15,
                                  height: 1.25,
                                  color: t.ink,
                                ),
                              ),
                            ),
                            _PopIcon(
                              active: job.bookmarked,
                              activeIcon: Icons.bookmark_rounded,
                              idleIcon: Icons.bookmark_border_rounded,
                              activeColor: t.ctaBg,
                              onTap: onBookmark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          coLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: t.mute),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _Chip(
                                    label: job.industry,
                                    bg: p.bg,
                                    fg: p.fg,
                                  ),
                                  if (showResume)
                                    _Chip(
                                      label: 'Resume',
                                      bg: Colors.transparent,
                                      fg: t.ink,
                                      icon: Icons.description_outlined,
                                      outlined: true,
                                    ),
                                  if (showResume && job.showFirstStepBadge)
                                    _Chip(
                                      label: 'First Step',
                                      bg: t.peach.bg,
                                      fg: t.peach.fg,
                                    ),
                                ],
                              ),
                            ),
                            if (ratingClosed)
                              Flexible(
                                child: Text(
                                  'Rating closed',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11.5, color: t.mute),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ThumbTile(
                                    active: job.rate == RateValue.up,
                                    icon: Icons.thumb_up_alt_rounded,
                                    activeBg: t.mint.bg,
                                    activeFg: t.mint.fg,
                                    onTap: onThumbUp,
                                  ),
                                  const SizedBox(width: 6),
                                  _ThumbTile(
                                    active: job.rate == RateValue.down,
                                    icon: Icons.thumb_down_alt_rounded,
                                    activeBg: t.ink,
                                    activeFg: t.bg,
                                    onTap: onThumbDown,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension / self-applied jobs — title, company, Applied chip, Save only.
class _ByYouJobCard extends StatelessWidget {
  final AppJob job;
  final VoidCallback onBookmark;

  const _ByYouJobCard({
    required this.job,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? t.card
        : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        decoration: BoxDecoration(
          color: cardColor,
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
                    job.role,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                      height: 1.25,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.company,
                    style: TextStyle(fontSize: 13, color: t.mute),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.mint.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      job.appliedLabel ?? 'Applied',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: t.mint.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onBookmark,
              style: TextButton.styleFrom(
                foregroundColor: job.bookmarked ? t.teal : t.ink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: Icon(
                job.bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 18,
              ),
              label: Text(
                job.bookmarked ? 'Saved' : 'Save',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final bool outlined;

  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: outlined ? 7 : 8,
        vertical: outlined ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: t.line) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbTile extends StatefulWidget {
  final bool active;
  final IconData icon;
  final Color activeBg;
  final Color activeFg;
  final VoidCallback onTap;

  const _ThumbTile({
    required this.active,
    required this.icon,
    required this.activeBg,
    required this.activeFg,
    required this.onTap,
  });

  @override
  State<_ThumbTile> createState() => _ThumbTileState();
}

class _ThumbTileState extends State<_ThumbTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void didUpdateWidget(covariant _ThumbTile old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.15), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 45),
        ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
        child: Container(
          width: 32,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.active ? widget.activeBg : t.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.active ? Colors.transparent : t.line,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.active ? widget.activeFg : t.mute,
          ),
        ),
      ),
    );
  }
}

class _PopIcon extends StatefulWidget {
  final bool active;
  final IconData activeIcon;
  final IconData idleIcon;
  final Color activeColor;
  final VoidCallback onTap;

  const _PopIcon({
    required this.active,
    required this.activeIcon,
    required this.idleIcon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_PopIcon> createState() => _PopIconState();
}

class _PopIconState extends State<_PopIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void didUpdateWidget(covariant _PopIcon old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ScaleTransition(
          scale: TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.15), weight: 55),
            TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 45),
          ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
          child: Icon(
            widget.active ? widget.activeIcon : widget.idleIcon,
            size: 20,
            color: widget.active ? widget.activeColor : t.mute,
          ),
        ),
      ),
    );
  }
}

class _OtherResumes extends StatefulWidget {
  const _OtherResumes();

  @override
  State<_OtherResumes> createState() => _OtherResumesState();
}

class _OtherResumesState extends State<_OtherResumes> {
  RateValue? _rate;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final sample = AppJob(
      company: 'General',
      role: 'Data Engineer',
      location: 'Remote',
      id: 'GEN-001',
      industry: 'Tech',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Other resumes for this day',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.mute,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: t.card,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => openResumeViewer(context, sample),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.lavender.bg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.description_outlined,
                          color: t.lavender.fg, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Engineer · general',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Prepared by Priya · not linked to a job',
                            style: TextStyle(fontSize: 12.5, color: t.mute),
                          ),
                        ],
                      ),
                    ),
                    _ThumbTile(
                      active: _rate == RateValue.up,
                      icon: Icons.thumb_up_alt_rounded,
                      activeBg: t.mint.bg,
                      activeFg: t.mint.fg,
                      onTap: () => setState(() {
                        _rate =
                            _rate == RateValue.up ? null : RateValue.up;
                      }),
                    ),
                    const SizedBox(width: 6),
                    _ThumbTile(
                      active: _rate == RateValue.down,
                      icon: Icons.thumb_down_alt_rounded,
                      activeBg: t.ink,
                      activeFg: t.bg,
                      onTap: () => setState(() {
                        _rate =
                            _rate == RateValue.down ? null : RateValue.down;
                      }),
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

class _ResponseCard extends StatelessWidget {
  final AppResponse response;
  final VoidCallback onTap;

  const _ResponseCard({required this.response, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final p = response.pastel == 'but' ? t.butter : t.lavender;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: t.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        width: 36,
                        color: const Color(0xFF14232B),
                      ),
                      const SizedBox(height: 6),
                      for (final w in [0.9, 0.7, 0.85, 0.55, 0.75, 0.6])
                        FractionallySizedBox(
                          widthFactor: w,
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 3),
                            color: const Color(0xFFE3E6E8),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Chip(label: response.tag, bg: p.bg, fg: p.fg),
                      const SizedBox(height: 6),
                      Text(
                        response.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.ink,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        response.subtitle,
                        style: TextStyle(fontSize: 12.5, color: t.mute),
                      ),
                      if (response.received.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Received ${response.received}',
                            style: TextStyle(fontSize: 12, color: t.mute),
                          ),
                        ),
                      if (response.due != null && response.due!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13, color: t.mute),
                              const SizedBox(width: 4),
                              Text(
                                'Due ${response.due}',
                                style: TextStyle(fontSize: 12, color: t.mute),
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
        ),
      ),
    );
  }
}


