import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../providers/note_detail_provider.dart';

// ═══════════════════════════════════════════════════════
//  FLASHCARD TAB — Pixel Game Design
// ═══════════════════════════════════════════════════════

class FlashcardTab extends ConsumerWidget {
  const FlashcardTab({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final note = ref.watch(noteDetailProvider(noteId));

    return note.when(
      loading: () => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text('Kartlar yukleniyor...', style: TextStyle(color: px.textSub, fontWeight: FontWeight.w600, fontSize: 13)),
      ])),
      error: (e, _) => Center(child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: px.wrongDeco(depth: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: PxDecor.red, size: 40),
          const SizedBox(height: 12),
          Text('Kartlar yuklenemedi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
          const SizedBox(height: 6),
          Text(e.toString(), style: TextStyle(color: px.textSub, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
        ]),
      )),
      data: (data) {
        final cards = (data['flashcards'] as List?)?.cast<dynamic>() ?? [];

        if (cards.isEmpty) {
          return Center(child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: px.cardDeco(depth: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.style_outlined, color: px.textMuted, size: 48),
              const SizedBox(height: 12),
              Text('Flashcard yok', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
              const SizedBox(height: 4),
              Text('Bu not icin kart bulunamadi', style: TextStyle(color: px.textSub, fontSize: 13)),
            ]),
          ));
        }

        return _FlashcardPager(cards: cards);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PAGER — swipe ile kart gecisi + sayac
// ═══════════════════════════════════════════════════════
class _FlashcardPager extends StatefulWidget {
  const _FlashcardPager({required this.cards});
  final List<dynamic> cards;

  @override
  State<_FlashcardPager> createState() => _FlashcardPagerState();
}

class _FlashcardPagerState extends State<_FlashcardPager> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final total = widget.cards.length;

    return Column(children: [
      // Ust bar: sayac + progress
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: px.cardDeco(bg: px.accentBg(PxDecor.teal), borderColor: PxDecor.teal, depth: 2),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.style_rounded, color: PxDecor.teal, size: 16),
              const SizedBox(width: 6),
              Text('${_currentPage + 1} / $total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: PxDecor.teal)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(
            height: 8,
            decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: px.border, width: 1)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentPage + 1) / total,
              child: Container(decoration: BoxDecoration(color: PxDecor.teal, borderRadius: BorderRadius.circular(4))),
            ),
          )),
          const SizedBox(width: 12),
          Text('Kaydir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textMuted)),
          const SizedBox(width: 2),
          Icon(Icons.swipe_rounded, size: 16, color: px.textMuted),
        ]),
      ),

      // Kartlar
      Expanded(
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: total,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, i) {
            final m = (widget.cards[i] as Map).cast<String, dynamic>();
            final front = (m['front'] as String?) ?? '';
            final back = (m['back'] as String?) ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: _PixelFlipCard(front: front, back: back, index: i),
            );
          },
        ),
      ),

      // Alt navigasyon
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Row(children: [
          _NavButton(
            icon: Icons.arrow_back_rounded,
            label: 'Onceki',
            color: PxDecor.blue,
            enabled: _currentPage > 0,
            onTap: () { _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut); },
          ),
          const Spacer(),
          // Nokta gostergesi
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(
            total > 10 ? 10 : total,
            (i) {
              final dotIdx = total > 10 ? ((_currentPage / (total - 1)) * 9).round() : i;
              final isActive = total > 10 ? i == dotIdx : i == _currentPage;
              return Container(
                width: isActive ? 10 : 6, height: isActive ? 10 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? PxDecor.teal : px.border,
                  shape: BoxShape.circle,
                ),
              );
            },
          )),
          const Spacer(),
          _NavButton(
            icon: Icons.arrow_forward_rounded,
            label: 'Sonraki',
            color: PxDecor.teal,
            enabled: _currentPage < total - 1,
            onTap: () { _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut); },
          ),
        ]),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════
//  NAV BUTTON — Pixel tarz kucuk buton
// ═══════════════════════════════════════════════════════
class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.color, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? color : px.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? color : px.border, width: 2),
          boxShadow: [BoxShadow(color: enabled ? color.withAlpha(80) : px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: enabled ? Colors.white : px.textMuted, size: 16),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: enabled ? Colors.white : px.textMuted)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PIXEL FLIP CARD — 3D cevirme animasyonu
// ═══════════════════════════════════════════════════════

const _cardColors = [
  [PxDecor.teal, PxDecor.tealDark],
  [PxDecor.blue, PxDecor.blueDark],
  [PxDecor.purple, PxDecor.purpleDark],
  [PxDecor.green, PxDecor.greenDark],
  [PxDecor.orange, PxDecor.orangeDark],
  [PxDecor.gold, PxDecor.goldDark],
];

class _PixelFlipCard extends StatefulWidget {
  const _PixelFlipCard({required this.front, required this.back, required this.index});
  final String front;
  final String back;
  final int index;

  @override
  State<_PixelFlipCard> createState() => _PixelFlipCardState();
}

class _PixelFlipCardState extends State<_PixelFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    if (_showFront) { _ctrl.forward(); } else { _ctrl.reverse(); }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final colors = _cardColors[widget.index % _cardColors.length];
    final mainColor = colors[0];
    final darkColor = colors[1];

    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final angle = _anim.value * math.pi;
          final isFront = angle < math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildFront(px, mainColor, darkColor)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(px, mainColor, darkColor),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(Px px, Color main, Color dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: main, width: 3),
        boxShadow: [BoxShadow(color: dark.withAlpha(px.isDark ? 60 : 100), offset: const Offset(0, 6), blurRadius: 0)],
      ),
      child: Column(children: [
        // Ust baslik bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: main,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.help_outline_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            const Text('SORU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
          ]),
        ),
        const SizedBox(height: 24),
        // Soru metni
        Expanded(
          child: Center(child: SingleChildScrollView(
            child: Text(
              widget.front,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: px.text, height: 1.5),
              textAlign: TextAlign.center,
            ),
          )),
        ),
        const SizedBox(height: 16),
        // Alt ipucu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: px.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: px.border, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app_rounded, color: main, size: 16),
            const SizedBox(width: 6),
            Text('Cevabi gormek icin dokun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textSub)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBack(Px px, Color main, Color dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: main,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark, width: 3),
        boxShadow: [BoxShadow(color: dark.withAlpha(px.isDark ? 60 : 100), offset: const Offset(0, 6), blurRadius: 0)],
      ),
      child: Column(children: [
        // Ust baslik bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withAlpha(60), width: 2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            const Text('CEVAP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
          ]),
        ),
        const SizedBox(height: 24),
        // Cevap metni
        Expanded(
          child: Center(child: SingleChildScrollView(
            child: Text(
              widget.back,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white, height: 1.6),
              textAlign: TextAlign.center,
            ),
          )),
        ),
        const SizedBox(height: 16),
        // Alt ipucu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app_rounded, color: Colors.white.withAlpha(200), size: 16),
            const SizedBox(width: 6),
            Text('Soruya donmek icin dokun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white.withAlpha(200))),
          ]),
        ),
      ]),
    );
  }
}
