import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../app_assets.dart';
import 'app_svg_icon.dart';

enum GameBadgeType { energy, xp }

class GameBadge extends StatelessWidget {
  const GameBadge({
    super.key,
    required this.type,
    required this.value,
    this.compact = false,
  });

  final GameBadgeType type;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String icon;
    final Color iconColor;
    final Color bgColor = theme.colorScheme.surface;
    final Color borderColor = theme.dividerColor;

    switch (type) {
      case GameBadgeType.energy:
        icon = AppAssets.gameLightning;
        iconColor = AppColors.xp;
        break;
      case GameBadgeType.xp:
        icon = AppAssets.xpGem;
        iconColor = const Color(0xFF58CC02);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.full,
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            icon,
            size: compact ? 16 : 18,
            color: iconColor,
            useThemeColorIfNull: false,
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: (compact ? AppTypography.labelMedium : AppTypography.titleMedium).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
