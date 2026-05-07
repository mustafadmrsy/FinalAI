import 'package:flutter/material.dart';
import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════
//  IMAGE SELECT TASK — Kavram kartlarini secme gorevi
//  Resim yerine renkli kavram kartlari gosterir
// ═══════════════════════════════════════════════════════════════

class ImageSelectTask extends StatefulWidget {
  const ImageSelectTask({
    super.key,
    required this.question,
    required this.images,
    required this.labels,
    required this.correctIndex,
    required this.answered,
    required this.onChanged,
  });

  final String question;
  final List<String> images;
  final List<String> labels;
  final int correctIndex;
  final bool answered;
  final VoidCallback onChanged;

  @override
  State<ImageSelectTask> createState() => ImageSelectTaskState();
}

class ImageSelectTaskState extends State<ImageSelectTask> {
  int? _selected;

  bool get isReady => _selected != null;

  bool checkAnswer() => _selected == widget.correctIndex;

  void reset() => setState(() => _selected = null);

  static const _cardColors = [PxDecor.blue, PxDecor.teal, PxDecor.purple, PxDecor.orange];
  static const _cardDarks = [PxDecor.blueDark, PxDecor.tealDark, PxDecor.purpleDark, PxDecor.orangeDark];
  static const _cardIcons = [Icons.lightbulb_rounded, Icons.auto_awesome_rounded, Icons.psychology_rounded, Icons.extension_rounded];

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Soru karti
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.orange), borderColor: PxDecor.orange, depth: 3),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: PxDecor.orange, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.question, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: px.text))),
        ]),
      ),
      const SizedBox(height: 16),

      // 2x2 Kavram kartlari
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
        children: List.generate(widget.labels.length.clamp(0, 4), (i) {
          final isSelected = _selected == i;
          final isCorrect = i == widget.correctIndex;
          final showResult = widget.answered;

          final baseColor = _cardColors[i % _cardColors.length];
          final baseDark = _cardDarks[i % _cardDarks.length];
          final icon = _cardIcons[i % _cardIcons.length];
          final label = i < widget.labels.length ? widget.labels[i] : '';

          Color borderColor;
          Color bgColor;
          Color shadowColor;
          if (showResult && isCorrect) {
            borderColor = PxDecor.green;
            bgColor = px.accentBg(PxDecor.green);
            shadowColor = PxDecor.greenDark;
          } else if (showResult && isSelected && !isCorrect) {
            borderColor = PxDecor.red;
            bgColor = px.accentBg(PxDecor.red);
            shadowColor = PxDecor.redDark;
          } else if (isSelected && !showResult) {
            borderColor = baseColor;
            bgColor = px.accentBg(baseColor);
            shadowColor = baseDark;
          } else {
            borderColor = px.border;
            bgColor = px.card;
            shadowColor = px.shadow;
          }

          return GestureDetector(
            onTap: widget.answered ? null : () {
              Haptic.selection();
              setState(() => _selected = i);
              widget.onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: isSelected || showResult ? 3 : 2),
                boxShadow: [BoxShadow(color: shadowColor.withAlpha(isSelected ? 80 : 255), offset: const Offset(0, 4), blurRadius: 0)],
              ),
              child: Column(children: [
                // Kavram ikon alani
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: showResult && isCorrect
                          ? PxDecor.green.withAlpha(25)
                          : showResult && isSelected && !isCorrect
                              ? PxDecor.red.withAlpha(25)
                              : baseColor.withAlpha(isSelected ? 30 : 15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: showResult && isCorrect ? PxDecor.green : showResult && isSelected ? PxDecor.red : baseColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: (showResult && isCorrect ? PxDecor.greenDark : showResult && isSelected ? PxDecor.redDark : baseDark).withAlpha(80),
                            offset: const Offset(0, 3), blurRadius: 0,
                          )],
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: showResult && isCorrect ? PxDecor.green : showResult && isSelected ? PxDecor.red : baseColor),
                      ),
                    ])),
                  ),
                ),
                // Label alani
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(
                      label,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: px.text),
                      maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    )),
                    if (showResult && isCorrect)
                      const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 18)),
                    if (showResult && isSelected && !isCorrect)
                      const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.cancel_rounded, color: PxDecor.red, size: 18)),
                  ]),
                ),
              ]),
            ),
          );
        }),
      ),
    ]);
  }
}
