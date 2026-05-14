import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'tasks/task_helpers.dart';
import '../../../core/services/game_engine_service.dart';
import '../../../core/services/haptic_service.dart';

/// Ders tamamlama overlay'i — uyuyan maskot + XP/istatistik
class LessonCompleteOverlay extends StatefulWidget {
  const LessonCompleteOverlay({
    super.key,
    required this.xpEarned,
    required this.correctCount,
    required this.totalSteps,
    required this.isPerfect,
  });

  final int xpEarned;
  final int correctCount;
  final int totalSteps;
  final bool isPerfect;

  static Future<void> show(
    BuildContext context, {
    required int xpEarned,
    required int correctCount,
    required int totalSteps,
    required bool isPerfect,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => LessonCompleteOverlay(
        xpEarned: xpEarned,
        correctCount: correctCount,
        totalSteps: totalSteps,
        isPerfect: isPerfect,
      ),
    );
  }

  @override
  State<LessonCompleteOverlay> createState() => _LessonCompleteOverlayState();
}

class _LessonCompleteOverlayState extends State<LessonCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _starCtrl;
  late Animation<double> _cardScale;
  late Animation<double> _starScale;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardScale = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);

    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _starScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _starCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starCtrl.forward();
    });
    Haptic.heavy();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  int get _stars => widget.isPerfect ? 3 : (widget.correctCount >= widget.totalSteps * 0.7 ? 2 : 1);

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    return ScaleTransition(
      scale: _cardScale,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: px.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PxDecor.green, width: 3),
            boxShadow: [
              BoxShadow(color: PxDecor.greenDark, offset: const Offset(0, 6), blurRadius: 0),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Green header with mascot
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              decoration: const BoxDecoration(
                color: PxDecor.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
              ),
              child: Column(children: [
                // Mascot Lottie
                SizedBox(
                  width: 130, height: 130,
                  child: Lottie.asset(
                    'assets/mascot/Cute Cup Sleeping.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isPerfect ? 'Mukemmel!' : 'Ders Bitti!',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22,
                    shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2))],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sleepMessages[Random().nextInt(_sleepMessages.length)],
                  style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(children: [
                // Pixel stars
                AnimatedBuilder(
                  animation: _starCtrl,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final earned = i < _stars;
                      final delay = i * 0.15;
                      final t = ((_starCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.scale(
                          scale: earned ? _starScale.value * t.clamp(0.5, 1.0) : 0.6,
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: earned ? PxDecor.gold : px.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: earned ? PxDecor.goldDark : px.border, width: 3),
                              boxShadow: [BoxShadow(
                                color: earned ? PxDecor.goldDark : px.shadow,
                                offset: const Offset(0, 3), blurRadius: 0,
                              )],
                            ),
                            child: Icon(Icons.star_rounded, color: earned ? Colors.white : px.border, size: 24),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Stat tiles row
                Row(children: [
                  Expanded(child: _statTile(px, Icons.auto_awesome_rounded, PxDecor.green, PxDecor.greenDark, '+${GameEngineService.formatXp(widget.xpEarned)}', 'XP')),
                  const SizedBox(width: 8),
                  Expanded(child: _statTile(px, Icons.check_circle_rounded, PxDecor.blue, PxDecor.blueDark, '${widget.correctCount}/${widget.totalSteps}', 'Dogru')),
                  const SizedBox(width: 8),
                  Expanded(child: _statTile(
                    px, Icons.workspace_premium_rounded,
                    widget.isPerfect ? PxDecor.gold : PxDecor.purple,
                    widget.isPerfect ? PxDecor.goldDark : PxDecor.purpleDark,
                    widget.isPerfect ? 'Evet!' : 'Hayir',
                    'Kusursuz',
                  )),
                ]),
                const SizedBox(height: 18),

                // Continue button
                GestureDetector(
                  onTap: () { Haptic.light(); Navigator.of(context).pop(); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: PxDecor.green,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PxDecor.greenDark, width: 2),
                      boxShadow: [BoxShadow(color: PxDecor.greenDark, offset: const Offset(0, 4), blurRadius: 0)],
                    ),
                    child: const Center(child: Text('Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statTile(Px px, IconData icon, Color color, Color dark, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dark, width: 2),
        boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 9, color: Colors.white.withAlpha(200))),
      ]),
    );
  }
}

const _sleepMessages = [
  'Beyni biraz sogut, hak ettin!',
  'Sen uyurken bilgi beyne yerlesir, bilim diyor!',
  'Bir dahaki sefere daha da iyi olacaksin!',
  'Simdi bi mola, sonra dunya senin!',
  'Beyin: "Tesekkurler, biraz nefes alayim."',
  'Kisa bir ara, buyuk bir geri donus!',
  'Dinlenme de antrenmanin parcasi!',
  'Yastiga kafani koy, ruya fabrikasi acilsin!',
  'Bi kestir, sonra geri gel, bekliyoruz!',
  'Uyku deyip gecme, super guc bu!',
  'Hafiza konsolidasyonu baslasin... zzZ',
  'Gozlerini kapat, bilgi otomatik yukleniyor!',
  'Mola vermek zayiflik degil, strateji!',
  'Biraz dinlen, beyin arka planda calisiyor!',
  'Uyku = bedava performans arttirici!',
];
