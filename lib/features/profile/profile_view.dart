import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/profile_models.dart';
import '../../auth/auth_controller.dart';
import '../../shared_widgets/app_nav.dart';
import '../../shared_widgets/liquid_wash.dart';
import '../../shared_widgets/spring_entrance.dart';
import '../../state/app_state.dart';
import '../../theme/home_tokens.dart';
import 'profile_helpers.dart';
import 'profile_store.dart';
import 'screens/help_pages.dart';
import 'screens/profile_badges.dart';
import 'screens/profile_screens.dart';
import 'widgets/avatar_mark.dart';

/// Profile tab rebuilt from 03-profile.html.
class ProfileTab extends StatefulWidget {
  final AppState appState;
  final AuthController? auth;

  const ProfileTab({super.key, required this.appState, this.auth});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final ProfileStore _store = ProfileStore();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _nameKey = GlobalKey();
  bool _showPinnedBar = false;
  bool _rolesSheetOpening = false;
  DateTime? _remoteLoadedAt;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.appState.addListener(_onAppState);
    _bootstrapHeader();
    _loadRemote();
  }

  void _onAppState() {
    if (!mounted) return;
    if (widget.appState.openProfileRoles && widget.appState.mainTabIndex == 4) {
      setState(() {});
    }
  }

  void _bootstrapHeader() {
    final user = widget.auth?.sessionUser;
    if (user != null) {
      _store.applySessionUser(user);
    }
  }

  Future<T?> _safe<T>(Future<T> run) async {
    try {
      return await run;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRemote() async {
    final auth = widget.auth;
    if (auth == null || auth.phase != AuthPhase.candidate) return;
    final fresh = _store.hasRemote &&
        _remoteLoadedAt != null &&
        DateTime.now().difference(_remoteLoadedAt!) < const Duration(seconds: 60);
    if (fresh) return;
    if (!_store.hasRemote) _store.setLoading(true);
    final api = auth.api;
    final results = await Future.wait([
      _safe(api.getPlanSummary()),
      _safe(api.getRewards()),
      _safe(api.getBadges()),
      _safe(api.getIntakeProfile()),
      _safe(api.getDocuments()),
      _safe(api.getSupportTickets()),
      _safe(api.getPlanBenefits()),
      _safe(api.getPlanDetails()),
      _safe(api.getAppProfile()),
    ]);
    final failed = <String>[];
    final names = [
      'plan',
      'rewards',
      'badges',
      'intake',
      'documents',
      'requests',
      'plan-benefits',
      'plan-details',
      'app-profile',
    ];
    for (var i = 0; i < results.length; i++) {
      if (results[i] == null) failed.add(names[i]);
    }
    if (!mounted) return;
    _store.applyRemote(
      user: auth.sessionUser,
      planSummary: results[0] as PlanSummary?,
      rewards: results[1] as RewardsSummary?,
      badges: results[2] as List<BadgeItem>?,
      intake: results[3] as IntakeProfileSummary?,
      documents: results[4] as DocumentsSummary?,
      ticketsSummary: results[5] as SupportTicketsSummary?,
      planBenefits: results[6] as PlanBenefitsSummary?,
      planDetailsInfo: results[7] as PlanDetailsInfo?,
      appProfile: results[8] as AppProfileSummary?,
      error: failed.isEmpty
          ? null
          : 'Could not load ${failed.join(', ')}. Try again later.',
    );
    _remoteLoadedAt = DateTime.now();
    _store.setLoading(false);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pinned = _scroll.offset > 200;
    if (pinned != _showPinnedBar) setState(() => _showPinnedBar = pinned);
  }

  void _scrollToTop() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openRolesEditorIfRequested() {
    final app = widget.appState;
    if (!app.openProfileRoles || app.mainTabIndex != 4) return;
    if (_rolesSheetOpening) return;
    _rolesSheetOpening = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rolesSheetOpening = false;
      if (!mounted) return;
      if (!app.openProfileRoles || app.mainTabIndex != 4) return;
      app.clearProfileRolesRequest();
      openEditSheet(
        context,
        _store,
        'Roles of interest',
        auth: widget.auth,
      );
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppState);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        _openRolesEditorIfRequested();
        final c = _store.content;
        final docs = _DocsSection(store: _store, auth: widget.auth);
        return Stack(
          children: [
            ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 128),
              children: [
                SpringEntrance(
                  index: 0,
                  child: LiquidWash(
                    intensity: 1.2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: t.ink,
                              ),
                            ),
                          ),
                          if (_store.loading)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: t.teal,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: () => openSettings(
                              context,
                              widget.appState,
                              auth: widget.auth,
                              store: _store,
                            ),
                            icon: Icon(Icons.settings_outlined, color: t.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_store.loadError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _store.loadError!,
                            style: TextStyle(fontSize: 12.5, color: t.mute),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _remoteLoadedAt = null;
                            _store.setLoading(true);
                            _loadRemote();
                          },
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: t.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                SpringEntrance(
                  index: 1,
                  child: Column(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () => openAvatarSheet(context, _store),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AvatarMark(
                                kind: _store.avatarKind,
                                pastelKey: _store.avatarBg,
                                initial: c.initial,
                                pictureUrl: _store.pictureUrl,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: t.card,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: t.line),
                                  ),
                                  child: Icon(Icons.edit, size: 14, color: t.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: widget.auth == null
                            ? null
                            : () => openDisplayNameSheet(
                                  context,
                                  auth: widget.auth!,
                                  store: _store,
                                ),
                        child: Text(
                          c.name,
                          key: _nameKey,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: t.ink,
                          ),
                        ),
                      ),
                      Text(
                        c.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: t.mute),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 12.5, color: t.mute),
                          children: [
                            const TextSpan(text: 'Member since '),
                            TextSpan(
                              text: c.memberSince,
                              style: TextStyle(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: c.midStat,
                              style: TextStyle(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' ${c.midLabel} · '),
                            TextSpan(
                              text: c.badgeStat,
                              style: TextStyle(
                                color: t.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' ${c.badgeLabel}'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SpringEntrance(index: 2, child: _PlanCard(store: _store, content: c)),
                const SizedBox(height: 12),
                SpringEntrance(
                  index: 3,
                  child: _Tiles(store: _store, auth: widget.auth),
                ),
                if (c.showBenefitChips)
                  SpringEntrance(
                    index: 4,
                    child: _PlanBenefits(store: _store),
                  ),
                if (c.showBenefitsUpsell)
                  const SpringEntrance(
                    index: 4,
                    child: _BenefitsUpsell(),
                  ),
                if (c.isBasic)
                  SpringEntrance(
                    index: 4,
                    child: _PersonalSection(
                      store: _store,
                      auth: widget.auth,
                    ),
                  ),
                if (!c.isBasic) SpringEntrance(index: 4, child: docs),
                if (c.showIntake)
                  SpringEntrance(index: 5, child: _Intake(store: _store)),
                if (!c.isBasic)
                  SpringEntrance(
                    index: 6,
                    child: _PersonalSection(
                      store: _store,
                      auth: widget.auth,
                    ),
                  ),
                if (c.isBasic) SpringEntrance(index: 6, child: docs),
                SpringEntrance(index: 7, child: _Rewards(store: _store, auth: widget.auth)),
                SpringEntrance(
                  index: 8,
                  child: _Section(
                    title: 'Settings & help',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined, color: t.mute, size: 20),
                      title: Text(
                        'Settings & help',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                      subtitle: Text(
                        'Notifications, appearance, FAQ, sign out',
                        style: TextStyle(fontSize: 12.5, color: t.mute),
                      ),
                      trailing: Icon(Icons.chevron_right, color: t.mute),
                      onTap: () => openSettings(
                        context,
                        widget.appState,
                        auth: widget.auth,
                        store: _store,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showPinnedBar,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  offset: _showPinnedBar ? Offset.zero : const Offset(0, -1.2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 280),
                    opacity: _showPinnedBar ? 1 : 0,
                    child: _PinnedProfileBar(
                      store: _store,
                      onTop: _scrollToTop,
                      onSettings: () => openSettings(
                        context,
                        widget.appState,
                        auth: widget.auth,
                        store: _store,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Pastel _pastelFor(HomeTokens t, String key) {
  return switch (key) {
    'pch' => t.peach,
    'sky' => t.sky,
    'but' => t.butter,
    _ => t.lavender,
  };
}

class _PinnedProfileBar extends StatelessWidget {
  final ProfileStore store;
  final VoidCallback onTop;
  final VoidCallback onSettings;

  const _PinnedProfileBar({
    required this.store,
    required this.onTop,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final c = store.content;
    return Material(
      color: t.bg.withValues(alpha: 0.94),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top + 6, 8, 10),
          child: Row(
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onTop,
                child: Row(
                  children: [
                    AvatarMark(
                      kind: store.avatarKind,
                      pastelKey: store.avatarBg,
                      initial: c.initial,
                      size: 28,
                      pictureUrl: store.pictureUrl,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettings,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.settings_outlined, color: t.ink, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanBenefits extends StatelessWidget {
  final ProfileStore store;
  const _PlanBenefits({required this.store});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final chips = store.planBenefits;
    final useBy = store.content.planUseBy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Your plan benefits',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.mute,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Use by $useBy',
                  style: TextStyle(fontSize: 12, color: t.mute),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                _BenefitChip(
                  chip: chip,
                  pastel: _pastelFor(t, chip.pastel),
                  onTap: () => openBenefitAction(context, store, chip),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Tap one to book or open its form. Ends with your plan.',
              style: TextStyle(fontSize: 12.5, color: t.mute),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final PlanBenefitChip chip;
  final Pastel pastel;
  final VoidCallback onTap;

  const _BenefitChip({
    required this.chip,
    required this.pastel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final icon = switch (chip.formKey) {
      'mock' => Icons.mic_none,
      'linkedin' => Icons.person_outline,
      'portfolio' => Icons.language,
      'scoutx' => Icons.radar,
      _ => Icons.star_outline,
    };
    return Material(
      color: pastel.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: pastel.fg),
              const SizedBox(width: 6),
              Text(
                '${chip.title} · ${chip.status}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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

class _BenefitsUpsell extends StatelessWidget {
  const _BenefitsUpsell();

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Premium adds mock interviews and a LinkedIn workshop',
                style: TextStyle(fontSize: 13, color: t.mute),
              ),
            ),
            TextButton(
              onPressed: () => openExternal(AppUrls.plans),
              child: Text(
                'See plans ↗',
                style: TextStyle(fontWeight: FontWeight.w700, color: t.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ProfileStore store;
  final ProfileContent content;
  const _PlanCard({required this.store, required this.content});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (content.isBasic) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Your plan', style: TextStyle(fontSize: 12, color: t.mute)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    planStatusChipLabel(
                      isBasic: true,
                      paymentDue: store.paymentDue,
                      showRenew: store.showRenew,
                      status: store.planStatus,
                    ),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Basic',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            Text(
              'Learning, job board and news. Let our team apply for you anytime.',
              style: TextStyle(fontSize: 13, color: t.mute),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Real people apply for you',
                    style: TextStyle(fontSize: 13, color: t.ink),
                  ),
                ),
                TextButton(
                  onPressed: () => openExternal(AppUrls.plans),
                  child: Text(
                    'See plans ↗',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: t.teal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark tokens flip navy→white for CTAs; plan card needs its own surface.
    final planBg = isDark ? t.card : t.navy;
    final planInk = isDark ? t.ink : Colors.white;
    final planMute = isDark ? t.mute : Colors.white.withValues(alpha: 0.75);
    final planChip = isDark
        ? t.tealSoft
        : Colors.white.withValues(alpha: 0.15);
    final planTrack = isDark
        ? t.line
        : Colors.white.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: planBg,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: t.line) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your plan',
                style: TextStyle(fontSize: 12, color: planMute),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: planChip,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  planStatusChipLabel(
                    isBasic: false,
                    paymentDue: store.paymentDue,
                    showRenew: store.showRenew,
                    status: store.planStatus,
                  ),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: planInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content.planName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: planInk,
            ),
          ),
          Text(
            content.planDates,
            style: TextStyle(fontSize: 13, color: planMute),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: content.progress,
              minHeight: 6,
              backgroundColor: planTrack,
              color: t.teal,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  content.daysLeft,
                  style: TextStyle(color: planInk, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => openPlanIncluded(context, store),
                child: Text(
                  "What's included",
                  style: TextStyle(
                    color: isDark ? t.teal : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  final ProfileStore store;
  final AuthController? auth;
  const _Tiles({required this.store, this.auth});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final openCount = store.supportOpenCount;
    final support = _Tile(
      bg: t.sky.bg,
      fg: t.sky.fg,
      icon: Icons.confirmation_number_outlined,
      title: 'Support',
      subtitle: openCount == 0
          ? 'No open tickets'
          : openCount == 1
              ? '1 open ticket'
              : '$openCount open tickets',
      badge: openCount > 0 ? '$openCount' : null,
      onTap: () => openTicketsSheet(context, store, auth: auth),
    );
    final other = store.content.whatsapp
        ? _Tile(
            bg: t.mint.bg,
            fg: t.mint.fg,
            icon: Icons.chat_bubble_outline,
            title: 'My WhatsApp group',
            subtitle: 'You and your FirstStep team',
            onTap: () {
              final url = store.whatsappGroupUrl.trim();
              if (url.isNotEmpty) {
                openExternal(url);
              } else {
                openExternal(AppUrls.whatsapp);
              }
            },
          )
        : _Tile(
            bg: t.butter.bg,
            fg: t.butter.fg,
            icon: Icons.card_giftcard,
            title: 'Invite a friend',
            subtitle: 'Get \$15 for each friend',
            onTap: () => shareText(
              context,
              AppUrls.inviteShareText(store.referralCode),
              AppUrls.referralFor(store.referralCode),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: store.content.whatsapp
            ? [Expanded(child: other), const SizedBox(width: 10), Expanded(child: support)]
            : [Expanded(child: support), const SizedBox(width: 10), Expanded(child: other)],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _Tile({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: fg, size: 20),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: t.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: t.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: t.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocsSection extends StatelessWidget {
  final ProfileStore store;
  final AuthController? auth;
  const _DocsSection({required this.store, this.auth});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    if (store.content.isBasic) {
      return _Section(
        title: 'My documents',
        child: ListTile(
          leading: Icon(Icons.upload_outlined, color: t.ink),
          title: Text(
            'Upload your resume',
            style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
          ),
          subtitle: Text(
            'PDF or Word · improves your job picks',
            style: TextStyle(fontSize: 12.5, color: t.mute),
          ),
          trailing: Icon(Icons.chevron_right, color: t.mute),
          onTap: () => openDocumentPreview(
            context,
            title: 'Your resume',
            emptyUpload: true,
          ),
        ),
      );
    }
    return _Section(
      title: 'My documents',
      trailing: 'Tap to view · ⬇ to save',
      child: Column(
        children: [
          if (store.docs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Documents will appear here after onboarding.',
                style: TextStyle(fontSize: 13, color: t.mute),
              ),
            )
          else
          for (final d in store.docs)
            ListTile(
              leading: Icon(Icons.description_outlined, color: t.mute, size: 20),
              title: Text(
                d.title,
                style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
              ),
              subtitle: Text(
                d.subtitle,
                style: TextStyle(fontSize: 12.5, color: t.mute),
              ),
              trailing: IconButton(
                onPressed: () => shareProfileDocument(
                  context,
                  doc: d,
                  auth: auth,
                ),
                icon: Icon(Icons.download_outlined, color: t.ink, size: 20),
              ),
              onTap: () => openDocumentPreview(
                context,
                title: d.title,
                subtitle: d.subtitle,
                doc: d,
                auth: auth,
              ),
            ),
        ],
      ),
    );
  }
}

class _Intake extends StatelessWidget {
  final ProfileStore store;
  const _Intake({required this.store});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final c = store.content;
    final intakeRoles = _rolesFromInterest(store.rolesOfInterest);
    final roles = intakeRoles.isNotEmpty ? intakeRoles : c.roles;
    final locationLabel = _displayOrEmpty(
      store.location,
      hidePrefixes: const ['Add your'],
    );
    final workAuth = store.workAuthorization.trim();
    final experience = store.experience.trim();
    final email = c.email.trim();

    final fields = <(IconData, String, String)>[
      if (locationLabel != null)
        (Icons.place_outlined, 'Locations', locationLabel),
      if (workAuth.isNotEmpty)
        (Icons.verified_user_outlined, 'Work authorization', workAuth),
      if (experience.isNotEmpty)
        (Icons.schedule_outlined, 'Experience', experience),
      if (email.isNotEmpty) (Icons.mail_outline, 'Application email', email),
    ];

    return _Section(
      title: 'From your intake',
      trailing: 'Read-only',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.tealSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.badge_outlined, size: 20, color: t.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Snapshot from onboarding — used when your partner applies for you.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: t.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (roles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Target roles',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.mute,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in roles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: t.sky.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.line),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.sky.fg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (fields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Material(
                color: t.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: t.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      _IntakeRow(
                        icon: fields[i].$1,
                        label: fields[i].$2,
                        value: fields[i].$3,
                      ),
                      if (i < fields.length - 1)
                        Divider(height: 1, thickness: 1, color: t.line),
                    ],
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.butter.bg.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: t.mute),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Need to change intake details? ',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: t.mute,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => openTicketSheet(
                            context,
                            store,
                            preselect: 0,
                          ),
                          child: Text(
                            'Raise a ticket',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: t.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _rolesFromInterest(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.startsWith('Add')) return const [];
    return text
        .split(RegExp(r'[,·|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static String? _displayOrEmpty(
    String raw, {
    List<String> hidePrefixes = const [],
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    for (final prefix in hidePrefixes) {
      if (text.startsWith(prefix)) return null;
    }
    return text;
  }

}

class _IntakeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IntakeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: t.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: t.mute),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: t.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalSection extends StatelessWidget {
  final ProfileStore store;
  final AuthController? auth;
  const _PersonalSection({required this.store, this.auth});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final rows = [
      ('Location', store.location, Icons.place_outlined, t.sky),
      ('Tech stack', store.tech, Icons.layers_outlined, t.lavender),
      ('Roles of interest', store.rolesOfInterest, Icons.work_outline, t.peach),
      ('News topics', store.news, Icons.newspaper_outlined, t.mint),
      ('Daily learning time', store.learningTime, Icons.schedule, t.butter),
    ];
    final list = Column(
      children: [
        for (final r in rows)
          ListTile(
            leading: Icon(r.$3, color: r.$4.fg, size: 20),
            title: Text(
              r.$1,
              style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
            ),
            subtitle: Text(
              r.$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: t.mute),
            ),
            trailing: Icon(Icons.chevron_right, color: t.mute),
            onTap: () => openEditSheet(
              context,
              store,
              r.$1,
              auth: auth,
            ),
          ),
      ],
    );

    if (store.content.isBasic) {
      final filled = store.personalFilled;
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.lavender.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: filled / 5,
                        strokeWidth: 4,
                        backgroundColor: t.card,
                        color: t.lavender.fg,
                      ),
                      Text(
                        '$filled/5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.ink,
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
                      Text(
                        'Personalise your app',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.ink,
                        ),
                      ),
                      Text(
                        'Tell us ${5 - filled} more things to get news, jobs and learning picked for you.',
                        style: TextStyle(fontSize: 12.5, color: t.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: '',
            child: Column(
              children: [
                list,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: t.mint.fg),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tech stack added · showing SQL & Python picks in Learn',
                          style: TextStyle(fontSize: 12.5, color: t.mute),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _Section(
      title: 'Personalise your app',
      child: Column(
        children: [
          list,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              "Changes your news, job picks and learning. It doesn't change your applications.",
              style: TextStyle(fontSize: 12.5, color: t.mute),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rewards extends StatelessWidget {
  final ProfileStore store;
  final AuthController? auth;
  const _Rewards({required this.store, this.auth});

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final c = store.content;
    final authed = auth;
    return _Section(
      title: 'Rewards & badges',
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.card_giftcard, color: t.butter.fg),
            title: Text(
              'Rewards',
              style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
            ),
            subtitle: Text(
              '${c.rewards} balance · \$15 for every friend who joins',
              style: TextStyle(fontSize: 12.5, color: t.mute),
            ),
            trailing: TextButton(
              onPressed: () => shareText(
                context,
                AppUrls.inviteShareText(store.referralCode),
                AppUrls.referralFor(store.referralCode),
              ),
              child: Text(
                'Invite',
                style: TextStyle(fontWeight: FontWeight.w700, color: t.teal),
              ),
            ),
          ),
          if (store.rewardsBalanceUsd >= 15 && authed != null)
            ListTile(
              leading: Icon(Icons.redeem_outlined, color: t.mint.fg),
              title: Text(
                'Redeem \$15',
                style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
              ),
              subtitle: Text(
                'Hold for a Resume add-on · same as website',
                style: TextStyle(fontSize: 12.5, color: t.mute),
              ),
              trailing: TextButton(
                onPressed: () => _redeemRewards(context, store, authed),
                child: Text(
                  'Redeem',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.teal),
                ),
              ),
            ),
          ListTile(
            leading: Icon(Icons.workspace_premium_outlined, color: t.lavender.fg),
            title: Text(
              'Badges',
              style: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
            ),
            subtitle: Text(
              '${c.badges} earned · see your collection',
              style: TextStyle(fontSize: 12.5, color: t.mute),
            ),
            trailing: Icon(Icons.chevron_right, color: t.mute),
            onTap: () => openBadges(
              context,
              api: auth?.api,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemRewards(
    BuildContext context,
    ProfileStore store,
    AuthController auth,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem \$15?'),
        content: const Text(
          'We hold \$15 until the team applies a Resume add-on. Same flow as the website.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: HomeTokens.of(ctx).navy,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      // Caller of api_client.redeemRewards; preserve store.referralCode if API omits it.
      final next = await auth.api.redeemRewards(
        previousReferralCode: store.referralCode,
      );
      store.applyRemote(rewards: next);
      if (context.mounted) {
        showProfileToast(
          context,
          'Redeem request sent. \$15 is held until the team applies the add-on.',
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Could not redeem. Try again.';
      showProfileToast(context, message);
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.mute,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trailing!,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: t.mute),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Material(
            color: t.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: t.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}
