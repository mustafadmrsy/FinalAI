import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/ui/app_assets.dart';
import '../../data/placement_questions.dart';

class PlacementStep extends StatefulWidget {
  const PlacementStep({
    super.key,
    required this.subject,
    required this.onPlacementDone,
    required this.onGoBack,
    this.goal,
    this.dailyMinutes,
  });

  final String subject;
  final String? goal;
  final int? dailyMinutes;
  final ValueChanged<Map<String, dynamic>> onPlacementDone;
  final VoidCallback onGoBack;

  @override
  State<PlacementStep> createState() => _PlacementStepState();
}

class _PlacementStepState extends State<PlacementStep> with TickerProviderStateMixin {
  int _currentQ = 0;
  int _totalSeconds = 180;
  Timer? _timer;
  bool _answered = false;
  int? _selectedOption;
  List<Map<String, dynamic>> _questions = [];
  bool _loadingQuestions = true;
  // Track answers per question for back navigation
  final Map<int, int?> _userAnswers = {};
  final Map<int, bool> _wasCorrect = {};

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  static const String _aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://finalai-zpza.onrender.com',
  );

  Future<void> _generateQuestions() async {
    try {
      debugPrint('[PlacementStep] Generating AI questions via Claude for: ${widget.subject}');
      debugPrint('[PlacementStep] Backend URL: $_aiBaseUrl');

      final uri = Uri.parse('$_aiBaseUrl/ai/placement-questions');
      final client = HttpClient();
      try {
        final req = await client.postUrl(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Backend bağlantı timeout'),
        );
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode({
          'subject': widget.subject,
          'goal': widget.goal,
          'dailyMinutes': widget.dailyMinutes,
        })));

        final res = await req.close().timeout(const Duration(seconds: 60));
        final resBody = await res.transform(utf8.decoder).join();

        debugPrint('[PlacementStep] Backend status: ${res.statusCode}');

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(resBody) as Map<String, dynamic>;
          final questions = decoded['questions'] as List?;

          if (questions != null && questions.length >= 4) {
            final valid = questions.where((q) {
              if (q is! Map) return false;
              return q['q'] is String &&
                  q['options'] is List &&
                  (q['options'] as List).length == 4 &&
                  q['answer'] is int &&
                  (q['answer'] as int) >= 0 &&
                  (q['answer'] as int) <= 3;
            }).map((q) => (q as Map).cast<String, dynamic>()).toList();

            debugPrint('[PlacementStep] Valid questions: ${valid.length}');

            if (valid.length >= 4) {
              if (mounted) setState(() { _questions = valid; _loadingQuestions = false; });
              _startTimer();
              return;
            }
          }
        } else {
          debugPrint('[PlacementStep] Backend error: $resBody');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[PlacementStep] AI error: $e');
    }

    // Fallback
    debugPrint('[PlacementStep] Using static fallback questions');
    if (mounted) {
      setState(() {
        _questions = PlacementQuestions.forSubject(widget.subject);
        _loadingQuestions = false;
      });
      _startTimer();
    }
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
    final correctAnswer = _questions[_currentQ]['answer'] as int;
    final isCorrect = idx == correctAnswer;
    setState(() {
      _selectedOption = idx;
      _answered = true;
      _userAnswers[_currentQ] = idx;
      _wasCorrect[_currentQ] = isCorrect;
    });
    // Auto-advance after brief feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_currentQ < _questions.length - 1) {
        _goToQuestion(_currentQ + 1);
      } else {
        _finish();
      }
    });
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() {
      _currentQ = index;
      _selectedOption = _userAnswers[index];
      _answered = _userAnswers.containsKey(index);
    });
  }

  void _skipQuestion() {
    if (_currentQ < _questions.length - 1) {
      _goToQuestion(_currentQ + 1);
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    // Recalculate correct from tracked answers
    int correct = 0;
    for (final entry in _wasCorrect.entries) {
      if (entry.value) correct++;
    }
    final answered = _wasCorrect.length;
    final total = _questions.length;
    final score = answered > 0 ? (correct / total * 100).round() : 0;
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
      'correct': correct,
      'total': total,
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

    if (_loadingQuestions) return _buildLoading(theme);
    if (_questions.isEmpty) return _buildLoading(theme);

    final q = _questions[_currentQ];
    final rawOptions = q['options'] as List;
    final options = rawOptions.map((e) => e.toString()).toList();
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
            // Timer badge
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
        // Progress bar
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
        // Question counter + question dots
        Row(
          children: [
            // Question dot indicators
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(_questions.length, (i) {
                  final answered = _userAnswers.containsKey(i);
                  final isCurrent = i == _currentQ;
                  Color dotColor;
                  if (isCurrent) {
                    dotColor = AppColors.primary;
                  } else if (answered && (_wasCorrect[i] ?? false)) {
                    dotColor = AppColors.success;
                  } else if (answered) {
                    dotColor = AppColors.error;
                  } else {
                    dotColor = theme.dividerColor;
                  }
                  return GestureDetector(
                    onTap: () => _goToQuestion(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isCurrent ? 24 : 16,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Text(
              '${_currentQ + 1} / ${_questions.length}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Question card
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
        const SizedBox(height: 16),
        // Option cards
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
              onTap: _answered ? null : () => _selectOption(i),
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
        const SizedBox(height: 12),
        // Navigation row: Back / Skip / Finish
        Row(
          children: [
            // Geri button
            GestureDetector(
              onTap: _currentQ > 0
                  ? () => _goToQuestion(_currentQ - 1)
                  : widget.onGoBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withAlpha(80), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _currentQ > 0 ? 'Onceki' : 'Geri',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            // Skip / Next / Finish
            if (!_answered)
              GestureDetector(
                onTap: _skipQuestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(60), width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _currentQ < _questions.length - 1 ? 'Atla' : 'Bitir',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                  ]),
                ),
              ),
            if (_answered && _currentQ < _questions.length - 1)
              GestureDetector(
                onTap: () => _goToQuestion(_currentQ + 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(60), width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Sonraki', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                  ]),
                ),
              ),
            if (_answered && _currentQ == _questions.length - 1)
              GestureDetector(
                onTap: _finish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF078F8D)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Testi Bitir', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  ]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Mascot riding bike animation
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset(
              AppAssets.mascotCuteCupBike,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 20),
          // Logo
          Image.asset(
            'assets/logo/logo.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Sorular hazirlaniyor...',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '"${widget.subject}" icin kisisel seviye testi olusturuluyor',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('AI ile uretiliyor', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 20),
          // Back button during loading
          GestureDetector(
            onTap: widget.onGoBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withAlpha(80), width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Geri Don', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
