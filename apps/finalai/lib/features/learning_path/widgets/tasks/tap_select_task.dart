import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

class TapSelectTask extends StatefulWidget {
  const TapSelectTask({super.key, required this.question, required this.options, required this.correctIndex, required this.answered, this.onChanged});
  final String question;
  final List<String> options;
  final int correctIndex;
  final bool answered;
  final VoidCallback? onChanged;
  @override
  State<TapSelectTask> createState() => TapSelectTaskState();
}

class TapSelectTaskState extends State<TapSelectTask> {
  int? _selected;
  bool get isReady => _selected != null;
  bool checkAnswer() => _selected == widget.correctIndex;
  void reset() { setState(() => _selected = null); widget.onChanged?.call(); }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Soru karti
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.green), borderColor: PxDecor.green, depth: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: PxDecor.green.withAlpha(40), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.help_outline_rounded, color: PxDecor.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.question, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: px.text, height: 1.4))),
        ]),
      ),
      const SizedBox(height: 16),

      // Secenekler
      ...List.generate(widget.options.length, (i) {
        final sel = _selected == i;
        final ok = widget.answered && i == widget.correctIndex;
        final bad = widget.answered && sel && i != widget.correctIndex;

        final dec = ok ? px.correctDeco() : bad ? px.wrongDeco() : sel ? px.selectedDeco(color: PxDecor.green) : px.cardDeco();
        final badgeColor = ok ? PxDecor.green : bad ? PxDecor.red : sel ? PxDecor.green : px.border;
        final badgeTextColor = (sel || ok || bad) ? Colors.white : px.textSub;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: widget.answered ? null : () { Haptic.selection(); setState(() => _selected = i); widget.onChanged?.call(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: dec,
              child: Row(children: [
                // Harf badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: (sel || ok || bad) ? [BoxShadow(color: badgeColor.withAlpha(60), offset: const Offset(0, 2), blurRadius: 0)] : [],
                  ),
                  child: Center(child: Text(String.fromCharCode(65 + i), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: badgeTextColor))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.options[i], style: TextStyle(fontWeight: sel || ok ? FontWeight.w800 : FontWeight.w700, fontSize: 14, color: ok ? PxDecor.greenDark : bad ? PxDecor.redDark : px.text))),
                if (ok) const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 22),
                if (bad) const Icon(Icons.cancel_rounded, color: PxDecor.red, size: 22),
              ]),
            ),
          ),
        );
      }),
    ]);
  }
}
