import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../state/app_state.dart';
import '../../scoutx/scoutx_landing.dart';

/// ScoutX tab — full marketing landing (mobile layout of the website).
///
/// Landing stays mounted; only the unread badge listens to [appState] so
/// home/bell polls do not rebuild the whole marketing page.
class ScoutXTab extends StatelessWidget {
  final AppState appState;
  final ApiClient? api;

  const ScoutXTab({super.key, required this.appState, this.api});

  @override
  Widget build(BuildContext context) {
    return ScoutXLanding(
      api: api,
      unreadListenable: appState,
      unreadOf: () => appState.bellUnread,
    );
  }
}
