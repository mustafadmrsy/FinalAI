import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class PathNode extends StatelessWidget {
  const PathNode({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.isLocked,
    required this.onTap,
    this.accent,
  });

  final String title;
  final String subtitle;
  final double progress;
  final bool isLocked;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = accent ?? AppColors.primary;

    return ExpressiveButton(
      onPressed: isLocked ? null : onTap,
      height: 78,
      backgroundColor: isLocked ? theme.colorScheme.surface : a.withAlpha((0.12 * 255).round()),
      foregroundColor: isLocked ? theme.colorScheme.onSurface : a,
      borderRadius: AppRadius.xl,
      borderSide: BorderSide(
        color: isLocked ? theme.dividerColor : a.withAlpha((0.5 * 255).round()),
        width: isLocked ? 0.8 : 1.2,
      ),
      depth: isLocked ? 4 : 10,
      child: Row(
        children: [
          _Ring(
            progress: progress,
            accent: isLocked ? AppColors.textMuted : a,
            locked: isLocked,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isLocked ? AppColors.textMuted : a).withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor, width: 0.8),
            ),
            child: Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
              color: isLocked ? AppColors.textMuted : a,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.accent, required this.locked});

  final double progress;
  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: locked ? 0 : progress.clamp(0, 1),
              strokeWidth: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                locked ? Icons.lock_outline_rounded : Icons.flag_outlined,
                color: accent,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
