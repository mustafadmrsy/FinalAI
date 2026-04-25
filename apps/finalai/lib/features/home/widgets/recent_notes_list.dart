import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/repository_providers.dart';
import '../providers/notes_provider.dart';

class RecentNotesList extends ConsumerWidget {
  const RecentNotesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son notlar', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),
        notes.when(
          data: (items) {
            if (items.isEmpty) {
              return const BaseCard(
                child: EmptyState(
                  title: 'Henüz not yok',
                  message: 'PDF yükleyerek ilk notunu oluşturabilirsin.',
                  icon: Icons.description_outlined,
                ),
              );
            }

            return Column(
              children: items
                  .map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: BaseCard(
                        onTap: () => context.go('/result/${n.id}'),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.subject, style: AppTypography.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Aç', style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final newName = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => _EditNoteDialog(currentName: n.subject),
                                  );
                                  if (newName != null && newName.isNotEmpty) {
                                    await ref.watch(noteRepositoryProvider).updateNoteSubject(n.id, newName);
                                    ref.invalidate(recentNotesProvider);
                                  }
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Notu sil?'),
                                      content: const Text('Bu işlem geri alınamaz.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('İptal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Sil', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.watch(noteRepositoryProvider).deleteNote(n.id);
                                    ref.invalidate(recentNotesProvider);
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('İsim değiştir')),
                                const PopupMenuItem(value: 'delete', child: Text('Sil')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const BaseCard(
            child: LoadingIndicator(message: 'Notlar yükleniyor...'),
          ),
          error: (e, _) => BaseCard(
            borderColor: AppColors.error,
            child: EmptyState(
              title: 'Notlar yüklenemedi',
              message: e.toString(),
              icon: Icons.error_outline,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditNoteDialog extends StatefulWidget {
  const _EditNoteDialog({required this.currentName});

  final String currentName;

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Not ismini değiştir'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Yeni isim'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
