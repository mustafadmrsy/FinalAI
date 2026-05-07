import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/ui/app_assets.dart';

class ConfirmPlanStep extends StatefulWidget {
  const ConfirmPlanStep({
    super.key,
    required this.subject,
    required this.goal,
    required this.dailyMinutes,
    required this.placementLevel,
    required this.placementScore,
    required this.isSaving,
    required this.onCreatePlan,
  });

  final String subject;
  final String goal;
  final int dailyMinutes;
  final String placementLevel;
  final int placementScore;
  final bool isSaving;
  final VoidCallback onCreatePlan;

  @override
  State<ConfirmPlanStep> createState() => _ConfirmPlanStepState();
}

class _ConfirmPlanStepState extends State<ConfirmPlanStep> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  int _loadingPhase = 0;
  static const _phases = [
    'Konular analiz ediliyor...',
    'Uniteler olusturuluyor...',
    'Dersler hazirlaniyor...',
    'Son dokunuslar...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _cyclePhases();
  }

  void _cyclePhases() async {
    while (mounted && widget.isSaving) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _loadingPhase = (_loadingPhase + 1) % _phases.length);
    }
  }

  @override
  void didUpdateWidget(covariant ConfirmPlanStep old) {
    super.didUpdateWidget(old);
    if (widget.isSaving && !old.isSaving) {
      _loadingPhase = 0;
      _cyclePhases();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return widget.isSaving ? _buildLoading(theme) : _buildSummary(theme);
  }

  Widget _buildLoading(ThemeData theme) {
    return SizedBox(
      height: 500,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mascot with animated glow ring
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (ctx, child) {
                final scale = 1.0 + (_pulseCtrl.value * 0.06);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.primary.withAlpha(20), Colors.transparent],
                        stops: const [0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withAlpha(25), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: ClipOval(
                      child: Lottie.asset(
                        AppAssets.mascotCuteCupReading,
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 3D progress bar
            Container(
              width: 220,
              height: 12,
              decoration: BoxDecoration(
                color: theme.dividerColor.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Planin hazirlaniyor...',
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            // Phase text with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _phases[_loadingPhase],
                key: ValueKey(_loadingPhase),
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Text(
                '${widget.subject} • ${widget.placementLevel}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Mascot peek
        Center(
          child: SizedBox(
            width: 110,
            height: 110,
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.primary.withAlpha(15), Colors.transparent],
                  ),
                ),
                child: Lottie.asset(
                  AppAssets.mascotCuteCupReading,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text('Haziriz!', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Secimlerini kontrol et ve ogrenme yolunu olustur.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        _SummaryRow(icon: Icons.school_rounded, color: AppColors.primary, label: 'Konu', value: widget.subject, theme: theme),
        const SizedBox(height: 10),
        _SummaryRow(icon: Icons.flag_rounded, color: const Color(0xFFFF9600), label: 'Hedef', value: widget.goal, theme: theme),
        const SizedBox(height: 10),
        _SummaryRow(icon: Icons.timer_rounded, color: const Color(0xFF1CB0F6), label: 'Gunluk sure', value: '${widget.dailyMinutes} dk / gun', theme: theme),
        const SizedBox(height: 10),
        _SummaryRow(icon: Icons.trending_up_rounded, color: const Color(0xFF58CC02), label: 'Seviye', value: '${widget.placementLevel} (skor: ${widget.placementScore}%)', theme: theme),

        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Planini olustur',
          icon: Icons.auto_awesome_rounded,
          onPressed: widget.onCreatePlan,
          height: 58,
          depth: 8,
          expand: true,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withAlpha(40), color.withAlpha(20)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withAlpha(25), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
