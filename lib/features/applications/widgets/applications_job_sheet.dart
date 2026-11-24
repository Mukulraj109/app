part of '../applications_view.dart';

// --------------------------------------------------------------------------
// Job sheet overlay
// --------------------------------------------------------------------------

class _JobSheetLayer extends StatefulWidget {
  final double top;
  final AppJob job;
  final AppsContent content;
  final VoidCallback onClose;
  final VoidCallback onBookmark;
  final VoidCallback onThumbUp;
  final VoidCallback onThumbDown;
  final VoidCallback onOpenResume;
  final VoidCallback onPosting;
  final ApplicationsStore? store;

  const _JobSheetLayer({
    required this.top,
    required this.job,
    required this.content,
    required this.onClose,
    required this.onBookmark,
    required this.onThumbUp,
    required this.onThumbDown,
    required this.onOpenResume,
    required this.onPosting,
    this.store,
  });

  @override
  State<_JobSheetLayer> createState() => _JobSheetLayerState();
}

class _JobSheetLayerState extends State<_JobSheetLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();
  bool _expanded = false;
  double _drag = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _mockJd =>
      '${widget.job.company} is looking for a ${widget.job.role} to build and own reliable data pipelines that power analytics and product decisions across the company.\n\nWhat you\'ll do\n• Design batch and streaming pipelines with Spark and Airflow\n• Model data in the warehouse for analytics and ML teams\n• Improve data quality, monitoring and cost';

  List<Widget> _jobDescriptionBlock(HomeTokens t, AppJob job) {
    final live = widget.store?.live == true;
    final loading = widget.store?.detailLoadingJobId == job.id;
    final raw = job.description.trim();
    if (live && loading && raw.isEmpty) {
      return [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.teal,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading description…',
              style: TextStyle(fontSize: 14, color: t.mute),
            ),
          ],
        ),
      ];
    }
    final text = raw.isNotEmpty
        ? raw
        : (live ? 'No description available for this job.' : _mockJd);
    final canExpand = text.length > 180;
    return [
      if (_expanded || !canExpand)
        Text(
          text,
          style: TextStyle(fontSize: 14, height: 1.6, color: t.ink),
        )
      else
        _JdClamp(text: text, fadeColor: t.card),
      if (canExpand)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              foregroundColor: t.teal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _expanded ? 'Show less' : 'Read more',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final job = widget.job;
    final c = widget.content;
    final p = pastelOf(t, ApplicationsStore.pastelFor(job.industry));
    final spring = CurvedAnimation(
      parent: _c,
      curve: const Cubic(0.2, 0.9, 0.25, 1.04),
    );

    return Stack(
      children: [
        // Full-bleed dim behind the 80% sheet (not just corner “ears”).
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: FadeTransition(
              opacity: spring,
              child: Container(color: Colors.black.withValues(alpha: 0.42)),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: spring,
          builder: (context, child) {
            return Positioned(
              left: 0,
              right: 0,
              top: widget.top + (1 - spring.value) * 40 + _drag,
              bottom: 0,
              child: child!,
            );
          },
          child: GestureDetector(
            onVerticalDragUpdate: (d) {
              if (d.delta.dy > 0) setState(() => _drag += d.delta.dy);
            },
            onVerticalDragEnd: (_) {
              if (_drag > 80) {
                widget.onClose();
              } else {
                setState(() => _drag = 0);
              }
            },
            child: Material(
              color: t.card,
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: t.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.appliedLabel ?? 'Applied today · Fri 14 Nov',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: t.mute,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: widget.onBookmark,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                job.bookmarked ? t.teal : t.ink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        const SizedBox(width: 4),
                        _SheetCircleIcon(
                          active: false,
                          activeIcon: Icons.close_rounded,
                          idleIcon: Icons.close_rounded,
                          activeColor: t.ink,
                          onTap: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job.company.isEmpty ? '?' : job.company[0],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.fg,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.role,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                  color: t.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job.company,
                                style: TextStyle(fontSize: 14, color: t.mute),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: t.ctaBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: widget.onPosting,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 34,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Job posting',
                                      style: TextStyle(
                                        color: t.ctaInk,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 13,
                                      color: t.ctaInk,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_outlined,
                                size: 14, color: t.mute),
                            const SizedBox(width: 5),
                            Text(
                              job.location,
                              style: TextStyle(fontSize: 12.5, color: t.mute),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag, size: 14, color: t.mute),
                            const SizedBox(width: 5),
                            Text(
                              job.id,
                              style: TextStyle(fontSize: 12.5, color: t.mute),
                            ),
                          ],
                        ),
                        _Chip(
                          label: job.industry,
                          bg: p.bg,
                          fg: p.fg,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                      children: [
                        if (c.showResumes) ...[
                          Text(
                            'RESUME USED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.84,
                              color: t.mute,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Material(
                            color: t.lavender.bg,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: widget.onOpenResume,
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(7),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(7),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 5,
                                            width: 38,
                                            color: const Color(0xFF14232B),
                                          ),
                                          const SizedBox(height: 5),
                                          for (final w in [
                                            0.85,
                                            0.4,
                                            0.7,
                                            0.55,
                                            0.8,
                                            0.65,
                                          ])
                                            FractionallySizedBox(
                                              widthFactor: w,
                                              child: Container(
                                                height: 2.5,
                                                margin: const EdgeInsets.only(
                                                    bottom: 3),
                                                color: const Color(0xFFE3E6E8),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Resume · ${job.company}',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: t.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tailored for this job · tap to open',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: t.ink
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              _ResumeActionPill(
                                                icon: Icons.download_outlined,
                                                label: 'Download',
                                                onTap: () =>
                                                    downloadResumeWithAck(
                                                  context,
                                                  widget.job,
                                                  store: widget.store,
                                                ),
                                              ),
                                              _ResumeActionPill(
                                                icon: Icons.ios_share,
                                                label: 'Share',
                                                onTap: () => shareText(
                                                  context,
                                                  'Resume · ${widget.job.company}',
                                                  'https://firststepjob.com/resumes/${widget.job.id}',
                                                ),
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
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'JOB DESCRIPTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.84,
                            color: t.mute,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._jobDescriptionBlock(t, job),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                    decoration: BoxDecoration(
                      color: t.card,
                      border: Border(top: BorderSide(color: t.line)),
                    ),
                    child: c.ratingClosed
                        ? Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rating closed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: t.ink,
                                      ),
                                    ),
                                    Text(
                                      'Your plan has ended',
                                      style: TextStyle(
                                          fontSize: 12, color: t.mute),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'How was this application?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: t.ink,
                                      ),
                                    ),
                                    Text(
                                      'Your AIC sees your answer',
                                      style: TextStyle(
                                          fontSize: 12, color: t.mute),
                                    ),
                                  ],
                                ),
                              ),
                              _RateThumbTile(
                                active: job.rate == RateValue.up,
                                icon: Icons.thumb_up_alt_rounded,
                                activeBg: t.mint.bg,
                                activeFg: t.mint.fg,
                                onTap: widget.onThumbUp,
                              ),
                              const SizedBox(width: 8),
                              _RateThumbTile(
                                active: job.rate == RateValue.down,
                                icon: Icons.thumb_down_alt_rounded,
                                activeBg: t.ink,
                                activeFg: t.bg,
                                onTap: widget.onThumbDown,
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
    );
  }
}

class _SheetCircleIcon extends StatelessWidget {
  final bool active;
  final IconData activeIcon;
  final IconData idleIcon;
  final Color activeColor;
  final VoidCallback onTap;

  const _SheetCircleIcon({
    required this.active,
    required this.activeIcon,
    required this.idleIcon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: t.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.line),
          ),
          child: Icon(
            active ? activeIcon : idleIcon,
            size: 18,
            color: active ? activeColor : t.ink,
          ),
        ),
      ),
    );
  }
}

class _ResumeActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ResumeActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: t.ink),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
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

class _JdClamp extends StatelessWidget {
  final String text;
  final Color fadeColor;

  const _JdClamp({required this.text, required this.fadeColor});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: t.ink,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      fadeColor.withValues(alpha: 0),
                      fadeColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateThumbTile extends StatelessWidget {
  final bool active;
  final IconData icon;
  final Color activeBg;
  final Color activeFg;
  final VoidCallback onTap;

  const _RateThumbTile({
    required this.active,
    required this.icon,
    required this.activeBg,
    required this.activeFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: active ? activeBg : t.card,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 46,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? Colors.transparent : t.line,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: active ? activeFg : t.mute,
          ),
        ),
      ),
    );
  }
}
