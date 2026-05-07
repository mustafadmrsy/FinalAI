import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/ui/app_assets.dart';
import '../../../core/ui/widgets/app_svg_icon.dart';
import '../../home/providers/notes_provider.dart';
import '../providers/upload_provider.dart';

class AiProcessingScreen extends ConsumerStatefulWidget {
  const AiProcessingScreen({super.key});

  @override
  ConsumerState<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends ConsumerState<AiProcessingScreen> {
  Timer? _tipTimer;
  int _tipIndex = 0;
  int _elapsedSeconds = 0;
  late DateTime _startTime;

  static const _tips = <String>[
    '💡 Kısa tekrarlar uzun çalışmadan daha etkilidir.',
    '📝 Özet çıkarırken ana kavramları başlık haline getir.',
    '🤔 Kendine mini-quiz soruları sor: "Bunu biri sorsa nasıl anlatırım?"',
    '📖 Yanlış yaptığın soruları bir "hata defteri"ne yaz.',
    '🔥 Bugün 15 dk bile olsa devam et. İstikrar kazanır.',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % _tips.length;
      });
    });
    // Elapsed time counter
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  String _getStatusEmoji(double progress) {
    if (progress < 0.2) return 'Dosya okunuyor...';
    if (progress < 0.5) return 'AI analiz ediyor...';
    if (progress < 0.8) return 'Sorular hazırlanıyor...';
    return 'Neredeyse bitti!';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(uploadProvider, (prev, next) {
      if (next.status == UploadStatus.done && next.resultId != null) {
        ref.invalidate(recentNotesProvider);
        Future.microtask(() {
          if (!mounted) return;
          context.go('/home');
          ref.read(uploadProvider.notifier).reset();
        });
      }

      if (next.status == UploadStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Bir hata oluştu')),
        );
      }
    });

    final state = ref.watch(uploadProvider);
    final theme = Theme.of(context);
    final progress = state.progress.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeText = minutes > 0
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '${seconds}s';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('AI Analiz', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  // Token badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.12 * 255).round()),
                      borderRadius: AppRadius.full,
                      border: Border.all(color: AppColors.primary.withAlpha((0.3 * 255).round())),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppSvgIcon(AppAssets.gameLightning, size: 14, color: AppColors.xp),
                        const SizedBox(width: 4),
                        Text(
                          state.aiTokensRemainingToday != null ? '${state.aiTokensRemainingToday}' : '-',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── MASCOT ANIMATION ───
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.08 * 255).round()),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.primary.withAlpha((0.2 * 255).round()), width: 3),
                      ),
                      child: ClipOval(
                        child: Center(
                          child: Transform.scale(
                            scale: 1.45,
                            child: Align(
                              alignment: Alignment.center,
                              widthFactor: 0.62,
                              heightFactor: 0.62,
                              child: Lottie.asset(
                                AppAssets.mascotCuteCupReading,
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ─── STATUS MESSAGE ───
                    Text(
                      state.message.isEmpty ? _getStatusEmoji(progress) : state.message,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ─── PROGRESS BAR (Game-style) ───
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppRadius.xl,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('İlerleme', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: AppRadius.full,
                                    ),
                                    child: Text(
                                      '%$progressPercent',
                                      style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(timeText, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ClipRRect(
                            borderRadius: AppRadius.full,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: AppColors.primary.withAlpha((0.12 * 255).round()),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ─── TIP CARD ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha((0.08 * 255).round()),
                        borderRadius: AppRadius.lg,
                        border: Border.all(color: AppColors.warning.withAlpha((0.25 * 255).round())),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _tips[_tipIndex],
                          key: ValueKey(_tipIndex),
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── BOTTOM INFO ───
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Uzun PDF\'ler 2-5 dakika sürebilir',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
