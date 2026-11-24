import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/auth_controller.dart';

/// Unpaid users finish payment on the website. No in-app checkout.
class CheckoutRedirectScreen extends StatefulWidget {
  const CheckoutRedirectScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<CheckoutRedirectScreen> createState() => _CheckoutRedirectScreenState();
}

class _CheckoutRedirectScreenState extends State<CheckoutRedirectScreen> {
  bool _busy = false;
  String? _error;

  Uri get _checkoutUri {
    final origin = widget.auth.config.safeWebAppOrigin;
    final plan = widget.auth.bootstrap?.selectedPlan;
    final params = <String, String>{};
    if (plan != null && plan.isNotEmpty) params['plan'] = plan;
    return Uri.parse('$origin/checkout').replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<void> _open() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    var ok = false;
    try {
      ok = await launchUrl(_checkoutUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _error = 'Could not open checkout in the browser.';
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.auth.bootstrap?.selectedPlan;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Finish checkout on the website',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geologica',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                plan == null
                    ? 'Payment happens in the browser. Come back and refresh when you are done.'
                    : 'Your plan ($plan) is waiting on the website. Come back and refresh when you are done.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Geologica', height: 1.4),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _open,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF023345)),
                child: Text(_busy ? 'Opening…' : 'Open checkout'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => widget.auth.refreshBootstrap(),
                child: const Text('I’ve paid — refresh'),
              ),
              TextButton(
                onPressed: () => widget.auth.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
