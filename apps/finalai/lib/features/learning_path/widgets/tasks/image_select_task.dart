import 'package:flutter/material.dart';
import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════
//  IMAGE SELECT TASK — Emoji/gorsel kartlarini secme gorevi
//  Emoji verisine gore gorsel kart gosterir
// ═══════════════════════════════════════════════════════════════

class ImageSelectTask extends StatefulWidget {
  const ImageSelectTask({
    super.key,
    required this.question,
    required this.images,
    required this.labels,
    required this.correctIndex,
    required this.answered,
    this.showCorrectAnswer = false,
    required this.onChanged,
  });

  final String question;
  final List<String> images; // emoji or url
  final List<String> labels;
  final int correctIndex;
  final bool answered;
  final bool showCorrectAnswer;
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

  /// Check if string is an emoji (starts with non-ASCII or is short special char)
  bool _isEmoji(String s) {
    if (s.isEmpty) return false;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return false;
    final rune = trimmed.runes.first;
    return rune > 127;
  }

  /// Check if string looks like a URL
  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

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
            child: const Icon(Icons.image_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.question, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: px.text))),
        ]),
      ),
      const SizedBox(height: 16),

      // 2x2 Gorsel kartlar
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: List.generate(widget.labels.length.clamp(0, 4), (i) {
          final isSelected = _selected == i;
          final isCorrect = i == widget.correctIndex;
          final showResult = widget.answered;

          final baseColor = _cardColors[i % _cardColors.length];
          final baseDark = _cardDarks[i % _cardDarks.length];
          final label = i < widget.labels.length ? widget.labels[i] : '';
          final image = i < widget.images.length ? widget.images[i] : '';

          Color borderColor;
          Color bgColor;
          Color shadowColor;
          if (widget.showCorrectAnswer && isCorrect) {
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

          // Visual content: emoji > network image > fallback icon
          Widget visualContent;
          if (_isEmoji(image)) {
            visualContent = Text(image, style: const TextStyle(fontSize: 42));
          } else if (_isUrl(image)) {
            visualContent = ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  label.isNotEmpty ? label[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: baseColor),
                ),
              ),
            );
          } else {
            // Fallback: large letter + color
            visualContent = Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: baseColor),
            );
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
                // Gorsel alan
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.showCorrectAnswer && isCorrect
                          ? PxDecor.green.withAlpha(25)
                          : showResult && isSelected && !isCorrect
                              ? PxDecor.red.withAlpha(25)
                              : baseColor.withAlpha(isSelected ? 30 : 15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    child: Center(child: visualContent),
                  ),
                ),
                // Label alani
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Expanded(child: Text(
                      label,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: px.text),
                      maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    )),
                    if (widget.showCorrectAnswer && isCorrect)
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
