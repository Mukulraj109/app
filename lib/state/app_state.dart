import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';
import '../data/models/tracker_state_model.dart';
import '../data/models/interview_model.dart';
import '../data/models/task_model.dart';
import '../data/fake/seed_data.dart';

/// Legacy gallery concepts — kept for unlinked design_* screens.
enum DesignConcept {
  designA,
  designB,
  designC,
  designD,
}

enum HomeMetricKey {
  totalApplied,
  weekApplied,
  interviews,
  responses,
  daysLeft,
  hoursSaved,
}

extension HomeMetricKeyX on HomeMetricKey {
  String get label {
    switch (this) {
      case HomeMetricKey.totalApplied:
        return 'Total applied';
      case HomeMetricKey.weekApplied:
        return 'This week';
      case HomeMetricKey.interviews:
        return 'Interviews';
      case HomeMetricKey.responses:
        return 'Responses';
      case HomeMetricKey.daysLeft:
        return 'Days left';
      case HomeMetricKey.hoursSaved:
        return 'Hours saved';
    }
  }

  String get shortLabel {
    switch (this) {
      case HomeMetricKey.totalApplied:
        return 'Applied';
      case HomeMetricKey.weekApplied:
        return 'Week';
      case HomeMetricKey.interviews:
        return 'Interviews';
      case HomeMetricKey.responses:
        return 'Replies';
      case HomeMetricKey.daysLeft:
        return 'Days left';
      case HomeMetricKey.hoursSaved:
        return 'Hours';
    }
  }
}

class AppState extends ChangeNotifier {
  static const _prefsKey = 'focus_visible_metrics';
  static const _themeKey = 'firststep_theme_mode';
  static const _defaultMetrics = [
    HomeMetricKey.weekApplied,
    HomeMetricKey.interviews,
    HomeMetricKey.responses,
    HomeMetricKey.daysLeft,
  ];

  /// Default is white / light; user can switch in Settings → Appearance.
  ThemeMode _themeMode = ThemeMode.light;
  DesignConcept _currentDesign = DesignConcept.designA;
  TrackerState _tracker = SeedData.defaultTracker;
  final UserProfile _user = SeedData.user;
  final DashboardMetrics _metrics = SeedData.metrics;
  final List<InterviewEvent> _interviews = List.from(SeedData.interviews);
  QuestionOfTheDay _qotd = SeedData.qotd;
  WeeklyChallenge _challenge = SeedData.challenge;
  List<DailyTask> _tasks = List.from(SeedData.dailyTasks);
  List<InboxItem> _inbox = List.from(SeedData.inboxItems);
  bool _openApplicationsReview = false;

  List<HomeMetricKey> _visibleMetricKeys = List.from(_defaultMetrics);
  int _mainTabIndex = 2; // Today (center)

  bool _liveActivityEnabled = true;
  bool _biometricLocked = false;
  bool _quietHoursEnabled = true;
  int _appIconBadgeCount = 12;
  String? _activePushNotice;
  bool _showCelebrationModal = false;
  bool _showFeedbackSheet = false;
  bool _prefsLoaded = false;
  bool _signOutRequested = false;
  bool _openBellRequested = false;
  bool _homeRefreshRequested = false;
  int _bellUnread = 0;
  bool _openProfileRoles = false;
  bool _hideBottomNav = false;

  ThemeMode get themeMode => _themeMode;
  DesignConcept get currentDesign => _currentDesign;
  TrackerState get tracker => _tracker;
  UserProfile get user => _user;
  DashboardMetrics get metrics => _metrics;
  List<InterviewEvent> get interviews => _interviews;
  QuestionOfTheDay get qotd => _qotd;
  WeeklyChallenge get challenge => _challenge;
  List<DailyTask> get tasks => _tasks;
  List<InboxItem> get inbox => _inbox;
  bool get openApplicationsReview => _openApplicationsReview;
  List<HomeMetricKey> get visibleMetricKeys => List.unmodifiable(_visibleMetricKeys);
  int get mainTabIndex => _mainTabIndex;
  bool get liveActivityEnabled => _liveActivityEnabled;
  bool get biometricLocked => _biometricLocked;
  bool get quietHoursEnabled => _quietHoursEnabled;
  int get appIconBadgeCount => _appIconBadgeCount;
  String? get activePushNotice => _activePushNotice;
  bool get showCelebrationModal => _showCelebrationModal;
  bool get showFeedbackSheet => _showFeedbackSheet;
  bool get prefsLoaded => _prefsLoaded;
  bool get signOutRequested => _signOutRequested;
  bool get openBellRequested => _openBellRequested;
  /// Callers: FocusShell._onAppState. Set by NotificationsPage after putSettings.
  bool get homeRefreshRequested => _homeRefreshRequested;
  int get bellUnread => _bellUnread;
  bool get openProfileRoles => _openProfileRoles;
  bool get hideBottomNav => _hideBottomNav;

  int get unreadInboxCount => _inbox.where((i) => !i.isRead).length;

  /// True while a full-height in-tab overlay should cover the pill bar (e.g. job sheet).
  void setBottomNavHidden(bool hide) {
    if (_hideBottomNav == hide) return;
    _hideBottomNav = hide;
    notifyListeners();
  }

