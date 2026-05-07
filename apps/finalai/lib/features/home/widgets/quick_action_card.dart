import 'package:flutter/material.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final c = color ?? PxDecor.teal;
    final dark = HSLColor.fromColor(c).withLightness((HSLColor.fromColor(c).lightness - 0.15).clamp(0, 1)).toColor();

    return GestureDetector(
      onTap: () { Haptic.light(); onTap(); },
      child: Container(
        height: 80,
        decoration: px.heroDeco(c, dark),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
