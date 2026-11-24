import 'package:flutter/material.dart';
import '../../theme/firststep_theme.dart';

class CelebrationOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const CelebrationOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: FirstStepTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: FirstStepColors.warmCream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration_rounded, color: FirstStepColors.warmInk, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Milestone Unlocked! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: FirstStepColors.teal,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You earned the Weekly Warrior badge and 25 career reward points. Priya has been notified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: FirstStepColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FirstStepColors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onDismiss,
                child: const Text('Claim Reward', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
