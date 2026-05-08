import 'dart:math';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/game_engine_service.dart';
import '../models/learning_lesson_model.dart';
import '../providers/learning_path_providers.dart';
import '../widgets/tasks/task_helpers.dart';
import '../widgets/tasks/matching_task.dart';
import '../widgets/tasks/order_steps_task.dart';
import '../widgets/tasks/fill_blank_task.dart';
import '../widgets/tasks/tap_select_task.dart';
import '../widgets/tasks/spot_error_task.dart';
import '../widgets/tasks/image_select_task.dart';
import '../widgets/tasks/translate_sentence_task.dart';
import '../widgets/tasks/speak_word_task.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../../core/ui/widgets/pixel_confirm_dialog.dart';
import '../../../core/services/haptic_service.dart';
import '../../stats/widgets/level_up_popup.dart';
import '../widgets/unit_complete_overlay.dart';
import '../widgets/combo_overlay.dart';
import '../../shop/widgets/quota_popup.dart';

// ═══════════════════════════════════════════════════════════
//  LESSON SCREEN — Multi-step (8 adim) pixel game ders akisi
// ═══════════════════════════════════════════════════════════

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.unitIndex, required this.lessonIndex});
  final int unitIndex;
  final int lessonIndex;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  LearningLessonModel? _lesson;
  bool _loading = true;
  bool _completing = false;
  bool _exiting = false;
  bool _isLastLessonInUnit = false;

  // Multi-step state
  List<Map<String, dynamic>> _items = [];
  int _currentStep = 0;
  bool _answered = false;
  bool _correct = false;
  int _wrongAttempts = 0;
  int _correctCount = 0;
  int _totalWrong = 0;
  int _consecutiveCorrect = 0;
  int _livesRemaining = 3;
  bool _answerRevealed = false;
  int _skipsUsed = 0;
  static const _maxSkips = 2;
  DateTime _lastCorrectTime = DateTime(2000);

  // GlobalKeys — her adim yeni key alir
  GlobalKey<MatchingTaskState> _matchingKey = GlobalKey<MatchingTaskState>();
  GlobalKey<OrderStepsTaskState> _orderKey = GlobalKey<OrderStepsTaskState>();
  GlobalKey<FillBlankTaskState> _fillKey = GlobalKey<FillBlankTaskState>();
  GlobalKey<TapSelectTaskState> _tapKey = GlobalKey<TapSelectTaskState>();
  GlobalKey<SpotErrorTaskState> _spotKey = GlobalKey<SpotErrorTaskState>();
  GlobalKey<ImageSelectTaskState> _imageKey = GlobalKey<ImageSelectTaskState>();
  GlobalKey<TranslateSentenceTaskState> _translateKey = GlobalKey<TranslateSentenceTaskState>();
  GlobalKey<SpeakWordTaskState> _speakKey = GlobalKey<SpeakWordTaskState>();

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  void _onTaskChanged() { if (mounted) setState(() {}); }

  Future<void> _confirmExit(BuildContext context) async {
    if (_exiting) return;
    if (_currentStep == 0 && _correctCount == 0) {
      _exiting = true;
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await PixelConfirmDialog.show(
      context,
      icon: Icons.exit_to_app_rounded,
      iconColor: PxDecor.orange,
      title: 'Dersten Cik?',
      message: 'Dersten cikarsan ilerlemen kaybolacak.\nEmin misin?',
      confirmLabel: 'Cik',
      cancelLabel: 'Devam Et',
      confirmColor: PxDecor.red,
      confirmDark: PxDecor.redDark,
      showWarningBadge: true,
      warningText: 'Ilerleme kaydedilmeyecek!',
    );
    if (confirmed && mounted) {
      _exiting = true;
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadLesson() async {
    try {
      final lessons = await ref.read(learningPathRepositoryProvider).getLessonsByUnit(widget.unitIndex);
      _isLastLessonInUnit = widget.lessonIndex >= lessons.length;
      final hit = lessons.where((l) => l.lessonIndex == widget.lessonIndex);
      if (hit.isNotEmpty) {
        _lesson = hit.first;
        // items dizisini oku; eski formatta items yoksa tek item olarak wrap et
        final tc = _lesson!.taskContent;
        final rawItems = tc['items'] as List?;
        if (rawItems != null && rawItems.isNotEmpty) {
          _items = rawItems.cast<Map<String, dynamic>>();
        } else {
          _items = [tc];
        }
        // Runtime shuffle: tap_select ve fill_blank seceneklerini karistir
        _shuffleItemOptions();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// Secenekleri runtime'da karistir (DB'den gelen veriler icin)
  void _shuffleItemOptions() {
    final rng = Random();
    final type = _lesson?.taskType;
    for (final item in _items) {
      if (type == 'tap_select') {
        final opts = item['options'] as List?;
        final idx = (item['correct_index'] as num?)?.toInt() ?? 0;
        if (opts != null && opts.length > 1 && idx < opts.length) {
          final correct = opts[idx];
          final shuffled = List<dynamic>.from(opts)..shuffle(rng);
          item['options'] = shuffled;
          item['correct_index'] = shuffled.indexOf(correct);
        }
      } else if (type == 'fill_blank') {
        final opts = item['options'] as List?;
        if (opts != null && opts.length > 1) {
          final shuffled = List<dynamic>.from(opts)..shuffle(rng);
          item['options'] = shuffled;
        }
      } else if (type == 'image_select') {
        final images = item['images'] as List?;
        final labels = item['labels'] as List?;
        final idx = (item['correct_index'] as num?)?.toInt() ?? 0;
        if (images != null && images.length > 1 && labels != null && labels.length == images.length && idx < images.length) {
          final indices = List.generate(images.length, (i) => i)..shuffle(rng);
          item['images'] = indices.map((i) => images[i]).toList();
          item['labels'] = indices.map((i) => labels[i]).toList();
          item['correct_index'] = indices.indexOf(idx);
        }
      } else if (type == 'translate_sentence') {
        final chips = item['word_chips'] as List?;
        if (chips != null && chips.length > 1) {
          final shuffled = List<dynamic>.from(chips)..shuffle(rng);
          item['word_chips'] = shuffled;
        }
      }
    }
  }

  // ── Current step data ────────────────────────────────
  Map<String, dynamic> get _stepData => _items.isNotEmpty ? _items[_currentStep] : {};
  int get _totalSteps => _items.length;
  bool get _isLastStep => _currentStep >= _totalSteps - 1;

  // ── Task delegation ────────────────────────────────────
  bool get _canCheck {
    switch (_lesson?.taskType) {
      case 'matching': return _matchingKey.currentState?.isReady ?? false;
      case 'order_steps': return _orderKey.currentState?.isReady ?? false;
      case 'fill_blank': return _fillKey.currentState?.isReady ?? false;
      case 'tap_select': return _tapKey.currentState?.isReady ?? false;
      case 'spot_error': return _spotKey.currentState?.isReady ?? false;
      case 'image_select': return _imageKey.currentState?.isReady ?? false;
      case 'translate_sentence': return _translateKey.currentState?.isReady ?? false;
      case 'speak_word': return _speakKey.currentState?.isReady ?? false;
      default: return false;
    }
  }

  Future<void> _checkAnswer() async {
    bool ok = false;
    switch (_lesson!.taskType) {
      case 'matching': ok = _matchingKey.currentState!.checkAnswer(); break;
      case 'order_steps': ok = _orderKey.currentState!.checkAnswer(); break;
      case 'fill_blank': ok = _fillKey.currentState!.checkAnswer(); break;
      case 'tap_select': ok = _tapKey.currentState!.checkAnswer(); break;
      case 'spot_error': ok = _spotKey.currentState!.checkAnswer(); break;
      case 'image_select': ok = _imageKey.currentState!.checkAnswer(); break;
      case 'translate_sentence': ok = _translateKey.currentState!.checkAnswer(); break;
      case 'speak_word': ok = _speakKey.currentState!.checkAnswer(); break;
    }
    setState(() {
      _answered = true;
      _correct = ok;
      if (ok) {
        _correctCount++;
        _consecutiveCorrect++;
        // Her 2 ardisik dogruda 1 can geri kazan
        if (_consecutiveCorrect % 2 == 0 && _livesRemaining < 3) {
          _livesRemaining++;
        }
        // Kombo kontrolu: 3 veya 5 ardisik dogruda animasyon + enerji
        final now = DateTime.now();
        final isFast = now.difference(_lastCorrectTime).inSeconds < 8;
        _lastCorrectTime = now;
        if (_consecutiveCorrect == 3 || _consecutiveCorrect == 5 || (_consecutiveCorrect > 5 && _consecutiveCorrect % 5 == 0)) {
          final energy = _consecutiveCorrect >= 5 ? 5 : 3;
          _awardComboEnergy(energy);
          if (mounted) {
            ComboOverlay.show(context, streak: _consecutiveCorrect, energyAwarded: energy, compact: isFast);
          }
        }
      }
      if (!ok) {
        _wrongAttempts++;
        _totalWrong++;
        _consecutiveCorrect = 0;
        _livesRemaining = (_livesRemaining - 1).clamp(0, 3);
      }
    });
    // Yanlis cevapta -3 enerji
    if (!ok) {
      try {
        await ref.read(userStatsRepositoryProvider).useEnergy(amount: 3);
        ref.invalidate(userStatsProvider);
      } catch (_) {
        // Enerji yetmezse kota popup goster
        if (mounted) {
          final rewarded = await QuotaPopup.show(context, ref, type: QuotaType.energy);
          ref.invalidate(userStatsProvider);
          if (!rewarded && mounted) { Navigator.of(context).maybePop(); return; }
        }
      }
      // Canlar bittiyse — dersi tekrar ettir
      if (_livesRemaining <= 0) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        _showRestartDialog();
        return;
      }
    }
  }

  bool get _showCorrectAnswer => _answerRevealed && !_correct;

  Future<void> _awardComboEnergy(int amount) async {
    try {
      await ref.read(userStatsRepositoryProvider).addEnergy(amount: amount);
      ref.invalidate(userStatsProvider);
    } catch (_) {}
  }

  void _retry() {
    switch (_lesson!.taskType) {
      case 'matching': _matchingKey.currentState?.reset(); break;
      case 'order_steps': _orderKey.currentState?.reset(); break;
      case 'fill_blank': _fillKey.currentState?.reset(); break;
      case 'tap_select': _tapKey.currentState?.reset(); break;
      case 'spot_error': _spotKey.currentState?.reset(); break;
      case 'image_select': _imageKey.currentState?.reset(); break;
      case 'translate_sentence': _translateKey.currentState?.reset(); break;
      case 'speak_word': _speakKey.currentState?.reset(); break;
    }
    setState(() { _answered = false; _correct = false; _answerRevealed = false; });
  }

  void _restartLesson() {
    setState(() {
      _currentStep = 0;
      _answered = false;
      _correct = false;
      _wrongAttempts = 0;
      _totalWrong = 0;
      _correctCount = 0;
      _consecutiveCorrect = 0;
      _livesRemaining = 3;
      _answerRevealed = false;
      _matchingKey = GlobalKey<MatchingTaskState>();
      _orderKey = GlobalKey<OrderStepsTaskState>();
      _fillKey = GlobalKey<FillBlankTaskState>();
      _tapKey = GlobalKey<TapSelectTaskState>();
      _spotKey = GlobalKey<SpotErrorTaskState>();
      _imageKey = GlobalKey<ImageSelectTaskState>();
      _translateKey = GlobalKey<TranslateSentenceTaskState>();
      _speakKey = GlobalKey<SpeakWordTaskState>();
      _shuffleItemOptions();
    });
  }

  void _showRestartDialog() {
    final px = Px.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: px.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PxDecor.red, width: 3),
            boxShadow: [BoxShadow(color: PxDecor.redDark, offset: const Offset(0, 6), blurRadius: 0)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: PxDecor.red, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            Text('3 Yanlis!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text)),
            const SizedBox(height: 6),
            Text('Dersi bastan tekrar etmen gerekiyor.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textSub)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () { Haptic.medium(); Navigator.of(ctx).pop(); _restartLesson(); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: PxDecor.orange,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PxDecor.orangeDark, width: 2),
                  boxShadow: [BoxShadow(color: PxDecor.orangeDark, offset: const Offset(0, 4), blurRadius: 0)],
                ),
                child: const Center(child: Text('Tekrar Baslat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _goNextStep() {
    setState(() {
      _currentStep++;
      _answered = false;
      _correct = false;
      _wrongAttempts = 0;
      _answerRevealed = false;
      // Yeni key'ler olustur ki widget yeniden olusturulsun
      _matchingKey = GlobalKey<MatchingTaskState>();
      _orderKey = GlobalKey<OrderStepsTaskState>();
      _fillKey = GlobalKey<FillBlankTaskState>();
      _tapKey = GlobalKey<TapSelectTaskState>();
      _spotKey = GlobalKey<SpotErrorTaskState>();
      _imageKey = GlobalKey<ImageSelectTaskState>();
      _translateKey = GlobalKey<TranslateSentenceTaskState>();
      _speakKey = GlobalKey<SpeakWordTaskState>();
    });
  }

  Future<void> _completeLesson() async {
    if (!_isLastStep) { _goNextStep(); return; }
    setState(() => _completing = true);
    try {
      final statsRepo = ref.read(userStatsRepositoryProvider);
      final stats = await statsRepo.getUserStats();
      final oldXp = stats?.xpTotal ?? 0;
      final oldLevel = (oldXp / 500).floor() + 1;
      final xp = GameEngineService.calculateXpReward(comboCount: stats?.comboCurrent ?? 0);
      final perfectBonus = _totalWrong == 0 ? 50 : 0;
      final totalXp = xp + perfectBonus;
      await statsRepo.updateXpAndCombo(xpGain: totalXp, comboIncrease: 1);
      final newLevel = ((oldXp + totalXp) / 500).floor() + 1;
      // Ders bitir: -1 enerji
      try { await statsRepo.useEnergy(amount: 1); } catch (_) {}
      // Gunluk gorev ilerlemesi
      await statsRepo.incrementDailyQuest(lessons: 1, xp: xp, correct: _correctCount);
      await ref.read(learningPathRepositoryProvider).completeLessonAndUnlockNext(widget.unitIndex, widget.lessonIndex);
      ref.invalidate(userStatsProvider);
      ref.invalidate(learningUnitsProvider);
      ref.invalidate(learningLessonsByUnitProvider);
      if (!mounted) return;
      _exiting = true;
      // Unite tamamlandi mi? — kutlama goster
      if (_isLastLessonInUnit && mounted) {
        await UnitCompleteOverlay.show(context);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      final bonusText = perfectBonus > 0 ? '  (+$perfectBonus bonus!)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ders tamamlandi! +$totalXp XP$bonusText  ($_correctCount/$_totalSteps dogru)', style: const TextStyle(fontWeight: FontWeight.w700)), backgroundColor: AppColors.success),
      );
      // Level up check
      if (newLevel > oldLevel && mounted) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) LevelUpPopup.show(context, newLevel: newLevel);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    if (_loading) return Scaffold(backgroundColor: px.bg, body: const Center(child: CircularProgressIndicator()));
    if (_lesson == null || _items.isEmpty) return _buildError(px);
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) _confirmExit(context); }, child: _buildBody(px, context));
  }

  Widget _buildBody(Px px, BuildContext context) {
    final meta = TaskMeta.fromType(_lesson!.taskType);

    return Scaffold(
      backgroundColor: px.bg,
      body: Column(children: [
        // Ust bar
        _TopBar(
          lesson: _lesson!, unitIndex: widget.unitIndex, meta: meta,
          currentStep: _currentStep, totalSteps: _totalSteps, correctCount: _correctCount,
          livesRemaining: _livesRemaining,
          onClose: () => _confirmExit(context),
        ),
        const SizedBox(height: 8),
        // Icerik
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            // Task container with pixel depth
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: px.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: meta.color.withAlpha(40), width: 2),
                boxShadow: [
                  BoxShadow(color: meta.darkColor.withAlpha(px.isDark ? 20 : 40), offset: const Offset(0, 4), blurRadius: 0),
                  BoxShadow(color: px.shadow.withAlpha(20), offset: const Offset(0, 8), blurRadius: 12),
                ],
              ),
              child: _buildTask(),
            ),
            const SizedBox(height: 24),
          ],
        )),
        // Alt bar
        _BottomBar(
          answered: _answered, correct: _correct, canCheck: _canCheck, completing: _completing,
          taskColor: meta.color, showCorrectAnswer: _showCorrectAnswer, wrongAttempts: _wrongAttempts,
          isLastStep: _isLastStep, answerRevealed: _answerRevealed,
          canSkip: _skipsUsed < _maxSkips, skipsRemaining: _maxSkips - _skipsUsed,
          onCheck: _checkAnswer, onRetry: _retry, onContinue: _completeLesson,
          onRevealAnswer: () { setState(() => _answerRevealed = true); },
          onSkip: () { setState(() => _skipsUsed++); _completeLesson(); },
        ),
      ]),
    );
  }

  Widget _buildError(Px px) {
    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('Ders bulunamadi', style: AppTypography.titleMedium),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Geri', onPressed: () => Navigator.of(context).maybePop(), height: 48, depth: 6, expand: false),
      ]))),
    );
  }

  Widget _buildTask() {
    final c = _stepData;
    switch (_lesson!.taskType) {
      case 'matching':
        final raw = (c['pairs'] as List?) ?? [];
        final pairs = raw.map((e) => Map<String, String>.from(e as Map)).toList();
        return MatchingTask(key: _matchingKey, pairs: pairs, answered: _answered, showCorrectAnswer: _showCorrectAnswer, onComplete: (_) {}, onChanged: _onTaskChanged);
      case 'order_steps':
        final steps = (c['steps'] as List?)?.cast<String>() ?? [];
        final order = ((c['correct_order'] as List?) ?? []).map((e) => (e as num).toInt()).toList();
        final safeOrder = order.isEmpty ? List.generate(steps.length, (i) => i) : order;
        return OrderStepsTask(key: _orderKey, instruction: (c['instruction'] as String?) ?? 'Dogru siraya koy', steps: steps, correctOrder: safeOrder, answered: _answered, showCorrectAnswer: _showCorrectAnswer, onChanged: _onTaskChanged);
      case 'fill_blank':
        return FillBlankTask(key: _fillKey, sentence: (c['sentence'] as String?) ?? '', answer: (c['answer'] as String?) ?? '', options: (c['options'] as List?)?.cast<String>() ?? [], answered: _answered, correct: _correct, showCorrectAnswer: _showCorrectAnswer, onChanged: _onTaskChanged);
      case 'tap_select':
        return TapSelectTask(key: _tapKey, question: (c['question'] as String?) ?? '', options: (c['options'] as List?)?.cast<String>() ?? [], correctIndex: (c['correct_index'] as num?)?.toInt() ?? 0, answered: _answered, showCorrectAnswer: _showCorrectAnswer, onChanged: _onTaskChanged);
      case 'spot_error':
        return SpotErrorTask(key: _spotKey, sentence: (c['sentence'] as String?) ?? '', errorWord: (c['error_word'] as String?) ?? '', correction: (c['correction'] as String?) ?? '', answered: _answered, correct: _correct, showCorrectAnswer: _showCorrectAnswer, choices: (c['choices'] as List?)?.cast<String>(), onChanged: _onTaskChanged);
      case 'image_select':
        return ImageSelectTask(
          key: _imageKey,
          question: (c['question'] as String?) ?? 'Dogru resmi sec',
          images: (c['images'] as List?)?.cast<String>() ?? [],
          labels: (c['labels'] as List?)?.cast<String>() ?? [],
          correctIndex: (c['correct_index'] as num?)?.toInt() ?? 0,
          answered: _answered,
          showCorrectAnswer: _showCorrectAnswer,
          onChanged: _onTaskChanged,
        );
      case 'translate_sentence':
        return TranslateSentenceTask(
          key: _translateKey,
          sourceSentence: (c['source_sentence'] as String?) ?? '',
          correctTranslation: (c['correct_translation'] as String?) ?? '',
          wordChips: (c['word_chips'] as List?)?.cast<String>() ?? [],
          answered: _answered,
          onChanged: _onTaskChanged,
          langCode: (c['lang_code'] as String?) ?? 'en-US',
          instruction: (c['instruction'] as String?) ?? 'Asagidaki cumleyi cevir',
          stepIndex: _currentStep,
        );
      case 'speak_word':
        return SpeakWordTask(
          key: _speakKey,
          nativeWord: (c['native_word'] as String?) ?? '',
          targetWord: (c['target_word'] as String?) ?? '',
          answered: _answered,
          showCorrectAnswer: _showCorrectAnswer,
          onChanged: _onTaskChanged,
          langCode: (c['lang_code'] as String?) ?? 'en-US',
          stepIndex: _currentStep,
        );
      default:
        return Center(child: Text('Bilinmeyen gorev tipi: ${_lesson!.taskType}'));
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  TOP BAR — progress + adim sayaci + pixel art
// ═══════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.lesson, required this.unitIndex, required this.meta, required this.currentStep, required this.totalSteps, required this.correctCount, required this.livesRemaining, this.onClose});
  final LearningLessonModel lesson;
  final int unitIndex;
  final TaskMeta meta;
  final int currentStep, totalSteps, correctCount, livesRemaining;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: px.card,
        border: Border(bottom: BorderSide(color: px.border, width: 2)),
        boxShadow: [BoxShadow(color: px.shadow, blurRadius: 0, offset: const Offset(0, 3))],
      ),
      child: SafeArea(bottom: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Ust satir: kapat + baslik + badge
        Row(children: [
          GestureDetector(
            onTap: onClose ?? () { Haptic.light(); Navigator.of(context).maybePop(); },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
              child: Icon(Icons.close_rounded, size: 18, color: px.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(lesson.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Unite $unitIndex  •  ${meta.label}', style: TextStyle(color: px.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: px.heroDeco(meta.color, meta.darkColor, depth: 3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(meta.icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text('${currentStep + 1}/$totalSteps', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        Row(children: List.generate(totalSteps, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: done ? PxDecor.green : active ? meta.color : px.surface,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: done ? PxDecor.greenDark : active ? meta.darkColor : px.border, width: 1),
            ),
          ));
        })),
        const SizedBox(height: 8),
        // Hearts — prominent center row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: livesRemaining <= 1 ? PxDecor.red.withAlpha(px.isDark ? 30 : 20) : px.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: livesRemaining <= 1 ? PxDecor.red.withAlpha(80) : px.border, width: 2),
            boxShadow: [BoxShadow(color: livesRemaining <= 1 ? PxDecor.redDark.withAlpha(40) : px.shadow, offset: const Offset(0, 2), blurRadius: 0)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_rounded, color: livesRemaining <= 1 ? PxDecor.red : px.textSub, size: 14),
            const SizedBox(width: 6),
            ...List.generate(3, (i) {
              final alive = i < livesRemaining;
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: AnimatedScale(
                  scale: alive ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  child: alive
                      ? Stack(clipBehavior: Clip.none, children: [
                          Positioned(left: 1, top: 2, child: Icon(Icons.favorite_rounded, color: PxDecor.redDark, size: 22)),
                          const Icon(Icons.favorite_rounded, color: PxDecor.red, size: 22),
                          Positioned(left: 4, top: 3, child: Icon(Icons.favorite_rounded, color: Colors.white.withAlpha(80), size: 8)),
                        ])
                      : Icon(Icons.favorite_border_rounded, color: px.border, size: 22),
                ),
              );
            }),
            const SizedBox(width: 6),
            Text('$livesRemaining', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: livesRemaining <= 1 ? PxDecor.red : px.textSub)),
          ]),
        ),
      ])),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM BAR — feedback + kontrol/devam butonu
