import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_result/providers/note_detail_provider.dart';
import '../providers/quiz_provider.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, this.noteId});

  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);

    if (noteId != null) {
      final noteAsync = ref.watch(noteDetailProvider(noteId!));
      noteAsync.whenData((data) {
        final questions = (data['questions'] as List?)?.cast<dynamic>() ?? [];
        if (questions.isNotEmpty) {
          final currentQuestions = ref.read(quizProvider).questions;
          final needsLoad = currentQuestions.isEmpty || 
              (currentQuestions.isNotEmpty && 
               currentQuestions.first.question == 'Elektrik alanın birimi nedir?');
          if (needsLoad) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(quizProvider.notifier).loadFromNoteQuestions(questions);
            });
          }
        }
      });
    }

    final quiz = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);
    final q = quiz.currentQuestion;

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: quiz.isFinished
              ? _FinishedView(px: px, total: quiz.total, correct: quiz.correctCount, onRestart: notifier.restart)
              : (q == null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: px.accentBg(PxDecor.blue), borderRadius: BorderRadius.circular(18), border: Border.all(color: PxDecor.blue, width: 2)),
                        child: const Icon(Icons.psychology_rounded, color: PxDecor.blue, size: 32),
                      ),
                      const SizedBox(height: 14),
                      Text('Henuz soru yok', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: px.text)),
                      const SizedBox(height: 6),
                      Text('Quiz sorulari bulunamadi', style: TextStyle(color: px.textSub, fontSize: 13)),
                    ]))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // ─── TOP BAR ───
                      Row(children: [
                        GestureDetector(
                          onTap: () { Haptic.light(); Navigator.of(context).maybePop(); },
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: px.textMuted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Quiz', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text))),
                        // Soru sayaci
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: px.heroDeco(PxDecor.blue, PxDecor.blueDark, depth: 3),
                          child: Text('${quiz.currentIndex + 1}/${quiz.total}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ─── PROGRESS BAR ───
                      Container(
                        height: 14,
                        decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: px.border, width: 2)),
                        child: LayoutBuilder(builder: (_, c) {
                          final pct = quiz.total == 0 ? 0.0 : (quiz.currentIndex + 1) / quiz.total;
                          return Stack(children: [
                            Container(width: c.maxWidth * pct, decoration: BoxDecoration(color: PxDecor.teal, borderRadius: BorderRadius.circular(5))),
                          ]);
                        }),
                      ),
                      const SizedBox(height: 20),

                      // ─── SORU KARTI ───
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: px.cardDeco(),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: PxDecor.blue, borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text('${quiz.currentIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                            ),
                            const SizedBox(width: 10),
                            Text('Soru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: px.textSub)),
                          ]),
                          const SizedBox(height: 14),
                          Text(q.question, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: px.text)),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // ─── SECENEKLER ───
                      Expanded(child: ListView(children: [
                        ...List.generate(q.options.length, (i) {
                          final isSelected = quiz.selectedIndex == i;
                          final isCorrect = i == q.correctIndex;
                          final showResult = quiz.selectedIndex != null;

                          BoxDecoration deco;
                          if (showResult && isCorrect) {
                            deco = px.correctDeco(depth: 3);
                          } else if (showResult && isSelected && !isCorrect) {
                            deco = px.wrongDeco(depth: 3);
                          } else if (isSelected && !showResult) {
                            deco = px.selectedDeco(depth: 3);
                          } else {
                            deco = px.cardDeco(depth: 3);
                          }

                          final optLabel = String.fromCharCode(65 + i); // A, B, C, D

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: showResult ? null : () { Haptic.medium(); notifier.selectAnswer(i); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: deco,
                                child: Row(children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: showResult && isCorrect ? PxDecor.green
                                          : showResult && isSelected && !isCorrect ? PxDecor.red
                                          : px.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: showResult && isCorrect ? PxDecor.greenDark
                                            : showResult && isSelected && !isCorrect ? PxDecor.redDark
                                            : px.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(child: Text(optLabel, style: TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 13,
                                      color: (showResult && (isCorrect || (isSelected && !isCorrect))) ? Colors.white : px.text,
                                    ))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(q.options[i], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: px.text))),
                                  if (showResult && isCorrect)
                                    const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 22),
                                  if (showResult && isSelected && !isCorrect)
                                    const Icon(Icons.cancel_rounded, color: PxDecor.red, size: 22),
                                ]),
                              ),
                            ),
                          );
                        }),

                        // Aciklama
                        if (quiz.selectedIndex != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: px.accentBg(PxDecor.blue),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: PxDecor.blue, width: 2),
                              boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(px.isDark ? 25 : 50), offset: const Offset(0, 3), blurRadius: 0)],
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.lightbulb_rounded, color: PxDecor.blue, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(q.explanation, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.text))),
                            ]),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ])),

                      // ─── DEVAM BUTONU ───
                      GestureDetector(
                        onTap: quiz.selectedIndex == null ? null : () { Haptic.light(); notifier.next(); },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: quiz.selectedIndex == null ? px.surface : PxDecor.teal,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: quiz.selectedIndex == null ? px.border : PxDecor.tealDark, width: 2),
                            boxShadow: [BoxShadow(
                              color: quiz.selectedIndex == null ? px.shadow : PxDecor.tealDark,
                              offset: const Offset(0, 4), blurRadius: 0,
                            )],
                          ),
                          child: Center(child: Text(
                            (quiz.currentIndex == quiz.total - 1) ? 'Bitir' : 'Devam',
                            style: TextStyle(color: quiz.selectedIndex == null ? px.textMuted : Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          )),
                        ),
                      ),
                    ])),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Sonuc Ekrani — Pixel Game Tarz
