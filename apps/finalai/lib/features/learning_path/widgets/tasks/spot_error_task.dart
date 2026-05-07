import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

class SpotErrorTask extends StatefulWidget {
  const SpotErrorTask({super.key, required this.sentence, required this.errorWord, required this.correction, required this.answered, required this.correct, this.showCorrectAnswer = false, this.onChanged});
  final String sentence;
  final String errorWord;
  final String correction;
  final bool answered;
  final bool correct;
  final bool showCorrectAnswer;
  final VoidCallback? onChanged;
  @override
  State<SpotErrorTask> createState() => SpotErrorTaskState();
}

class SpotErrorTaskState extends State<SpotErrorTask> {
  String? _selected;
  bool get isReady => _selected != null;

  /// Normalize: strip punctuation, lowercase, trim
  static String _norm(String w) => w.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '').trim().toLowerCase();

  bool checkAnswer() {
    if (_selected == null) return false;
    return _norm(_selected!) == _norm(widget.errorWord);
  }

  void reset() { setState(() => _selected = null); widget.onChanged?.call(); }

  /// Split sentence keeping multi-word errorWord as a single tappable token
  List<String> _splitSentence() {
    final sentence = widget.sentence;
    final err = widget.errorWord.trim();

    // Multi-word error: find it in sentence and keep as one token
    if (err.contains(' ')) {
      final lowerSentence = sentence.toLowerCase();
      final lowerErr = err.toLowerCase();
      final idx = lowerSentence.indexOf(lowerErr);
      if (idx >= 0) {
        final before = sentence.substring(0, idx).trim();
        final errorInSentence = sentence.substring(idx, idx + err.length);
        final after = sentence.substring(idx + err.length).trim();
        final words = <String>[];
        if (before.isNotEmpty) words.addAll(before.split(RegExp(r'\s+')));
        words.add(errorInSentence);
        if (after.isNotEmpty) words.addAll(after.split(RegExp(r'\s+')));
        return words.where((w) => w.isNotEmpty).toList();
      }
    }

    return sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final words = _splitSentence();
    final canReveal = widget.correct || widget.showCorrectAnswer;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Baslik
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.gold), borderColor: PxDecor.gold, depth: 3),
        child: Row(children: [
          const Icon(Icons.find_replace_rounded, color: PxDecor.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Cumlede hatali kelimeye dokun', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: px.isDark ? PxDecor.gold : PxDecor.goldDark))),
        ]),
      ),
      const SizedBox(height: 16),

      // Kelime kartlari
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: px.cardDeco(depth: 4),
        child: Wrap(spacing: 6, runSpacing: 8, children: words.map((w) {
          final sel = _selected == w;
          final isErr = widget.answered && _norm(w) == _norm(widget.errorWord);
          final isBad = widget.answered && sel && _norm(w) != _norm(widget.errorWord);

          BoxDecoration dec;
          if (isErr && canReveal) {
            dec = px.selectedDeco(color: PxDecor.green, depth: 2);
          } else if (isBad) {
            dec = px.wrongDeco(depth: 2);
          } else if (sel) {
            dec = px.selectedDeco(color: PxDecor.gold, depth: 2);
          } else {
            dec = px.cardDeco(depth: 2);
          }

          return GestureDetector(
            onTap: widget.answered ? null : () { Haptic.selection(); setState(() => _selected = w); widget.onChanged?.call(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: dec,
              child: Text(w, style: TextStyle(
                fontWeight: sel || (isErr && canReveal) || isBad ? FontWeight.w900 : FontWeight.w700, fontSize: 15,
                color: (isErr && canReveal) ? PxDecor.greenDark : isBad ? PxDecor.redDark : sel ? PxDecor.goldDark : px.text,
                decoration: (isErr && canReveal) ? TextDecoration.lineThrough : null,
              )),
            ),
          );
        }).toList()),
      ),

      // Duzeltme bilgisi — sadece dogru cevap veya 2 yanlis sonrasi goster
      if (widget.answered && canReveal) ...[
        const SizedBox(height: 12),
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
