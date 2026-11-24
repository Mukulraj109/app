import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../home/home_live.dart';
import '../home/home_refresh.dart';
import '../../shared_widgets/celebration_overlay.dart';
import '../../shared_widgets/liquid_wash.dart';
import '../../shared_widgets/expanding_pill_nav.dart';
import '../../state/app_state.dart';
import '../../theme/home_tokens.dart';
import '../applications/applications_view.dart';
import '../home/focus_home_view.dart';
import '../home/screens/bell_inbox.dart';
import '../home/home_store.dart';
import '../learn/learn_view.dart';
import '../profile/profile_view.dart';
import 'tabs/scoutx_tab.dart';

/// Unified shell — Learn · Applications · [Home] · ScoutX · Profile,
/// Home in the center.
class FocusShell extends StatefulWidget {
  final AppState appState;
  final AuthController? auth;

  const FocusShell({super.key, required this.appState, this.auth});

  @override
  State<FocusShell> createState() => _FocusShellState();
}

class _FocusShellState extends State<FocusShell> {
  late final HomeStore _homeStore = HomeStore(awaitingLive: widget.auth?.api != null);
  final InFlightGate _homeGate = InFlightGate();
  Timer? _homePoll;
  bool _timezoneSynced = false;

  int _tabIndex = 2;
  /// Tabs mount on first visit so Profile/ScoutX do not run at cold start.
  final Set<int> _mountedTabs = {2};
  bool _showCelebration = false;
  String? _pushNotice;

  @override
  void initState() {
    super.initState();
    _syncFromAppState();
    widget.appState.addListener(_onAppState);
    _loadHome();
    if (widget.auth?.api != null) {
      _homePoll = Timer.periodic(const Duration(seconds: 45), (_) {
        // Only poll while Home is visible — keeps Learn/Apps/ScoutX smooth.
        if (_tabIndex == 2) _loadHome();
      });
    }
  }

  Future<void> _syncDeviceTimezone() async {
    if (_timezoneSynced) return;
    final api = widget.auth?.api;
    if (api == null) return;
    try {
      // Ops day stays ET; this only improves weekend ribbon copy for the viewer.
      await api.putSettings({'timezone': deviceTimezone()});
      _timezoneSynced = true;
    } catch (_) {
      /* home still loads; mobile also overrides weekend copy locally */
    }
  }

  Future<void> _loadHome() {
    return _homeGate.run(() async {
      final api = widget.auth?.api;
      if (api == null) return;
      try {
        // Timezone is a settings write, not required to paint Home.
        unawaited(_syncDeviceTimezone());
        final loaded = await joinHomeAndBell(
          home: api.getHomeScreen,
          bell: () => api.getBell(limit: 20),
        );
        if (!mounted) return;
        _homeStore.showLive(
          homeContentFromScreen(
            loaded.screen,
            firstName: widget.auth?.sessionUser?.firstName ?? '',
          ),
          actions: homeActionsFromScreen(loaded.screen),
        );
        final bell = loaded.bell;
        if (bell != null) {
          final unread = bell['unreadCount'];
          final items = bell['items'] ?? bell['notifications'];
          var count = unread is num ? unread.toInt() : 0;
          if (unread == null && items is List) {
            count = items.whereType<Map>().where((row) => row['read'] != true && row['isRead'] != true).length;
          }
          widget.appState.setBellUnread(count);
        }
      } catch (_) {
        if (!mounted) return;
        _homeStore.showLoadFailed();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FocusShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState.removeListener(_onAppState);
      widget.appState.addListener(_onAppState);
      _syncFromAppState();
    }
  }

  @override
  void dispose() {
    _homePoll?.cancel();
    widget.appState.removeListener(_onAppState);
    super.dispose();
  }

  void _syncFromAppState() {
    _tabIndex = widget.appState.mainTabIndex;
    _mountedTabs.add(_tabIndex);
    _showCelebration = widget.appState.showCelebrationModal;
    _pushNotice = widget.appState.activePushNotice;
  }

  void _selectMainTab(int index) {
    // Callers: ExpandingPillNav onSelected. Existing FocusShell method.
    // User: "fix these speed issue so my user experice is up to the mark"
    final nav = Navigator.of(context);
    // Dismiss sheets/dialogs so tab changes do not leave a modal scrim on Home.
    while (nav.canPop()) {
      nav.pop();
    }
    final returningHome = index == 2 && _tabIndex != 2;
    setState(() => _mountedTabs.add(index));
    widget.appState.setMainTabIndex(index);
    if (returningHome && widget.auth?.api != null) {
      _loadHome();
    }
  }

  Widget _tabWhenMounted(int index, Widget child) {
    if (!_mountedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return child;
  }

  void _onAppState() {
    if (widget.appState.openBellRequested) {
      widget.appState.clearOpenBellRequest();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        openBellInbox(context, widget.auth?.api);
      });
    }
    if (widget.appState.homeRefreshRequested) {
      widget.appState.clearHomeRefreshRequest();
      _loadHome();
    }
    final nextIndex = widget.appState.mainTabIndex;
    final nextCelebration = widget.appState.showCelebrationModal;
    final nextPush = widget.appState.activePushNotice;
    if (nextIndex == _tabIndex &&
        nextCelebration == _showCelebration &&
        nextPush == _pushNotice) {
      return;
    }
    setState(() {
      _tabIndex = nextIndex;
      _mountedTabs.add(nextIndex);
      _showCelebration = nextCelebration;
      _pushNotice = nextPush;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final index = _tabIndex;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ScoutX is opaque paper — skip the 20fps wash while it is selected.
            if (index != 3)
              const Positioned.fill(
                child: LiquidWashBackdrop(intensity: 1.05),
              ),
            IndexedStack(
              index: index,
              children: [
                TickerMode(
                  enabled: index == 0,
                  child: _tabWhenMounted(
                    0,
                    LearnTab(
                      appState: widget.appState,
                      api: widget.auth?.api,
                      webAppUrl: widget.auth?.config.webAppUrl,
                    ),
                  ),
                ),
                TickerMode(
                  enabled: index == 1,
                  child: _tabWhenMounted(
                    1,
                    ApplicationsTab(
                      appState: widget.appState,
                      api: widget.auth?.api,
                      auth: widget.auth,
                    ),
                  ),
                ),
                TickerMode(
                  enabled: index == 2,
                  child: FocusHomeView(
                    homeStore: _homeStore,
                    appState: widget.appState,
                    onRefresh: _loadHome,
                    api: widget.auth?.api,
                  ),
                ),
                TickerMode(
                  enabled: index == 3,
                  child: _tabWhenMounted(
                    3,
                    ScoutXTab(appState: widget.appState, api: widget.auth?.api),
                  ),
                ),
                TickerMode(
                  enabled: index == 4,
                  child: _tabWhenMounted(
                    4,
                    ProfileTab(appState: widget.appState, auth: widget.auth),
                  ),
                ),
              ],
            ),
            if (_showCelebration)
              CelebrationOverlay(
                onDismiss: () => widget.appState.setCelebration(false),
              ),
            if (_pushNotice != null)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: t.teal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Text(
                      _pushNotice!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ExpandingPillNav(
              selectedIndex: index,
              onSelected: _selectMainTab,
            ),
          ],
        ),
      ),
    );
  }
}
