import 'dart:math';

import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

class SpotErrorTask extends StatefulWidget {
  const SpotErrorTask({super.key, required this.sentence, required this.errorWord, required this.correction, required this.answered, required this.correct, this.showCorrectAnswer = false, this.choices, this.onChanged});
  final String sentence;
  final String errorWord;
  final String correction;
  final bool answered;
  final bool correct;
  final bool showCorrectAnswer;
  final List<String>? choices;
  final VoidCallback? onChanged;
  @override
  State<SpotErrorTask> createState() => SpotErrorTaskState();
}

class SpotErrorTaskState extends State<SpotErrorTask> {
  String? _selected;
  late List<String> _choices;
  bool get isReady => _selected != null;

  /// Normalize: strip punctuation, lowercase, trim
  static String _norm(String w) => w.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '').trim().toLowerCase();

  bool checkAnswer() {
    if (_selected == null) return false;
    return _norm(_selected!) == _norm(widget.errorWord);
  }

  void reset() { setState(() => _selected = null); widget.onChanged?.call(); }

  /// Build 4 choices: 1 error + 3 correct words from the sentence
  List<String> _buildChoices() {
    // Use AI-provided choices if available
    if (widget.choices != null && widget.choices!.length >= 4) {
      return List<String>.from(widget.choices!);
    }
    // Auto-generate: pick 3 random non-error words + the error word
    final words = widget.sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && _norm(w) != _norm(widget.errorWord)).toList();
    words.shuffle(Random());
    final picks = words.take(3).toList();
    picks.add(widget.errorWord);
    picks.shuffle(Random());
    return picks;
  }

  @override
  void initState() {
    super.initState();
    _choices = _buildChoices();
  }

  @override
  void didUpdateWidget(covariant SpotErrorTask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentence != widget.sentence || oldWidget.errorWord != widget.errorWord) {
      _choices = _buildChoices();
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final canReveal = widget.correct || widget.showCorrectAnswer;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Baslik
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.gold), borderColor: PxDecor.gold, depth: 3),
        child: Row(children: [
          const Icon(Icons.find_replace_rounded, color: PxDecor.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Hatali kelimeyi bul', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: px.isDark ? PxDecor.gold : PxDecor.goldDark))),
        ]),
      ),
      const SizedBox(height: 12),

      // Cumle — tam metin olarak goster
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: px.cardDeco(depth: 3),
        child: Text(widget.sentence, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: px.text, height: 1.5)),
      ),
      const SizedBox(height: 14),

      // 4 secenekli kutucuklar
      ...List.generate(_choices.length, (i) {
        final w = _choices[i];
        final sel = _selected == w;
        final isErr = widget.answered && _norm(w) == _norm(widget.errorWord);
        final isBad = widget.answered && sel && _norm(w) != _norm(widget.errorWord);

        BoxDecoration dec;
        if (isErr && canReveal) {
          dec = px.correctDeco(depth: 3);
        } else if (isBad) {
          dec = px.wrongDeco(depth: 3);
        } else if (sel) {
          dec = px.selectedDeco(color: PxDecor.gold, depth: 3);
        } else {
          dec = px.cardDeco(depth: 3);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: widget.answered ? null : () { Haptic.selection(); setState(() => _selected = w); widget.onChanged?.call(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: dec,
              child: Text(w, style: TextStyle(
                fontWeight: sel || (isErr && canReveal) || isBad ? FontWeight.w900 : FontWeight.w700, fontSize: 16,
                color: (isErr && canReveal) ? PxDecor.greenDark : isBad ? PxDecor.redDark : sel ? PxDecor.goldDark : px.text,
              )),
            ),
          ),
        );
      }),

      // Duzeltme bilgisi
      if (widget.answered && canReveal) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.correct ? px.correctDeco(depth: 3) : px.cardDeco(bg: px.accentBg(PxDecor.gold), borderColor: PxDecor.gold, depth: 3),
          child: Row(children: [
            Icon(widget.correct ? Icons.auto_fix_high_rounded : Icons.lightbulb_rounded, color: widget.correct ? PxDecor.green : PxDecor.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(child: RichText(text: TextSpan(
              style: TextStyle(color: px.text, fontSize: 14),
              children: [
                TextSpan(text: '"${widget.errorWord}"', style: const TextStyle(decoration: TextDecoration.lineThrough, color: PxDecor.red, fontWeight: FontWeight.w700)),
                const TextSpan(text: '  →  '),
                TextSpan(text: '"${widget.correction}"', style: const TextStyle(fontWeight: FontWeight.w900, color: PxDecor.greenDark)),
              ],
            ))),
          ]),
        ),
      ],
    ]);
  }
}