  Future<void> loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey);
      if (stored != null && stored.isNotEmpty) {
        final parsed = stored
            .map((name) {
              try {
                return HomeMetricKey.values.byName(name);
              } catch (_) {
                return null;
              }
            })
            .whereType<HomeMetricKey>()
            .toList();
        if (parsed.isNotEmpty) {
          _visibleMetricKeys = parsed.take(4).toList();
        }
      }
      _themeMode = switch (prefs.getString(_themeKey)) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
    } catch (e) {
      debugPrint('Focus prefs load failed: $e');
    }
    _prefsLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };
      await prefs.setString(_themeKey, value);
    } catch (e) {
      debugPrint('Theme prefs save failed: $e');
    }
  }

  Future<void> setVisibleMetrics(List<HomeMetricKey> keys) async {
    final next = keys.take(4).toList();
    if (next.isEmpty) return;
    _visibleMetricKeys = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        _visibleMetricKeys.map((k) => k.name).toList(),
      );
    } catch (e) {
      debugPrint('Focus prefs save failed: $e');
    }
  }

  String metricValue(HomeMetricKey key) {
    switch (key) {
      case HomeMetricKey.totalApplied:
        return '${_metrics.totalApplications}';
      case HomeMetricKey.weekApplied:
        return '${_metrics.weekApplications}';
      case HomeMetricKey.interviews:
        return '${_metrics.upcomingInterviews}';
      case HomeMetricKey.responses:
        return '${_metrics.responsesReceived}';
      case HomeMetricKey.daysLeft:
        return '${_user.daysLeft}';
      case HomeMetricKey.hoursSaved:
        return '${_metrics.hoursSaved}';
    }
  }

  void setMainTabIndex(int index) {
    if (index < 0 || index > 4 || index == _mainTabIndex) return;
    _mainTabIndex = index;
    notifyListeners();
  }

  void setDesign(DesignConcept design) {
    _currentDesign = design;
    notifyListeners();
  }

  void setTrackerScenario(TrackerState state) {
    _tracker = state;
    _appIconBadgeCount = state.todayCount;
    notifyListeners();
  }

  void answerQotd(int selectedIndex) {
    if (_qotd.isAnswered) return;
    final isCorrect = selectedIndex == _qotd.correctOptionIndex;
    _qotd = _qotd.copyWith(
      isAnswered: true,
      selectedOption: selectedIndex,
      currentStreak: isCorrect ? _qotd.currentStreak + 1 : _qotd.currentStreak,
    );
    notifyListeners();
  }

  void toggleChallengeCompleted() {
    _challenge = _challenge.copyWith(isCompleted: !_challenge.isCompleted);
    if (_challenge.isCompleted) {
      _showCelebrationModal = true;
    }
    notifyListeners();
  }

  void toggleTask(String taskId) {
    _tasks = _tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();
    notifyListeners();
  }

  /// Switch to Applications and ask it to open Review mode (Home evening card).
  void requestApplicationsReview() {
    _mainTabIndex = 1;
    _openApplicationsReview = true;
    notifyListeners();
  }

  void clearApplicationsReviewRequest() {
    if (!_openApplicationsReview) return;
    _openApplicationsReview = false;
    notifyListeners();
  }

  void markInboxRead(String id) {
    _inbox = _inbox.map((item) {
      if (item.id == id) return item.copyWith(isRead: true);
      return item;
    }).toList();
    notifyListeners();
  }

  void toggleLiveActivity() {
    _liveActivityEnabled = !_liveActivityEnabled;
    notifyListeners();
  }

  void toggleBiometrics() {
    _biometricLocked = !_biometricLocked;
    notifyListeners();
  }

  void toggleQuietHours() {
    _quietHoursEnabled = !_quietHoursEnabled;
    notifyListeners();
  }

  void requestOpenBell() {
    _openBellRequested = true;
    _mainTabIndex = 2;
    notifyListeners();
  }

  void clearOpenBellRequest() {
    if (!_openBellRequested) return;
    _openBellRequested = false;
    notifyListeners();
  }

  /// Settings timezone/prefs change → shell reloads GET /api/me/home/screen.
  void requestHomeRefresh() {
    _homeRefreshRequested = true;
    notifyListeners();
  }

  void clearHomeRefreshRequest() {
    if (!_homeRefreshRequested) return;
    _homeRefreshRequested = false;
    notifyListeners();
  }

  void setBellUnread(int count) {
    if (_bellUnread == count) return;
    _bellUnread = count;
    notifyListeners();
  }

  void triggerFakePush(String message) {
    _activePushNotice = message;
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      _activePushNotice = null;
      notifyListeners();
    });
  }

  void setCelebration(bool show) {
    _showCelebrationModal = show;
    notifyListeners();
  }

  void setFeedbackSheet(bool show) {
    _showFeedbackSheet = show;
    notifyListeners();
  }

  void requestSignOut() {
    _signOutRequested = true;
    notifyListeners();
  }

  void clearSignOutRequest() {
    if (!_signOutRequested) return;
    _signOutRequested = false;
    notifyListeners();
  }

  /// Jump to Profile and open Roles of interest editor.
  void requestProfileRoles() {
    _mainTabIndex = 4;
    _openProfileRoles = true;
    notifyListeners();
  }

  void clearProfileRolesRequest() {
    if (!_openProfileRoles) return;
    _openProfileRoles = false;
    notifyListeners();
  }
}
