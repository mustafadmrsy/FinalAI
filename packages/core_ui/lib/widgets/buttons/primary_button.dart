import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_typography.dart';
import 'expressive_button.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.foregroundColor,
    this.height = 52,
    this.depth = 6,
    this.borderRadius,
    this.borderSide,
    this.expand = true,
    this.feedbackController,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final Color? foregroundColor;
  final double height;
  final double depth;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final bool expand;
  final ButtonFeedbackController? feedbackController;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;

    Widget button = ExpressiveButton(
      onPressed: isLoading ? null : onPressed,
      height: height,
      backgroundColor: bg,
      foregroundColor: fg,
      borderRadius: borderRadius ?? AppRadius.lg,
      borderSide: borderSide,
      depth: depth,
      controller: feedbackController,
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
