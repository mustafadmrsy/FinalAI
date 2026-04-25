import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/providers/notes_provider.dart';
import '../providers/upload_provider.dart';

class AiProcessingScreen extends ConsumerStatefulWidget {
  const AiProcessingScreen({super.key});

  @override
  ConsumerState<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends ConsumerState<AiProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _tipTimer;
  int _tipIndex = 0;

  static const _tips = <String>[
    'Kısa tekrarlar uzun çalışmadan daha etkilidir.',
    'Özet çıkarırken ana kavramları başlık haline getir.',
    'Kendine mini-quiz soruları sor: “Bunu biri sorsa nasıl anlatırım?”',
    'Yanlış yaptığın soruları bir “hata defteri”ne yaz.',
    'Bugün 15 dk bile olsa devam et. İstikrar kazanır.',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % _tips.length;
      });
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(uploadProvider, (prev, next) {
      if (next.status == UploadStatus.done && next.resultId != null) {
        // Ensure home screen shows the newly created note immediately.
        ref.invalidate(recentNotesProvider);
        // Defer navigation to avoid triggering go_router during rebuilds.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Hazırlanıyor'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TokenBar(
                used: state.lastAiTokensUsed,
                remaining: state.aiTokensRemainingToday,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulseOrb(controller: _controller),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        state.message.isEmpty ? 'Başlatılıyor...' : state.message,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: 260,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: state.progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '%${(state.progress.clamp(0.0, 1.0) * 100).round()}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _tips[_tipIndex],
                          key: ValueKey(_tipIndex),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenBar extends StatelessWidget {
  const _TokenBar({required this.used, required this.remaining});

  final int? used;
  final int? remaining;

  @override
  Widget build(BuildContext context) {
    final usedText = used == null ? '-' : used.toString();
    final remainingText = remaining == null ? '-' : remaining.toString();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, color: Colors.white70),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Token: Kullanılan $usedText · Kalan $remainingText',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseOrb extends StatelessWidget {
  const _PulseOrb({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.36;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final s = 0.92 + (0.08 * (1 - (2 * (t - 0.5)).abs()));
        return Transform.scale(
          scale: s,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF9B87F5),
                  Color(0xFF6E5AEF),
                  Color(0xFF1B1B2A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6E5AEF).withOpacity(0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.56,
                height: size * 0.56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
