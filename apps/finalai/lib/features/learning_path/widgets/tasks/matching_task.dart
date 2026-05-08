import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════
//  MATCHING TASK — Tap-to-place: kavram sec → bosluk sec → yerles
// ═══════════════════════════════════════════════════════════════

class MatchingTask extends StatefulWidget {
  const MatchingTask({super.key, required this.pairs, required this.answered, this.showCorrectAnswer = false, required this.onComplete, this.onChanged});
  final List<Map<String, String>> pairs;
  final bool answered;
  final bool showCorrectAnswer;
  final ValueChanged<bool> onComplete;
  final VoidCallback? onChanged;
  @override
  State<MatchingTask> createState() => MatchingTaskState();
}

class MatchingTaskState extends State<MatchingTask> {
  final Map<String, String> _answers = {};
  late List<String> _shuffled;
  String? _selectedTerm;

  @override
  void initState() {
    super.initState();
    _shuffled = widget.pairs.map((p) => p['term']!).toList()..shuffle();
  }

  bool get isReady => _answers.length == widget.pairs.length;
  bool checkAnswer() => widget.pairs.every((p) => _answers[p['definition']] == p['term']);

  void reset() {
    setState(() { _answers.clear(); _shuffled.shuffle(); _selectedTerm = null; });
    widget.onChanged?.call();
  }

  void _selectTerm(String term) {
    if (widget.answered) return;
    if (_answers.containsValue(term)) return;
    setState(() => _selectedTerm = _selectedTerm == term ? null : term);
  }

  void _selectSlot(String def) {
    if (widget.answered) return;
    if (_answers.containsKey(def)) return;
    if (_selectedTerm == null) return;
    setState(() {
      _answers[def] = _selectedTerm!;
      _selectedTerm = null;
    });
    widget.onChanged?.call();
  }

  void _remove(String def) {
    if (widget.answered) return;
    setState(() => _answers.remove(def));
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Instruction header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.teal), borderColor: PxDecor.teal, depth: 3),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: PxDecor.teal.withAlpha(40), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.touch_app_rounded, color: PxDecor.teal, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kavramlari esle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: px.isDark ? PxDecor.teal : PxDecor.tealDark)),
            const SizedBox(height: 2),
            Text('Bir kavram sec, sonra bosluga dokun', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: PxDecor.teal, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: PxDecor.tealDark.withAlpha(60), offset: const Offset(0, 2), blurRadius: 0)]),
            child: Text('${_answers.length}/${widget.pairs.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Definition slots (targets)
      ...List.generate(widget.pairs.length, (i) {
        final p = widget.pairs[i];
        final def = p['definition']!;
        final correct = p['term']!;
        final matched = _answers[def];
        final has = matched != null;
        final ok = widget.showCorrectAnswer && matched == correct;
        final bad = widget.answered && matched != null && matched != correct;
        final isTarget = _selectedTerm != null && !has && !widget.answered;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: isTarget ? () { Haptic.selection(); _selectSlot(def); } : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(12),
              decoration: ok ? px.correctDeco(depth: 3) : bad ? px.wrongDeco(depth: 3)
                  : isTarget ? px.selectedDeco(color: PxDecor.teal, depth: 3) : px.cardDeco(depth: 3),
              child: Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: ok ? PxDecor.green : bad ? PxDecor.red : isTarget ? PxDecor.teal : PxDecor.teal.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: (ok ? PxDecor.greenDark : bad ? PxDecor.redDark : PxDecor.tealDark).withAlpha(50), offset: const Offset(0, 2), blurRadius: 0)],
                  ),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(def, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: px.text)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: has ? (ok ? px.accentBg(PxDecor.green) : bad ? px.accentBg(PxDecor.red) : px.accentBg(PxDecor.teal))
                          : isTarget ? PxDecor.teal.withAlpha(20) : px.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: has ? (ok ? PxDecor.green : bad ? PxDecor.red : PxDecor.teal)
                            : isTarget ? PxDecor.teal : px.border,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Text(
                      has ? matched : (isTarget ? 'Buraya yerlestir' : '_ _ _ _ _'),
                      style: TextStyle(
                        fontWeight: has ? FontWeight.w800 : FontWeight.w600, fontSize: 14,
                        color: has ? (ok ? PxDecor.greenDark : bad ? PxDecor.redDark : PxDecor.tealDark) : (isTarget ? PxDecor.teal : px.textMuted),
                        fontStyle: has ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                ])),
                const SizedBox(width: 6),
                if (has && !widget.answered) GestureDetector(
                  onTap: () { Haptic.light(); _remove(def); },
                  child: Container(width: 30, height: 30, decoration: BoxDecoration(color: px.accentBg(PxDecor.red), borderRadius: BorderRadius.circular(8), border: Border.all(color: PxDecor.red, width: 1.5)),
                    child: const Icon(Icons.close_rounded, color: PxDecor.red, size: 16)),
                ),
                if (widget.showCorrectAnswer) Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? PxDecor.green : PxDecor.red, size: 24)
                else if (widget.answered && bad) const Icon(Icons.cancel_rounded, color: PxDecor.red, size: 24),
              ]),
            ),
          ),
        );
      }),
      const SizedBox(height: 14),

      // Term chips at the bottom
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: px.cardDeco(depth: 3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kavramlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: px.textSub)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _shuffled.map((t) {
            final used = _answers.containsValue(t);
            final selected = _selectedTerm == t;
            return GestureDetector(
              onTap: (!used && !widget.answered) ? () { Haptic.selection(); _selectTerm(t); } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? PxDecor.teal : used ? px.surface : px.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? PxDecor.tealDark : used ? px.border : PxDecor.teal, width: 2),
                  boxShadow: used ? [] : [BoxShadow(
                    color: selected ? PxDecor.tealDark : PxDecor.teal.withAlpha(px.isDark ? 30 : 60),
                    offset: const Offset(0, 3), blurRadius: 0,
                  )],
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14,
                    color: selected ? Colors.white : used ? px.textMuted : PxDecor.tealDark,
                    decoration: used ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList()),
        ]),
      ),
    ]);
  }
}
