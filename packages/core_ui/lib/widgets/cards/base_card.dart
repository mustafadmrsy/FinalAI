import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final resolvedBorderColor = borderColor ?? theme.dividerColor;

    return GestureDetector(
      onTap: onTap != null ? () { HapticFeedback.lightImpact(); onTap!(); } : null,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: resolvedColor,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: resolvedBorderColor,
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
