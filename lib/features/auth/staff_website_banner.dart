import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/welcome_tokens.dart';

/// Full-screen block for staff accounts — mobile is candidates only.
class StaffWebsiteBanner extends StatelessWidget {
  const StaffWebsiteBanner({
    super.key,
    required this.websiteUrl,
    required this.onSignOut,
  });

  final String? websiteUrl;
  final VoidCallback onSignOut;

  Future<void> _openWebsite() async {
    final raw = websiteUrl;
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WelcomeTokens>() ?? WelcomeTokens.light;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0B429)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF9A6700)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This account is for the FirstStep website. The mobile app is for candidates only.',
                        style: TextStyle(
                          fontFamily: 'Geologica',
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C4300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Use the website version',
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                websiteUrl == null
                    ? 'Open FirstStep in a browser to reach your staff portal.'
                    : 'Open your staff portal in the browser. You will sign in there separately.',
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 15,
                  height: 1.4,
                  color: tokens.ink.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              if (websiteUrl != null) ...[
                FilledButton(
                  onPressed: _openWebsite,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF023345),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Open website',
                    style: TextStyle(
                      fontFamily: 'Geologica',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF023345),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF023345)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontFamily: 'Geologica',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
