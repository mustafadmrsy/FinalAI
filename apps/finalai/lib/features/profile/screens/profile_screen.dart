import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../home/providers/notes_provider.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final notes = ref.watch(recentNotesProvider);

    final profile = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hesap', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            profile.when(
              loading: () => const BaseCard(
                child: LoadingIndicator(message: 'Profil yükleniyor...'),
              ),
              error: (e, _) => BaseCard(
                borderColor: AppColors.error,
                child: EmptyState(
                  title: 'Profil yüklenemedi',
                  message: e.toString(),
                  icon: Icons.error_outline,
                ),
              ),
              data: (p) {
                final fullName = (p?['full_name'] as String?) ?? '';
                final isPremium = (p?['is_premium'] as bool?) ?? false;
                final dailyCount = (p?['daily_upload_count'] as int?) ?? 0;
                final premiumUntil = p?['premium_until']?.toString();

                return Column(
                  children: [
                    BaseCard(
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fullName.isEmpty ? 'Ad Soyad ekle' : fullName, style: AppTypography.titleMedium),
                                const SizedBox(height: 4),
                                Text(user?.email ?? '-', style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showEditNameDialog(context, ref, fullName),
                            child: const Text('Düzenle'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BaseCard(
                      child: Row(
                        children: [
                          Icon(
                            isPremium ? Icons.workspace_premium : Icons.lock_outline,
                            color: isPremium ? AppColors.warning : AppColors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPremium ? 'Premium aktif' : 'Ücretsiz plan',
                                  style: AppTypography.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPremium && premiumUntil != null
                                      ? 'Bitiş: $premiumUntil'
                                      : 'Günlük yükleme: $dailyCount/${AppConstants.freeUploadLimit}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/premium'),
                            child: const Text('Yükselt'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Notlarım', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: notes.when(
                loading: () => const LoadingIndicator(message: 'Notlar yükleniyor...'),
                error: (e, _) => EmptyState(
                  title: 'Notlar yüklenemedi',
                  message: e.toString(),
                  icon: Icons.error_outline,
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'Henüz not yok',
                      message: 'Bir PDF yükleyerek ilk notunu oluşturabilirsin.',
                      icon: Icons.description_outlined,
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return BaseCard(
                        onTap: () => context.go('/result/${n.id}'),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(n.subject, style: AppTypography.titleMedium),
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
                      );
                    },
                  );
                },
              ),
            ),
            if (auth.errorMessage != null) ...[
              BaseCard(
                borderColor: AppColors.error,
                child: Text(auth.errorMessage!, style: AppTypography.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            PrimaryButton(
              label: 'Çıkış yap',
              icon: Icons.logout,
              isLoading: auth.isLoading,
              onPressed: auth.session == null
                  ? null
                  : () => ref.read(authProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

final _profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.watch(statsRepositoryProvider).getUserProfile();
});

Future<void> _showEditNameDialog(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  final controller = TextEditingController(text: current);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Ad Soyad'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Örn: Ali Veli'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Boş olamaz' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );

  if (result == null) return;

  await ref.read(statsRepositoryProvider).updateUserProfile(fullName: result);
  ref.invalidate(_profileProvider);
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