// ═══════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.answered, required this.correct, required this.canCheck,
    required this.completing, required this.taskColor, required this.showCorrectAnswer,
    required this.wrongAttempts, required this.isLastStep, required this.answerRevealed,
    required this.canSkip, required this.skipsRemaining,
    required this.onCheck, required this.onRetry, required this.onContinue,
    required this.onRevealAnswer, required this.onSkip,
  });

  final bool answered, correct, canCheck, completing, showCorrectAnswer, isLastStep, answerRevealed, canSkip;
  final int wrongAttempts, skipsRemaining;
  final Color taskColor;
  final VoidCallback onCheck, onRetry, onRevealAnswer, onSkip;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    // Yanlis + cevap acildi = turuncu bilgi, yanlis + acilmadi = kirmizi
    final isWrongRevealed = answered && !correct && answerRevealed;

    final feedColor = correct ? PxDecor.green : isWrongRevealed ? PxDecor.orange : PxDecor.red;
    final feedDark = correct ? PxDecor.greenDark : isWrongRevealed ? PxDecor.orangeDark : PxDecor.redDark;
    final feedBg = correct
        ? (px.isDark ? PxDecor.green.withAlpha(25) : PxDecor.greenBg)
        : isWrongRevealed
            ? (px.isDark ? PxDecor.orange.withAlpha(25) : PxDecor.orangeBg)
            : (px.isDark ? PxDecor.red.withAlpha(25) : PxDecor.redBg);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: answered ? feedBg.withAlpha(px.isDark ? 60 : 120) : px.card,
        border: Border(top: BorderSide(color: answered ? feedColor.withAlpha(60) : px.border, width: 2)),
        boxShadow: [BoxShadow(color: px.shadow.withAlpha(40), offset: const Offset(0, -2), blurRadius: 0)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (answered) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: feedBg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: feedColor, width: 2),
              boxShadow: [BoxShadow(color: feedDark.withAlpha(60), offset: const Offset(0, 3), blurRadius: 0)],
            ),
            child: Row(children: [
              Icon(correct ? Icons.check_circle_rounded : isWrongRevealed ? Icons.info_rounded : Icons.cancel_rounded, color: feedColor, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(
                correct ? 'Harika! Dogru cevap!' : isWrongRevealed ? 'Dogru cevabi incele, sonra tekrar dene.' : 'Yanlis! Tekrar dene.',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: feedDark),
              )),
            ]),
          ),
        ),
        // Buton alani
        SizedBox(width: double.infinity, child: _buildButtons(px)),
      ]),
    );
  }

  Widget _buildButtons(Px px) {
    if (!answered) {
      return PrimaryButton(label: 'Kontrol et', icon: Icons.check_rounded, onPressed: canCheck ? onCheck : null, height: 54, depth: 6, color: taskColor);
    }
    // Dogru cevap
    if (correct) {
      final label = isLastStep ? 'Dersi Tamamla' : 'Sonraki Adim';
      return PrimaryButton(label: label, icon: Icons.arrow_forward_rounded, onPressed: completing ? null : onContinue, isLoading: completing, height: 54, depth: 6, color: PxDecor.green);
    }
    // Yanlis — her zaman "Tekrar dene" goster
    // Cevap acilmissa: tekrar dene + atla (sinirli)
    // Cevap acilmamissa: tekrar dene + cevaba bak
    return Column(children: [
      PrimaryButton(label: 'Tekrar dene', icon: Icons.refresh_rounded, onPressed: onRetry, height: 54, depth: 6, color: PxDecor.orange),
      const SizedBox(height: 8),
      if (!answerRevealed && wrongAttempts >= 1)
        _buildSecondaryButton(px, icon: Icons.visibility_rounded, label: 'Cevaba bak', onTap: onRevealAnswer)
      else if (answerRevealed && canSkip)
        _buildSecondaryButton(px, icon: Icons.skip_next_rounded, label: 'Atla ($skipsRemaining kaldi)', onTap: onSkip),
    ]);
  }

  Widget _buildSecondaryButton(Px px, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () { Haptic.light(); onTap(); },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: px.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: px.border, width: 2),
        ),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: px.textMuted, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.textMuted)),
        ])),
      ),
    );
  }
}
