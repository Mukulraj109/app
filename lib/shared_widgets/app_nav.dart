import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/home_tokens.dart';

/// Canonical FirstStep URLs used by CTAs across tabs.
abstract final class AppUrls {
  static const site = 'https://firststepjob.com';
  static const plans = 'https://firststepjob.com/plans';
  static const booking = 'https://firststepjob.com/book';
  static const whatsapp = String.fromEnvironment('WHATSAPP_URL', defaultValue: '');
  static const referral = 'https://firststepjob.com/r';

  /// Personal invite link; falls back to generic referral URL.
  static String referralFor(String? code) {
    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty) return referral;
    return '$site/r/${Uri.encodeComponent(trimmed)}';
  }

  static String inviteShareText(String? code) {
    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Join FirstStep with me';
    }
    return 'Join FirstStep with my code $trimmed';
  }
}

Future<void> openExternal(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  final uri = Uri.parse(trimmed);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> shareText(BuildContext context, String title, String url) async {
  await Share.share('$title\n$url', subject: title);
}

PageRoute<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

Future<T?> pushSlide<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(slideRoute<T>(page));
}

/// Settings-style chrome used by every new pushed page.
class AppPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.chevron_left, color: t.ink, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                  ),
                  if (actions == null || actions!.isEmpty)
                    const SizedBox(width: 42)
                  else
                    ...actions!,
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