// ═══════════════════════════════════════════════════
class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.px, required this.total, required this.correct, required this.onRestart});
  final Px px;
  final int total, correct;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final wrong = total - correct;

    Color heroColor, heroDark;
    String emoji, label;
    if (pct >= 80) { heroColor = PxDecor.green; heroDark = PxDecor.greenDark; emoji = '🎉'; label = 'Mukemmel!'; }
    else if (pct >= 60) { heroColor = PxDecor.gold; heroDark = PxDecor.goldDark; emoji = '👍'; label = 'Iyi gidiyorsun!'; }
    else if (pct >= 40) { heroColor = PxDecor.orange; heroDark = PxDecor.orangeDark; emoji = '💪'; label = 'Daha iyi olabilir'; }
    else { heroColor = PxDecor.red; heroDark = PxDecor.redDark; emoji = '📚'; label = 'Tekrar dene!'; }

    return Column(children: [
      // Geri butonu
      Row(children: [
        GestureDetector(
          onTap: () { Haptic.light(); Navigator.of(context).maybePop(); },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: px.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Text('Sonuc', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text)),
      ]),
      const Spacer(),

      // Hero sonuc karti
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: px.heroDeco(heroColor, heroDark),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 8),
          Text('%$pct basari', style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 20),

      // Skor kartlari
      Row(children: [
        Expanded(child: _scoreTile(px, 'Dogru', correct, PxDecor.green, PxDecor.greenDark, Icons.check_circle_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _scoreTile(px, 'Yanlis', wrong, PxDecor.red, PxDecor.redDark, Icons.cancel_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _scoreTile(px, 'Toplam', total, PxDecor.blue, PxDecor.blueDark, Icons.quiz_rounded)),
      ]),

      const Spacer(),

      // Tekrar basla
      GestureDetector(
        onTap: () { Haptic.medium(); onRestart(); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: PxDecor.teal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PxDecor.tealDark, width: 2),
            boxShadow: [BoxShadow(color: PxDecor.tealDark, offset: const Offset(0, 4), blurRadius: 0)],
          ),
          child: const Center(child: Text('Tekrar basla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
        ),
      ),
    ]);
  }

  static Widget _scoreTile(Px px, String label, int value, Color color, Color dark, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: px.accentBg(color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: dark.withAlpha(px.isDark ? 30 : 60), offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text('$value', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.isDark ? color : dark)),
      ]),
    );
  }
}
