import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class AppSegmentedTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 44,
  });

  final TabController controller;
  final List<Widget> tabs;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.titleMedium,
        indicator: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
