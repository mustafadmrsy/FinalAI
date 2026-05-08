import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/tts_service.dart';

// ═══════════════════════════════════════════════════════════════
//  TRANSLATE SENTENCE TASK — Duolingo-style word chip translation
//  Karakter konuşma balonunda cümle söyler, kullanıcı kelime
//  chip'leri ile çeviriyi oluşturur.
// ═══════════════════════════════════════════════════════════════

class TranslateSentenceTask extends StatefulWidget {
  const TranslateSentenceTask({
    super.key,
    required this.sourceSentence,
    required this.correctTranslation,
    required this.wordChips,
    required this.answered,
    required this.onChanged,
    this.langCode = 'en-US',
    this.instruction = 'Asagidaki cumleyi cevir',
    this.stepIndex = 0,
  });

  final String sourceSentence;
  final String correctTranslation;
  final List<String> wordChips;
  final bool answered;
  final VoidCallback onChanged;
  final String langCode;
  final String instruction;
  final int stepIndex;

  @override
  State<TranslateSentenceTask> createState() => TranslateSentenceTaskState();
}

class TranslateSentenceTaskState extends State<TranslateSentenceTask> {
  final List<String> _selectedWords = [];
  final List<int> _selectedIndices = [];

  bool get isReady => _selectedWords.isNotEmpty;

  bool checkAnswer() {
    if (_selectedWords.isEmpty || widget.correctTranslation.trim().isEmpty) return false;
    final userAnswer = _selectedWords.join(' ').trim().toLowerCase();
    final correct = widget.correctTranslation.trim().toLowerCase();
    return userAnswer == correct;
  }

  void reset() {
    setState(() {
      _selectedWords.clear();
      _selectedIndices.clear();
    });
    widget.onChanged();
  }

  void _addWord(int index) {
    if (widget.answered || _selectedIndices.contains(index)) return;
    Haptic.selection();
    setState(() {
      _selectedWords.add(widget.wordChips[index]);
      _selectedIndices.add(index);
    });
    widget.onChanged();
  }

  void _removeWord(int tapIndex) {
    if (widget.answered) return;
    Haptic.light();
    setState(() {
      final originalIndex = _selectedIndices[tapIndex];
      _selectedWords.removeAt(tapIndex);
      _selectedIndices.removeAt(tapIndex);
      // ignore: unused_local_variable
      final _ = originalIndex;
    });
    widget.onChanged();
  }

  LessonAvatar get _avatar => LessonAvatar.forStep(widget.stepIndex);

  void _playAudio() {
    TtsService.instance.speakAsAvatar(widget.sourceSentence, widget.langCode, _avatar);
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final avatar = _avatar;
    final isCorrect = widget.answered && checkAnswer();
    final isWrong = widget.answered && !checkAnswer();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Instruction
      Text(
        widget.instruction,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: px.text),
      ),
      const SizedBox(height: 16),

      // Character + Speech bubble
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: PxDecor.teal.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PxDecor.teal, width: 2),
            boxShadow: [BoxShadow(color: PxDecor.tealDark.withAlpha(60), offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Center(
            child: Text(avatar.emoji, style: const TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(width: 12),
        // Speech bubble
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: px.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: px.border, width: 2),
              boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
            ),
            child: Row(children: [
              // Speaker button
              GestureDetector(
                onTap: _playAudio,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: PxDecor.blue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(80), offset: const Offset(0, 2), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.sourceSentence,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: px.text, height: 1.4),
                ),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 20),

      // Answer area — lines where tapped words appear
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCorrect
              ? px.accentBg(PxDecor.green)
              : isWrong
                  ? px.accentBg(PxDecor.red)
                  : px.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCorrect ? PxDecor.green : isWrong ? PxDecor.red : px.border,
            width: 2,
          ),
        ),
        child: _selectedWords.isEmpty
            ? Center(
                child: Text(
                  '...',
                  style: TextStyle(fontSize: 18, color: px.textMuted, fontWeight: FontWeight.w600),
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_selectedWords.length, (i) {
                  return GestureDetector(
                    onTap: () => _removeWord(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: px.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: px.border, width: 1.5),
                        boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 2), blurRadius: 0)],
                      ),
                      child: Text(
                        _selectedWords[i],
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: px.text),
                      ),
                    ),
                  );
                }),
              ),
      ),

      // Correct answer display when wrong
      if (isWrong) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: px.accentBg(PxDecor.green),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PxDecor.green, width: 2),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dogru cevap: ${widget.correctTranslation}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: PxDecor.green),
              ),
            ),
          ]),
        ),
      ],

      // Divider lines
      const SizedBox(height: 4),
      Container(height: 2, color: px.border.withAlpha(80)),
      const SizedBox(height: 20),

      // Word chips (bottom)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(widget.wordChips.length, (i) {
          final isUsed = _selectedIndices.contains(i);
          return GestureDetector(
            onTap: isUsed ? null : () => _addWord(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUsed ? px.surface : px.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUsed ? px.border.withAlpha(60) : px.border,
                  width: 2,
                ),
                boxShadow: isUsed
                    ? []
                    : [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
              ),
              child: Text(
                widget.wordChips[i],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isUsed ? Colors.transparent : px.text,
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}
