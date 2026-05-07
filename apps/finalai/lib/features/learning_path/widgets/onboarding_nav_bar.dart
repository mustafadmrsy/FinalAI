import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class OnboardingNavBar extends StatelessWidget {
  const OnboardingNavBar({
    super.key,
    required this.isSaving,
    required this.step,
    required this.totalSteps,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
  });

  final bool isSaving;
  final int step;
  final int totalSteps;
  final bool canGoNext;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;

    return Row(
      children: [
        Expanded(
          child: GhostButton(
            label: 'Geri',
            onPressed: isSaving ? null : onBack,
            height: 54,
            depth: 4,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: PrimaryButton(
            label: isLast ? 'Bitti' : 'Devam',
            icon: Icons.arrow_forward_rounded,
            onPressed: isSaving || !canGoNext ? null : onNext,
            height: 54,
            depth: 8,
            expand: true,
          ),
        ),
      ],
    );
  }
}
