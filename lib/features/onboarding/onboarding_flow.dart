import 'package:flutter/material.dart';

import '../../api/bootstrap_models.dart';
import '../../auth/auth_controller.dart';
import '../../state/app_state.dart';
import '../../theme/home_tokens.dart';

/// Post-sign-in onboarding when bootstrap destination is `onboarding`.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.auth,
    required this.appState,
  });

  final AuthController auth;
  final AppState appState;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  String? _questionId;
  int _percent = 0;
  bool _busy = false;
  String? _error;
  final _text = TextEditingController();
  final Set<String> _multi = {};
  String? _choice;

  @override
  void initState() {
    super.initState();
    final boot = widget.auth.lastBootstrap;
    _questionId = boot?.nextQuestion;
    _percent = boot?.percent ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSpecOrExit();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  OnboardingQuestionSpec? get _spec {
    final id = _questionId;
    if (id == null || id.isEmpty) return null;
    return _specFor(id);
  }

  OnboardingQuestionSpec? _specFor(String id) {
    final catalog = widget.auth.lastBootstrap?.questionCatalog ?? const [];
    for (final q in catalog) {
      if (q.questionId == id) return q;
    }
    return null;
  }

  int _percentFrom(Map<String, dynamic> response) {
    final raw = response['percent'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? _percent;
  }

  Future<void> _finishOnboarding() async {
    await widget.auth.refreshBootstrap();
    widget.auth.markOnboardingComplete();
  }

  /// Unknown / missing catalog entry must not leave the user on “Loading…”.
  Future<void> _ensureSpecOrExit() async {
    final id = _questionId;
    if (id == null || id.isEmpty) {
      await _finishOnboarding();
      return;
    }
    if (_specFor(id) != null) return;
    setState(() => _busy = true);
    try {
      await widget.auth.refreshBootstrap();
      if (!mounted) return;
      final boot = widget.auth.lastBootstrap;
      final next = boot?.nextQuestion?.trim();
      if (next == null || next.isEmpty || !boot!.needsOnboarding) {
        widget.auth.markOnboardingComplete();
        return;
      }
      if (_specFor(next) == null) {
        widget.auth.markOnboardingComplete();
        return;
      }
      setState(() {
        _questionId = next;
        _percent = boot.percent;
        _busy = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not load the next question. Tap retry.';
      });
    }
  }

  Future<void> _submit({bool skipped = false, Object? value}) async {
    final id = _questionId;
    if (id == null || id.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await widget.auth.api.answerOnboarding(
        questionId: id,
        skipped: skipped,
        value: value,
      );
      final next = response['nextQuestion'];
      final nextId = next == null ? null : '$next'.trim();
      final percent = _percentFrom(response);
      if (!mounted) return;
      if (nextId == null || nextId.isEmpty) {
        await _finishOnboarding();
        return;
      }
      if (_specFor(nextId) == null) {
        await widget.auth.refreshBootstrap();
        if (!mounted) return;
        final boot = widget.auth.lastBootstrap;
        final resolved = boot?.nextQuestion?.trim();
        if (resolved == null ||
            resolved.isEmpty ||
            _specFor(resolved) == null) {
          widget.auth.markOnboardingComplete();
          return;
        }
        setState(() {
          _questionId = resolved;
          _percent = boot?.percent ?? percent;
          _text.clear();
          _multi.clear();
          _choice = null;
          _busy = false;
        });
        return;
      }
      setState(() {
        _questionId = nextId;
        _percent = percent;
        _text.clear();
        _multi.clear();
        _choice = null;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  Future<void> _onContinue() async {
    final spec = _spec;
    if (spec == null) {
      await _ensureSpecOrExit();
      return;
    }
    switch (spec.kind) {
      case 'multi':
        await _submit(value: _multi.toList());
      case 'text':
      case 'locations':
        await _submit(value: _text.text.trim());
      default:
        if (_choice == null || _choice!.isEmpty) {
          setState(() => _error = 'Pick one to continue.');
          return;
        }
        await _submit(value: _choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    final spec = _spec;
    final progress = (_percent.clamp(0, 100)) / 100;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Finish your profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 6,
                  backgroundColor: t.line,
                  color: t.teal,
                ),
              ),
              const SizedBox(height: 20),
              if (spec == null)
                Expanded(
                  child: Center(
                    child: _busy
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error ?? 'Loading…',
                                style: TextStyle(color: t.mute),
                                textAlign: TextAlign.center,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _ensureSpecOrExit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: t.navy,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ],
                          ),
                  ),
                )
              else ...[
                Text(
                  spec.prompt,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: t.ink,
                  ),
                ),
                if (spec.hint.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      spec.hint,
                      style: TextStyle(fontSize: 13, color: t.mute),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(child: _buildInput(context, spec, t)),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: t.mute, fontSize: 13),
                  ),
                ),
              if (spec != null)
                Row(
                  children: [
                    if (spec.skippable)
                      TextButton(
                        onPressed: _busy ? null : () => _submit(skipped: true),
                        child: const Text('Skip'),
                      ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: t.navy,
                        minimumSize: const Size(120, 48),
                      ),
                      onPressed: _busy ? null : _onContinue,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    OnboardingQuestionSpec spec,
    HomeTokens t,
  ) {
    if (spec.kind == 'multi') {
      return ListView(
        children: [
          for (final opt in spec.options)
            CheckboxListTile(
              value: _multi.contains(opt.id),
              title: Text(opt.label, style: TextStyle(color: t.ink)),
              activeColor: t.teal,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _multi.add(opt.id);
                  } else {
                    _multi.remove(opt.id);
                  }
                });
              },
            ),
        ],
      );
    }
    if (spec.kind == 'text' || spec.kind == 'locations') {
      return TextField(
        controller: _text,
        maxLines: spec.kind == 'locations' ? 2 : 3,
        style: TextStyle(color: t.ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: t.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.line),
          ),
        ),
      );
    }
    return ListView(
      children: [
        for (final opt in spec.options)
          RadioListTile<String>(
            value: opt.id,
            groupValue: _choice,
            title: Text(opt.label, style: TextStyle(color: t.ink)),
            activeColor: t.teal,
            onChanged: (v) => setState(() => _choice = v),
          ),
      ],
    );
  }
}