import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../data/placement_questions.dart';

class PlacementStep extends StatefulWidget {
  const PlacementStep({
    super.key,
    required this.subject,
    required this.onPlacementDone,
  });

  final String subject;
  final ValueChanged<Map<String, dynamic>> onPlacementDone;

  @override
  State<PlacementStep> createState() => _PlacementStepState();
}

class _PlacementStepState extends State<PlacementStep> with TickerProviderStateMixin {
  int _currentQ = 0;
  int _correct = 0;
  int _totalSeconds = 180;
  Timer? _timer;
  bool _answered = false;
  int? _selectedOption;
  late final List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = PlacementQuestions.forSubject(widget.subject);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_totalSeconds <= 0) {
        t.cancel();
        _finish();
        return;
      }
      if (mounted) setState(() => _totalSeconds--);
    });
  }

  void _selectOption(int idx) {
    if (_answered) return;
    setState(() {
      _selectedOption = idx;
      _answered = true;
      if (idx == _questions[_currentQ]['answer']) _correct++;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_currentQ < _questions.length - 1) {
        setState(() {
          _currentQ++;
          _answered = false;
          _selectedOption = null;
        });
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    final score = (_correct / _questions.length * 100).round();
    String level;
    if (score >= 80) {
      level = 'Ileri';
    } else if (score >= 50) {
      level = 'Orta';
    } else {
      level = 'Baslangic';
    }
    widget.onPlacementDone({
      'score': score,
      'correct': _correct,
      'total': _questions.length,
      'level': level,
      'timeSpent': 180 - _totalSeconds,
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _questions[_currentQ];
    final options = q['options'] as List<String>;
    final correctIdx = q['answer'] as int;
    final mins = _totalSeconds ~/ 60;
    final secs = _totalSeconds % 60;
    final progress = (_currentQ + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Header row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seviye Testi', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(widget.subject, style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            // 3D timer badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _totalSeconds < 30 ? AppColors.error.withAlpha(15) : AppColors.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _totalSeconds < 30 ? AppColors.error.withAlpha(120) : AppColors.primary.withAlpha(80), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (_totalSeconds < 30 ? AppColors.error : AppColors.primary).withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded, size: 18, color: _totalSeconds < 30 ? AppColors.error : AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$mins:${secs.toString().padLeft(2, '0')}',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: _totalSeconds < 30 ? AppColors.error : AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar with 3D effect
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: theme.dividerColor.withAlpha(60),
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF078F8D)]),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 6, offset: const Offset(0, 2))],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Soru ${_currentQ + 1} / ${_questions.length}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 20),
        // 3D Question card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withAlpha(10), AppColors.primary.withAlpha(5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withAlpha(40), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: AppColors.primary.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (q['difficulty'] as String?) == 'hard' ? 'Zor' : (q['difficulty'] as String?) == 'medium' ? 'Orta' : 'Kolay',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                q['q'] as String,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 3D option cards
        ...List.generate(options.length, (i) {
          final isSelected = _selectedOption == i;
          final isCorrect = i == correctIdx;

          Color borderColor = theme.dividerColor.withAlpha(80);
          Color bgColor = theme.colorScheme.surface;
          Color shadowColor = Colors.black.withAlpha(6);

          if (_answered && isSelected) {
            borderColor = isCorrect ? AppColors.success : AppColors.error;
            bgColor = (isCorrect ? AppColors.success : AppColors.error).withAlpha(15);
            shadowColor = (isCorrect ? AppColors.success : AppColors.error).withAlpha(30);
          } else if (_answered && isCorrect) {
            borderColor = AppColors.success.withAlpha(120);
            bgColor = AppColors.success.withAlpha(10);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _selectOption(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: _answered && (isSelected || isCorrect) ? 2.5 : 1.5),
                  boxShadow: [
                    BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // 3D letter badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: _answered && isSelected
                            ? LinearGradient(colors: isCorrect ? [AppColors.success, AppColors.successDark] : [AppColors.error, AppColors.error])
                            : LinearGradient(colors: [AppColors.primary.withAlpha(20), AppColors.primary.withAlpha(10)]),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: (_answered && isSelected ? (isCorrect ? AppColors.success : AppColors.error) : AppColors.primary).withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _answered && isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        options[i],
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_answered && isSelected)
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? AppColors.success : AppColors.error,
                        size: 24,
                      ),
                    if (_answered && !isSelected && isCorrect)
                      Icon(Icons.check_circle_outlined, color: AppColors.success.withAlpha(160), size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
