import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../data/onboarding_options.dart';

class GoalDurationStep extends StatelessWidget {
  const GoalDurationStep({
    super.key,
    required this.selectedGoal,
    required this.selectedMinutes,
    required this.onGoalSelected,
    required this.onMinutesSelected,
  });

  final String? selectedGoal;
  final int selectedMinutes;
  final ValueChanged<String> onGoalSelected;
  final ValueChanged<int> onMinutesSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Hedefin ne?', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Ogrenme amacina gore plan seklini belirleyelim.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        // Goal cards — 3D game style
        ...OnboardingOptions.goals.map((g) {
          final selected = selectedGoal == g.label;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onGoalSelected(g.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withAlpha(15) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : theme.dividerColor.withAlpha(80),
                    width: selected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
                    BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withAlpha(20) : theme.dividerColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Center(child: Text(g.emoji, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.label, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(g.desc, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Container(
                              key: const ValueKey('check'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            )
                          : const SizedBox(key: ValueKey('empty'), width: 32),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 28),
        Text('Gunluk ne kadar zaman ayirabilirsin?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        // Duration pills — 3D game style
        Row(
          children: OnboardingOptions.durations.map((d) {
            final selected = selectedMinutes == d.minutes;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onMinutesSelected(d.minutes),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withAlpha(15) : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? AppColors.primary : theme.dividerColor.withAlpha(80),
                        width: selected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(color: AppColors.primary.withAlpha(35), blurRadius: 10, offset: const Offset(0, 4)),
                        BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(d.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(
                          '${d.minutes}',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: selected ? AppColors.primary : theme.colorScheme.onSurface),
                        ),
                        Text('dk/gun', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
