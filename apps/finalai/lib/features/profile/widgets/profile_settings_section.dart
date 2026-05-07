import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/theme_service.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';

class ProfileSettingsSection extends ConsumerWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: px.text)),
        const SizedBox(height: 12),

        // Theme toggle
        GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: px.cardDeco(),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: px.accentBg(PxDecor.teal),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PxDecor.teal, width: 2),
                ),
                child: Icon(isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, color: PxDecor.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tema', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: px.text)),
                const SizedBox(height: 2),
                Text(isDark ? 'Karanlik' : 'Aydinlik', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textSub)),
              ])),
              Switch(
                value: isDark,
                activeColor: PxDecor.teal,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // Tip card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: px.accentBg(PxDecor.gold),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PxDecor.gold, width: 2),
            boxShadow: [BoxShadow(color: PxDecor.goldDark.withAlpha(px.isDark ? 25 : 50), offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: PxDecor.gold, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.tips_and_updates_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ipucu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: px.isDark ? PxDecor.gold : PxDecor.goldDark)),
              const SizedBox(height: 2),
              Text('Kisa tekrarlar uzun calismadan daha etkilidir.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textSub)),
            ])),
          ]),
        ),
      ],
    );
  }
}
