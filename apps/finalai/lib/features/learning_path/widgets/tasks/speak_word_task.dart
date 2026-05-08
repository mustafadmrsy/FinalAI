import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/services/stt_service.dart';

// ═══════════════════════════════════════════════════════════════
//  SPEAK WORD TASK — Kullanici kelimeyi hedef dilde telaffuz eder
//  Turkce anlamini gosterir, hedef dilde TTS okur, kullanici
//  mikrofona soylediginde fuzzy-match ile dogru/yanlis kontrol eder
// ═══════════════════════════════════════════════════════════════

class SpeakWordTask extends StatefulWidget {
  const SpeakWordTask({
    super.key,
    required this.nativeWord,
    required this.targetWord,
    required this.answered,
    required this.onChanged,
    this.showCorrectAnswer = false,
    this.langCode = 'en-US',
    this.stepIndex = 0,
  });

  final String nativeWord;
  final String targetWord;
  final bool answered;
  final VoidCallback onChanged;
  final bool showCorrectAnswer;
  final String langCode;
  final int stepIndex;

  @override
  State<SpeakWordTask> createState() => SpeakWordTaskState();
}

class SpeakWordTaskState extends State<SpeakWordTask> with SingleTickerProviderStateMixin {
  String _spokenText = '';
  bool _isListening = false;
  bool _hasSpoken = false;
  bool _resultCorrect = false;
  late AnimationController _pulseCtrl;

  bool get isReady => _hasSpoken;

  bool checkAnswer() => _resultCorrect;

  void reset() {
    setState(() {
      _spokenText = '';
      _isListening = false;
      _hasSpoken = false;
      _resultCorrect = false;
    });
    widget.onChanged();
  }

  LessonAvatar get _avatar => LessonAvatar.forStep(widget.stepIndex);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Auto-play on first load
    Future.delayed(const Duration(milliseconds: 400), _playTargetWord);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SttService.instance.stop();
    super.dispose();
  }

  void _playTargetWord() {
    TtsService.instance.speakAsAvatar(widget.targetWord, widget.langCode, _avatar);
  }

  Future<void> _startListening() async {
    if (widget.answered || _isListening || _hasSpoken) return;
    Haptic.medium();
    setState(() {
      _isListening = true;
      _spokenText = '';
    });
    _pulseCtrl.repeat(reverse: true);

    await SttService.instance.listen(
      langCode: widget.langCode,
      onResult: (text, isFinal) {
        if (!mounted || !_isListening) return;
        setState(() {
          _spokenText = text;
        });
        // Partial result yeterince iyiyse aninda kabul et
        if (text.trim().isNotEmpty && SttService.isCloseEnough(text, widget.targetWord)) {
          _finishListening();
          return;
        }
        if (isFinal) {
          _finishListening();
        }
      },
      listenFor: const Duration(seconds: 10),
    );

    // Safety timeout
    Future.delayed(const Duration(seconds: 11), () {
      if (mounted && _isListening) _finishListening();
    });
  }

  void _finishListening() {
    if (!_isListening) return; // Tekrar cagirmayi engelle
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    SttService.instance.stop();
    final isCorrect = SttService.isCloseEnough(_spokenText, widget.targetWord);
    setState(() {
      _isListening = false;
      _hasSpoken = true;
      _resultCorrect = isCorrect;
    });
    if (isCorrect) {
      Haptic.heavy();
    } else {
      Haptic.vibrate();
    }
    widget.onChanged();
  }

  void _skip() {
    // Kullanici mikrofon calismiyorsa atlasin — dogru say
    setState(() {
      _hasSpoken = true;
      _resultCorrect = true;
      _spokenText = widget.targetWord;
    });
    Haptic.light();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final avatar = _avatar;
    final isCorrect = widget.answered && _resultCorrect;
    final isWrong = widget.answered && !_resultCorrect;

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // Instruction
      Text(
        'Bu kelimeyi soyle',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: px.text),
      ),
      const SizedBox(height: 20),

      // Avatar + target word card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: px.border, width: 2),
          boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Column(children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: PxDecor.teal.withAlpha(30),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PxDecor.teal, width: 2),
              boxShadow: [BoxShadow(color: PxDecor.tealDark.withAlpha(60), offset: const Offset(0, 3), blurRadius: 0)],
            ),
            child: Center(child: Text(avatar.emoji, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 14),

          // Native word (Turkish)
          Text(
            widget.nativeWord,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: px.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Target word (big, bold)
          Text(
            widget.targetWord,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: px.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Play button
          GestureDetector(
            onTap: _playTargetWord,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: PxDecor.blue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(80), offset: const Offset(0, 3), blurRadius: 0)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text('Dinle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),

      // Microphone button
      if (!widget.answered)
        GestureDetector(
          onTap: _isListening ? null : _startListening,
          child: AnimatedBuilder2(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = _isListening ? 1.0 + (_pulseCtrl.value * 0.15) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening ? PxDecor.red : PxDecor.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? PxDecor.red : PxDecor.green).withAlpha(80),
                        offset: const Offset(0, 4),
                        blurRadius: _isListening ? 12 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
        ),

      if (_isListening) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _spokenText.isEmpty ? 'Dinleniyor...' : '"$_spokenText"',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _spokenText.isEmpty ? PxDecor.red : px.text,
            ),
          ),
        ),
      ],

      // Skip/pass button — mikrofon calismiyorsa
      if (!widget.answered && !_hasSpoken && !_isListening)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: GestureDetector(
            onTap: _skip,
            child: Text(
              'Mikrofon calismiyor, atla',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: px.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

      // Spoken text result — sadece yanlis oldugunda soyledigini goster
      if (_hasSpoken && !_resultCorrect && _spokenText.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: px.accentBg(PxDecor.red),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PxDecor.red, width: 2),
          ),
          child: Column(children: [
            Text('Tekrar dene', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: PxDecor.red)),
            const SizedBox(height: 4),
            Text('Soyledigin: "$_spokenText"', style: TextStyle(fontSize: 14, color: px.textMuted, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],

      // Show correct answer only when user taps 'Cevaba bak'
      if (isWrong && widget.showCorrectAnswer) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: px.accentBg(PxDecor.blue),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PxDecor.blue, width: 2),
          ),
          child: Column(children: [
            Text('Dogru telaffuz:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textMuted)),
            const SizedBox(height: 4),
            Text(
              widget.targetWord,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: PxDecor.blue),
            ),
          ]),
        ),
      ],

      if (isCorrect) ...[
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 28),
          const SizedBox(width: 8),
          Text('Dogru!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: PxDecor.green)),
        ]),
      ],
    ]);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  Animation<double> get animation => listenable as Animation<double>;
  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
