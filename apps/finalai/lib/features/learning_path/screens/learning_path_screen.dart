import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/learning_path_providers.dart';
import '../widgets/zigzag_path_list.dart';
import '../widgets/duo_circle_node.dart';
import '../widgets/tasks/task_helpers.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final units = ref.watch(learningUnitsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: units.when(
          loading: () => const Center(child: LoadingIndicator(message: 'Uniteler hazirlaniyor...')),
          error: (e, _) => Center(
            child: EmptyState(
              title: 'Uniteler yuklenemedi',
              message: e.toString(),
              icon: Icons.error_outline,
            ),
          ),
          data: (list) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Text('Egitim Yolun', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: px.heroDeco(PxIcons.xpColor, PxIcons.xpDark, depth: 3),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(PxIcons.xpIcon, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: ZigzagPathList(
                    itemCount: list.length,
                    itemBuilder: (context, i, isLeft) {
                      final u = list[i];
                      return DuoCircleNode(
                        label: u.title,
                        progress: u.progress,
                        isLocked: u.isLocked,
                        onTap: () => context.push('/path/unit/${u.index}'),
                      );
                    },
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
