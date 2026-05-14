import 'package:flutter/material.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../models/user_stats_model.dart';
import '../../../core/services/game_engine_service.dart';

// ═══════════════════════════════════════════════════════════════
//  GREEN XP BADGE — Küçük yeşil arka planlı seviye+XP göstergesi
//  Her ekranın sağ üstünde ortak kullanılır, tıklayınca popup
// ═══════════════════════════════════════════════════════════════

class GreenXpBadge extends StatelessWidget {
  const GreenXpBadge({super.key, required this.stats, this.onTap});
  final UserStatsModel stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final xp = stats.xpTotal;
    final level = GameEngineService.levelFromXp(xp);
    final xpInLevel = GameEngineService.xpInCurrentLevel(xp);
    final xpRequired = GameEngineService.xpRequiredForCurrentLevel(xp);
    final pct = xpRequired > 0 ? (xpInLevel / xpRequired).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PxDecor.green,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PxDecor.greenDark, width: 2),
          boxShadow: [BoxShadow(color: PxDecor.greenDark.withAlpha(80), offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // Level circle
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
            ),
            child: Center(child: Text('$level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, height: 1))),
          ),
          const SizedBox(width: 6),
          // XP mini progress bar + text
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(GameEngineService.formatXp(xp), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, height: 1)),
            const SizedBox(height: 3),
            SizedBox(
              width: 40, height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
