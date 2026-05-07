import 'package:flutter/material.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_typography.dart';
import 'expressive_button.dart';

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.depth = 6,
    this.borderRadius,
    this.foregroundColor,
    this.borderColor,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double depth;
  final BorderRadius? borderRadius;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foregroundColor ?? theme.colorScheme.onSurface;

    Widget button = ExpressiveButton(
      onPressed: isLoading ? null : onPressed,
      height: height,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: fg,
      borderRadius: borderRadius ?? AppRadius.lg,
      borderSide: BorderSide(color: borderColor ?? theme.dividerColor, width: 0.9),
      depth: depth,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
