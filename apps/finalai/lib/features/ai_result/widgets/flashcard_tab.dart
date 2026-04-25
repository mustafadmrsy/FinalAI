import 'dart:math' as math;
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/note_detail_provider.dart';

class FlashcardTab extends ConsumerWidget {
  const FlashcardTab({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteDetailProvider(noteId));

    return note.when(
      loading: () => const LoadingIndicator(message: 'Flashcard yükleniyor...'),
      error: (e, _) => EmptyState(
        title: 'Flashcard yüklenemedi',
        message: e.toString(),
        icon: Icons.error_outline,
      ),
      data: (data) {
        final cards = (data['flashcards'] as List?)?.cast<dynamic>() ?? [];

        if (cards.isEmpty) {
          return const EmptyState(
            title: 'Flashcard yok',
            message: 'Bu not için flashcard bulunamadı.',
            icon: Icons.style_outlined,
          );
        }

        return PageView.builder(
          padEnds: false,
          itemCount: cards.length,
          itemBuilder: (context, i) {
            final m = (cards[i] as Map).cast<String, dynamic>();
            final front = (m['front'] as String?) ?? '';
            final back = (m['back'] as String?) ?? '';

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _FlipCard(front: front, back: back, index: i),
            );
          },
        );
      },
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back, required this.index});

  final String front;
  final String back;
  final int index;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
    ];
    final gradient = gradients[widget.index % gradients.length];

    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle >= math.pi / 2
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(
                      gradient,
                      widget.back,
                      'Cevap',
                      Icons.lightbulb_outline,
                    ),
                  )
                : _buildCardSide(
                    gradient,
                    widget.front,
                    'Soru',
                    Icons.help_outline,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(List<Color> gradient, String text, String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Center(
              child: Text(
                text,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kartı çevirmek için dokun',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
