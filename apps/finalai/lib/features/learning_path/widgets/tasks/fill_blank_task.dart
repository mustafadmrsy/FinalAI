import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

class FillBlankTask extends StatefulWidget {
  const FillBlankTask({super.key, required this.sentence, required this.answer, required this.options, required this.answered, required this.correct, this.onChanged});
  final String sentence;
  final String answer;
  final List<String> options;
  final bool answered;
  final bool correct;
  final VoidCallback? onChanged;
  @override
  State<FillBlankTask> createState() => FillBlankTaskState();
}

class FillBlankTaskState extends State<FillBlankTask> {
  String? _selected;
  bool get isReady => _selected != null;
  bool checkAnswer() => _selected == widget.answer;
  void reset() { setState(() => _selected = null); widget.onChanged?.call(); }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final parts = widget.sentence.split('_____');
    final hasAns = _selected != null;
    final ok = widget.answered && widget.correct;
    final bad = widget.answered && !widget.correct;

    final blankBg = hasAns ? (ok ? px.accentBg(PxDecor.green) : bad ? px.accentBg(PxDecor.red) : px.accentBg(PxDecor.blue)) : px.surface;
    final blankBorder = hasAns ? (ok ? PxDecor.green : bad ? PxDecor.red : PxDecor.blue) : px.border;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Baslik
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.purple), borderColor: PxDecor.purple, depth: 3),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: PxDecor.purple.withAlpha(40), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.text_fields_rounded, color: PxDecor.purple, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Boslugu doldur', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: px.isDark ? PxDecor.purple : PxDecor.purpleDark)),
            const SizedBox(height: 2),
            Text('Dogru kelimeyi surukle veya dokun', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textMuted)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),

      // Cumle karti — bosluk .... olarak gosterilir, DragTarget ile kelime birakilir
      DragTarget<String>(
        onAcceptWithDetails: (details) {
          if (!widget.answered) {
            setState(() => _selected = details.data);
            widget.onChanged?.call();
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isHovering ? px.accentBg(PxDecor.blue) : px.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isHovering ? PxDecor.blue : px.border, width: 2),
              boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 4), blurRadius: 0)],
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (parts.isNotEmpty) Text(parts[0], style: TextStyle(fontWeight: FontWeight.w700, color: px.text, fontSize: 16, height: 1.7)),
                // Bosluk alani
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  constraints: const BoxConstraints(minWidth: 60),
                  decoration: BoxDecoration(
                    color: blankBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: blankBorder, width: 2),
                    boxShadow: [BoxShadow(color: blankBorder.withAlpha(px.isDark ? 30 : 60), offset: const Offset(0, 2), blurRadius: 0)],
                  ),
                  child: Text(
                    hasAns ? _selected! : '........',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: hasAns ? 0 : 2,
                      color: hasAns ? (ok ? PxDecor.greenDark : bad ? PxDecor.redDark : PxDecor.blueDark) : px.textMuted,
                    ),
                  ),
                ),
                if (parts.length > 1) Text(parts[1], style: TextStyle(fontWeight: FontWeight.w700, color: px.text, fontSize: 16, height: 1.7)),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 16),

      // Secenekler — suruklenebilir, kutusuz sadece kelime
      Wrap(spacing: 10, runSpacing: 10, children: widget.options.map((opt) {
        final sel = _selected == opt;
        final isOk = widget.answered && opt == widget.answer;
        final isBad = widget.answered && sel && !widget.correct;

        Color chipColor, chipBorder;
        if (isOk) { chipColor = px.accentBg(PxDecor.green); chipBorder = PxDecor.green; }
        else if (isBad) { chipColor = px.accentBg(PxDecor.red); chipBorder = PxDecor.red; }
        else if (sel) { chipColor = px.accentBg(PxDecor.blue); chipBorder = PxDecor.blue; }
        else { chipColor = px.card; chipBorder = px.border; }

        final child = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel && !widget.answered ? Colors.transparent : chipColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel && !widget.answered ? Colors.transparent : chipBorder, width: 2),
            boxShadow: sel && !widget.answered ? [] : [BoxShadow(color: chipBorder.withAlpha(px.isDark ? 25 : 50), offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isOk) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 16)),
            if (isBad) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.cancel_rounded, color: PxDecor.red, size: 16)),
            Text(opt, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: sel && !widget.answered ? Colors.transparent : px.text)),
          ]),
        );

        if (widget.answered || (sel && !widget.answered)) return child;

        return Draggable<String>(
          data: opt,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: PxDecor.blue, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 3), blurRadius: 0)]),
              child: Text(opt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, decoration: TextDecoration.none)),
            ),
          ),
          childWhenDragging: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border.withAlpha(60), width: 2, style: BorderStyle.solid)),
            child: Text(opt, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: px.textMuted)),
          ),
          onDragStarted: () {},
          child: GestureDetector(
            onTap: () { if (!widget.answered) { Haptic.selection(); setState(() => _selected = opt); widget.onChanged?.call(); } },
            child: child,
          ),
        );
      }).toList()),
    ]);
  }
}
