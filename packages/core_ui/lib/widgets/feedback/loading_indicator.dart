import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
