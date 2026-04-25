import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Günlük hedef', style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text('Bugün 10 soru çöz', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
