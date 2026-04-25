import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Premium', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sınırsız PDF yükle, gelişmiş çalışma planı.',
              style: AppTypography.bodyMedium,
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Satın al (${AppConstants.premiumPrice})',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
