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
  // Index-based: slot index -> term index
  final Map<int, int> _answers = {};
  late List<Map<String, String>> _uniquePairs;
  late List<int> _shuffledTermIndices;
  int? _selectedTermIdx;

  @override
  void initState() {
    super.initState();
    // Deduplicate pairs by both term and definition to avoid collisions
    final seen = <String>{};
    _uniquePairs = [];
    for (final p in widget.pairs) {
      final key = '${p['term']}|||${p['definition']}';
      if (!seen.contains(key) && (p['term'] ?? '').isNotEmpty && (p['definition'] ?? '').isNotEmpty) {
        seen.add(key);
        _uniquePairs.add(p);
      }
    }
    if (_uniquePairs.isEmpty) _uniquePairs = List.from(widget.pairs);
    _shuffledTermIndices = List.generate(_uniquePairs.length, (i) => i)..shuffle();
  }

  bool get isReady => _answers.length == _uniquePairs.length;
  bool checkAnswer() => _answers.entries.every((e) => e.value == e.key);

  void reset() {
    setState(() { _answers.clear(); _shuffledTermIndices.shuffle(); _selectedTermIdx = null; });
    widget.onChanged?.call();
  }

  void _selectTerm(int termIdx) {
    if (widget.answered) return;
    if (_answers.containsValue(termIdx)) return;
    setState(() => _selectedTermIdx = _selectedTermIdx == termIdx ? null : termIdx);
  }

  void _selectSlot(int slotIdx) {
    if (widget.answered) return;
    if (_answers.containsKey(slotIdx)) return;
    if (_selectedTermIdx == null) return;
    setState(() {
      _answers[slotIdx] = _selectedTermIdx!;
      _selectedTermIdx = null;
    });
    widget.onChanged?.call();
  }

  void _remove(int slotIdx) {
    if (widget.answered) return;
    setState(() => _answers.remove(slotIdx));
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
            child: Text('${_answers.length}/${_uniquePairs.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Definition slots (targets)
      ...List.generate(_uniquePairs.length, (i) {
        final p = _uniquePairs[i];
        final def = p['definition']!;
        final matchedTermIdx = _answers[i];
        final has = matchedTermIdx != null;
        final matchedTerm = has ? _uniquePairs[matchedTermIdx]['term']! : null;
        final ok = widget.showCorrectAnswer && has && matchedTermIdx == i;
        final bad = widget.answered && has && matchedTermIdx != i;
        final isTarget = _selectedTermIdx != null && !has && !widget.answered;
        // Dogru cevap: slot i'nin dogru termi (pair indexi == slot indexi)
        final correctTerm = _uniquePairs[i]['term']!;
        final showCorrection = widget.showCorrectAnswer && bad;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: isTarget ? () { Haptic.selection(); _selectSlot(i); } : null,
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
                  // Kullanicinin verdigi cevap
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
                      matchedTerm ?? (isTarget ? 'Buraya yerlestir' : '_ _ _ _ _'),
                      style: TextStyle(
                        fontWeight: has ? FontWeight.w800 : FontWeight.w600, fontSize: 14,
                        color: has ? (ok ? PxDecor.greenDark : bad ? PxDecor.redDark : PxDecor.tealDark) : (isTarget ? PxDecor.teal : px.textMuted),
                        fontStyle: has ? FontStyle.normal : FontStyle.italic,
                        decoration: showCorrection ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  // Dogru cevabi goster (yanlis eslesmede)
                  if (showCorrection) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: px.accentBg(PxDecor.green),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PxDecor.green, width: 2, strokeAlign: BorderSide.strokeAlignInside),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(correctTerm, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: PxDecor.greenDark))),
                      ]),
                    ),
                  ],
                ])),
                const SizedBox(width: 6),
                if (has && !widget.answered) GestureDetector(
                  onTap: () { Haptic.light(); _remove(i); },
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
          Wrap(spacing: 8, runSpacing: 8, children: _shuffledTermIndices.map((termIdx) {
            final t = _uniquePairs[termIdx]['term']!;
            final used = _answers.containsValue(termIdx);
            final selected = _selectedTermIdx == termIdx;
            return GestureDetector(
              onTap: (!used && !widget.answered) ? () { Haptic.selection(); _selectTerm(termIdx); } : null,
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
