import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FinalAI', style: AppTypography.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sınavlara akıllı hazırlan',
                style: AppTypography.bodyMedium,
              ),
              const Spacer(),
              if (auth.errorMessage != null) ...[
                BaseCard(
                  borderColor: AppColors.error,
                  child: Text(auth.errorMessage!, style: AppTypography.bodyMedium),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              PrimaryButton(
                label: 'Google ile giriş',
                icon: Icons.login,
                isLoading: auth.isLoading,
                onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
              ),
              const SizedBox(height: AppSpacing.sm),
              GhostButton(
                label: 'Çıkış yap',
                onPressed: auth.session == null
                    ? null
                    : () => ref.read(authProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
