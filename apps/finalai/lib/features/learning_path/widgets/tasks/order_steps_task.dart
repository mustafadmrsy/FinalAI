import 'package:flutter/material.dart';

import 'task_helpers.dart';
import '../../../../core/services/haptic_service.dart';

class OrderStepsTask extends StatefulWidget {
  const OrderStepsTask({super.key, required this.instruction, required this.steps, required this.correctOrder, required this.answered, this.showCorrectAnswer = false, this.onChanged});
  final String instruction;
  final List<String> steps;
  final List<int> correctOrder;
  final bool answered;
  final bool showCorrectAnswer;
  final VoidCallback? onChanged;
  @override
  State<OrderStepsTask> createState() => OrderStepsTaskState();
}

class OrderStepsTaskState extends State<OrderStepsTask> {
  late List<int> _currentOrder;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    _currentOrder = List.generate(widget.steps.length, (i) => i)..shuffle();
    while (_currentOrder.length > 1 && _isCorrectOrder()) {
      _currentOrder.shuffle();
    }
  }

  bool get isReady => true;

  bool _isCorrectOrder() {
    for (int i = 0; i < widget.correctOrder.length && i < _currentOrder.length; i++) {
      if (_currentOrder[i] != widget.correctOrder[i]) return false;
    }
    return true;
  }

  bool checkAnswer() => _isCorrectOrder();

  void reset() { setState(_shuffle); widget.onChanged?.call(); }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Talimat karti
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: px.cardDeco(bg: px.accentBg(PxDecor.blue), borderColor: PxDecor.blue, depth: 3),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: PxDecor.blue.withAlpha(40), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.swap_vert_rounded, color: PxDecor.blue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.instruction, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: px.isDark ? PxDecor.blue : PxDecor.blueDark)),
            const SizedBox(height: 2),
            Text('Ogeleri surukleyerek dogru siraya koy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textMuted)),
          ])),
        ]),
      ),
      const SizedBox(height: 14),

      // Siralama listesi
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _currentOrder.length,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: PxDecor.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PxDecor.blue, width: 2.5),
                  boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(60), offset: const Offset(0, 4), blurRadius: 8)],
                ),
                child: child,
              ),
            ),
            child: child,
          );
        },
        onReorder: widget.answered ? (_, __) {} : (old, nw) {
          Haptic.selection();
          setState(() {
            final item = _currentOrder.removeAt(old);
            _currentOrder.insert(nw > old ? nw - 1 : nw, item);
          });
          widget.onChanged?.call();
        },
        itemBuilder: (_, i) {
          final stepIdx = _currentOrder[i];
          final stepText = widget.steps[stepIdx];
          final correctStepIdx = i < widget.correctOrder.length ? widget.correctOrder[i] : -1;
          final ok = widget.showCorrectAnswer && stepIdx == correctStepIdx;
          final bad = widget.answered && stepIdx != correctStepIdx;

          final correctText = widget.showCorrectAnswer && bad && i < widget.correctOrder.length ? widget.steps[widget.correctOrder[i]] : null;

          final dec = ok ? px.correctDeco(depth: 3) : bad ? px.wrongDeco(depth: 3) : px.cardDeco(depth: 3);
          final badgeColor = ok ? PxDecor.green : bad ? PxDecor.red : PxDecor.blue;

          return Container(
            key: ValueKey('step_$stepIdx'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: dec,
            child: Row(children: [
              // Sira numarasi badge
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [BoxShadow(color: badgeColor.withAlpha(50), offset: const Offset(0, 2), blurRadius: 0)],
                ),
                child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
              ),
              const SizedBox(width: 12),
              // Icerik
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(stepText, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ok ? PxDecor.greenDark : bad ? PxDecor.redDark : px.text)),
                if (correctText != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, color: PxDecor.green, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(correctText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: PxDecor.green))),
                  ]),
                ],
              ])),
              // Surukle ikonu veya sonuc ikonu
              if (!widget.answered)
                ReorderableDragStartListener(
                  index: i,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: px.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PxDecor.blue.withAlpha(60), width: 1.5),
                    ),
                    child: const Icon(Icons.drag_handle_rounded, color: PxDecor.blue, size: 20),
                  ),
                ),
              if (ok) const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 22),
              if (bad) const Icon(Icons.cancel_rounded, color: PxDecor.red, size: 22),
            ]),
          );
        },
      ),
    ]);
  }
}
