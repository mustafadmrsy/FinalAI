import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/foreground_service.dart';
import '../providers/learning_path_providers.dart';
import '../../notifications/services/notification_service.dart';
import '../widgets/steps/subject_select_step.dart';
import '../widgets/steps/difficulty_select_step.dart';
import '../widgets/steps/placement_step.dart';
import '../widgets/steps/confirm_plan_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  String _query = '';
  String? _subject;
  String? _goal;
  int _dailyMinutes = 15;
  String _placementLevel = 'Orta';
  int _placementScore = 0;
  bool _saving = false;
  bool _planReady = false;
  bool _onboardingSaved = false;

  static const _totalSteps = 4;
  static const _stepTitles = [
    'Konu',
    'Hedef',
    'Test',
    'Olustur',
  ];

  bool get _canGoNext {
    if (_step == 0) return _subject != null;
    if (_step == 1) return _goal != null;
    return true;
  }

  Future<void> _createPlan(BuildContext context) async {
    if (_subject == null) return;

    setState(() => _saving = true);

    // Foreground service baslatarak Android'in arka planda process'i oldur/agi kesmesini engelle
    await ForegroundService.start(
      title: '$_subject plani hazirlaniyor...',
      body: 'AI ders planiniz olusturuluyor',
    );

    try {
      final repo = ref.read(learningPathRepositoryProvider);

      if (!_onboardingSaved) {
        debugPrint('[Onboarding] saveOnboarding...');
        await repo.saveOnboarding(subject: _subject!, difficulty: _placementLevel);
        _onboardingSaved = true;
        debugPrint('[Onboarding] saveOnboarding done');
      }

      try { await NotificationService.showPlanProgress(percent: 0, subject: _subject!); } catch (_) {}
      debugPrint('[Onboarding] generateAndSaveInitialPlan starting...');

      await repo.generateAndSaveInitialPlan(
        subject: _subject!,
        difficulty: _placementLevel,
        goal: _goal ?? '',
        dailyMinutes: _dailyMinutes,
        onProgress: (percent) {
          try { NotificationService.showPlanProgress(percent: percent, subject: _subject!); } catch (_) {}
        },
      );

      // ── Success ──
      debugPrint('[Onboarding] Plan saved successfully!');
      try { await NotificationService.cancelPlanProgress(); } catch (_) {}

      // Foreground service'i durdur
      await ForegroundService.stop();

      // Bildirim gonder — kullanici arka plandaysa bunu gorur
      try { await NotificationService.notifyPlanReady(subject: _subject!); } catch (_) {}

      // Provider'lari invalidate et — OnboardingGate otomatik dashboard'a gecer
      ref.invalidate(onboardingCompletedProvider);
      ref.invalidate(learningUnitsProvider);

      if (mounted) {
        setState(() { _saving = false; _planReady = true; });
        // Kutlama ekranini 3sn goster, sonra provider tekrar invalidate
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) ref.invalidate(onboardingCompletedProvider);
      }
      return;

    } catch (e, st) {
      debugPrint('[Onboarding] Plan creation failed: $e');
      debugPrint('[Onboarding] Stack: $st');
      await ForegroundService.stop();
      try { await NotificationService.cancelPlanProgress(); } catch (_) {}
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI ders planı oluşturulamadı. Lütfen tekrar deneyin.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onPlacementDone(Map<String, dynamic> result) {
    setState(() {
      _placementLevel = result['level'] as String;
      _placementScore = result['score'] as int;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Step indicators
                  Row(
                    children: List.generate(_totalSteps, (i) {
                      final isActive = i == _step;
                      final isDone = i < _step;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? AppColors.primary
                                      : isActive
                                          ? AppColors.primary.withAlpha(160)
                                          : theme.dividerColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _stepTitles[i],
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDone || isActive
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: switch (_step) {
                      0 => SubjectSelectStep(
                          key: const ValueKey('step0'),
                          query: _query,
                          selectedSubject: _subject,
                          onQueryChanged: (v) => setState(() => _query = v),
                          onSubjectSelected: (s) => setState(() => _subject = s),
                        ),
                      1 => GoalDurationStep(
                          key: const ValueKey('step1'),
                          selectedGoal: _goal,
                          selectedMinutes: _dailyMinutes,
                          onGoalSelected: (g) => setState(() => _goal = g),
                          onMinutesSelected: (m) => setState(() => _dailyMinutes = m),
                        ),
                      2 => PlacementStep(
                          key: const ValueKey('step2'),
                          subject: _subject ?? '',
                          goal: _goal,
                          dailyMinutes: _dailyMinutes,
                          onPlacementDone: _onPlacementDone,
                          onGoBack: () => setState(() => _step = 1),
                        ),
                      _ => ConfirmPlanStep(
                          key: const ValueKey('step3'),
                          subject: _subject ?? '-',
                          goal: _goal ?? '-',
                          dailyMinutes: _dailyMinutes,
                          placementLevel: _placementLevel,
                          placementScore: _placementScore,
                          isSaving: _saving,
                          isPlanReady: _planReady,
                          onCreatePlan: () => _createPlan(context),
                        ),
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            // Bottom navigation
            if (_step != 2 && !_saving)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: GhostButton(
                          label: 'Geri',
                          onPressed: () => setState(() => _step -= 1),
                          height: 52,
                          depth: 4,
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    if (_step < 3)
                      Expanded(
                        flex: 1,
                        child: PrimaryButton(
                          label: 'Devam',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _canGoNext
                              ? () {
                                  if (_step < _totalSteps - 1) {
                                    setState(() => _step += 1);
                                  }
                                }
                              : null,
                          height: 52,
                          depth: 8,
                          expand: true,
                        ),
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
