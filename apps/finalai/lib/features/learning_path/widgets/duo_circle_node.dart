import 'package:flutter/material.dart';
import 'tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';

class DuoCircleNode extends StatelessWidget {
  const DuoCircleNode({
    super.key,
    required this.label,
    required this.progress,
    required this.isLocked,
    required this.onTap,
    this.accent,
    this.size = 78,
  });

  final String label;
  final double progress;
  final bool isLocked;
  final VoidCallback? onTap;
  final Color? accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final a = accent ?? PxDecor.teal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isLocked ? null : () { Haptic.medium(); onTap?.call(); },
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: isLocked ? px.surface : a,
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(color: isLocked ? px.border : a, width: 3),
              boxShadow: [BoxShadow(color: isLocked ? px.shadow : a.withAlpha(px.isDark ? 60 : 100), offset: const Offset(0, 6), blurRadius: 0)],
            ),
            child: Stack(children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    value: isLocked ? 0 : progress.clamp(0, 1),
                    strokeWidth: 6,
                    backgroundColor: isLocked ? px.border : Colors.white.withAlpha(40),
                    valueColor: AlwaysStoppedAnimation<Color>(isLocked ? px.textMuted : Colors.white),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: size - 28, height: size - 28,
                  decoration: BoxDecoration(
                    color: isLocked ? px.card : Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular((size - 28) / 2),
                    border: Border.all(color: Colors.white.withAlpha(isLocked ? 0 : 70), width: 2),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : (progress >= 1 ? Icons.check_rounded : Icons.play_arrow_rounded),
                    color: isLocked ? px.textMuted : Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: px.text), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
