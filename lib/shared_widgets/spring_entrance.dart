import 'dart:async';

import 'package:flutter/material.dart';

/// Staggered fade/slide entrance for list blocks.
///
/// In an [IndexedStack] (Focus shell), offstage tabs have [TickerMode] off.
/// We must not keep opacity at 0 on those tabs — that reads as a full-screen
/// wash when switching tabs or on first paint.
class SpringEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? delay;

  const SpringEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
  });

  @override
  State<SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<SpringEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _armed = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    final spring = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(spring);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.55, curve: Curves.easeIn),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(spring);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1.0;
      _armed = true;
      return;
    }
    if (!_armed) {
      _armed = true;
    }
    _kickEntrance();
  }

  void _kickEntrance() {
    if (!mounted || _ctrl.value >= 1.0) return;
    if (!TickerMode.of(context)) return;
    if (_ctrl.isAnimating) return;

    _delayTimer?.cancel();
    final delay = widget.delay ?? Duration(milliseconds: 60 * widget.index);
    if (delay <= Duration.zero) {
      _ctrl.forward();
      return;
    }
    _delayTimer = Timer(delay, () {
      if (mounted && TickerMode.of(context) && _ctrl.value < 1.0) {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticking = TickerMode.of(context);

    // Offstage shell tabs: show content at full strength (no 0-opacity layer).
    if (!ticking) {
      return widget.child;
    }

    if (_ctrl.value < 1.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _kickEntrance());
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
