part of '../focus_home_view.dart';

// --------------------------------------------------------------------------
// Blocks
// --------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final HomeContent content;
  final HomeTokens tokens;
  final HomeStore store;
  final ApiClient? api;
  final int unread;
  final bool signedIn;

  const _TopBar({
    required this.content,
    required this.tokens,
    required this.store,
    this.api,
    this.unread = 0,
    this.signedIn = false,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openStatePicker(BuildContext context) {
    final t = tokens;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.7,
            child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Preview state',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              for (final state in HomeScreenState.values)
                ListTile(
                  title: Text(
                    _stateLabel(state),
                    style: TextStyle(color: t.ink, fontWeight: FontWeight.w500),
                  ),
                  trailing: store.state == state
                      ? Icon(Icons.check_rounded, color: t.teal)
                      : null,
                  onTap: () {
                    store.setState(state);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
            ),
          ),
        );
      },
    );
  }

  String _stateLabel(HomeScreenState state) {
    switch (state) {
      case HomeScreenState.applying:
        return 'Active · applying now';
      case HomeScreenState.done:
        return 'Active · done for today';
      case HomeScreenState.weekend:
        return 'Weekend';
      case HomeScreenState.falcon:
        return 'Falcon · plan total';
      case HomeScreenState.gettingReady:
        return 'Getting ready';
      case HomeScreenState.basic:
        return 'Basic';
      case HomeScreenState.expired:
        return 'Expired';
      case HomeScreenState.alumni:
        return 'Alumni';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    // Match 02-home.html Option A (hdC + gC):
    // Row 1: News · centred FirstStep logo · Notifications
    // Row 2: centred greeting + plan line
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Row(
            children: [
              _DotButton(
                icon: Icons.article_outlined,
                label: 'News',
                hasDot: false,
                onTap: () => openNewsFeed(
                  context,
                  api: signedIn ? api : null,
                  liveCards: signedIn ? content.news : null,
                ),
              ),
              Expanded(
                child: Center(
                  child: kDebugMode
                      ? Tooltip(
                          message: 'Preview states',
                          child: GestureDetector(
                            onTap: () => _openStatePicker(context),
                            onLongPress: () => _openStatePicker(context),
                            onDoubleTap: () => _openStatePicker(context),
                            child: const FirstStepLogo(
                              triangleWidth: 24,
                              wordmarkWidth: 112,
                              spacing: 7,
                            ),
                          ),
                        )
                      : const FirstStepLogo(
                          triangleWidth: 24,
                          wordmarkWidth: 112,
                          spacing: 7,
                        ),
                ),
              ),
              _DotButton(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                hasDot: unread > 0,
                onTap: () => openBellInbox(context, api),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '$_greeting, ${content.firstName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: t.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          content.planLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.mute,
          ),
        ),
      ],
    );
  }
}

class _DotButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasDot;
  final VoidCallback? onTap;

  const _DotButton({
    required this.icon,
    required this.label,
    this.hasDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: t.card,
              shape: BoxShape.circle,
              border: Border.all(color: t.line, width: 1.2),
              boxShadow: t.cardShadow,
            ),
            child: Icon(icon, size: 21, color: t.ink),
          ),
          if (hasDot)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5533D),
                  shape: BoxShape.circle,
                  border: Border.all(color: t.card, width: 2),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _QuietLine extends StatelessWidget {
  final int total;
  final int hours;

  const _QuietLine({required this.total, required this.hours});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(
            text: '$total',
            style: TextStyle(
              fontSize: 12.5,
              color: t.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' total',
            style: TextStyle(
              fontSize: 12.5,
              color: t.mute,
              fontWeight: FontWeight.w500,
            ),
          ),
        ])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: t.mute.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Text.rich(TextSpan(children: [
          TextSpan(
            text: '$hours',
            style: TextStyle(
              fontSize: 12.5,
              color: t.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' hrs saved',
            style: TextStyle(
              fontSize: 12.5,
              color: t.mute,
              fontWeight: FontWeight.w500,
            ),
          ),
        ])),
      ],
    );
  }
}

class _BusyCard extends StatefulWidget {
  final String text;

  const _BusyCard({required this.text});

  @override
  State<_BusyCard> createState() => _BusyCardState();
}

class _BusyCardState extends State<_BusyCard> {
  bool _gone = false;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final m = t.mint;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: HomeCurves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _gone
          ? const SizedBox(width: double.infinity)
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: m.bg,
                borderRadius: BorderRadius.circular(20),
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
                    alignment: Alignment.center,
                    child: CustomPaint(
                      size: const Size(18, 18),
                      painter: _SparkPainter(color: m.fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'While you were busy',
                          style: TextStyle(
                            fontSize: 14,
                            color: t.ink,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: t.ink.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Dismiss',
                    onPressed: () => setState(() => _gone = true),
                    icon: Icon(Icons.close_rounded, size: 18, color: t.mute),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Sparkline from 02-homev2.html (`M4 12h3l2-5 4 10 2-5h5`).
class _SparkPainter extends CustomPainter {
  final Color color;

  _SparkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24;
    final sy = size.height / 24;
    final path = Path()
      ..moveTo(4 * sx, 12 * sy)
      ..lineTo(7 * sx, 12 * sy)
      ..lineTo(9 * sx, 7 * sy)
      ..lineTo(13 * sx, 17 * sy)
      ..lineTo(15 * sx, 12 * sy)
      ..lineTo(20 * sx, 12 * sy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * sx
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.color != color;
}


