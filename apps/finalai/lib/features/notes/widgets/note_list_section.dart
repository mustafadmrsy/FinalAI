import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/repository_providers.dart';
import '../../../models/note_model.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/pixel_confirm_dialog.dart';

// ═══════════════════════════════════════════════════════════════
//  BELGELERIM — 2D Pixel Game Art Style
// ═══════════════════════════════════════════════════════════════

class NoteListSection extends ConsumerWidget {
  const NoteListSection({
    super.key,
    required this.title,
    required this.notes,
    this.onChanged,
    this.emptyTitle = 'Henuz not yok',
    this.emptyMessage = 'Bir PDF yukleyerek ilk notunu olusturabilirsin.',
    this.showHeader = true,
  });

  final String title;
  final AsyncValue<List<NoteModel>> notes;
  final VoidCallback? onChanged;
  final String emptyTitle;
  final String emptyMessage;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showHeader) ...[
        Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: PxDecor.blue, borderRadius: BorderRadius.circular(10)),
            child: Text('${notes.valueOrNull?.length ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 14),
      ],
      notes.when(
        loading: () => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: px.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: px.border, width: 2),
            boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Center(child: Column(children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: PxDecor.blue)),
            const SizedBox(height: 10),
            Text('Belgeler yukleniyor...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textMuted)),
          ])),
        ),
        error: (e, _) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: px.accentBg(PxDecor.red),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PxDecor.red, width: 2),
          ),
          child: Row(children: [
            Icon(Icons.error_outline_rounded, color: PxDecor.red, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('Belgeler yuklenemedi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: PxDecor.red))),
          ]),
        ),
        data: (items) {
          if (items.isEmpty) return _buildEmptyState(px);
          return Column(children: [
            for (int i = 0; i < items.length; i++) ...[
              _NoteCard(note: items[i], index: i, onChanged: onChanged),
              if (i < items.length - 1) const SizedBox(height: 10),
            ],
          ]);
        },
      ),
    ]);
  }

  Widget _buildEmptyState(Px px) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: px.border, width: 2),
        boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 4), blurRadius: 0)],
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: px.accentBg(PxDecor.blue),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PxDecor.blue, width: 2),
            boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(30), offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Stack(children: [
            Positioned(top: 4, left: 4, child: Container(
              width: 14, height: 6,
              decoration: BoxDecoration(color: PxDecor.blue.withAlpha(30), borderRadius: BorderRadius.circular(3)),
            )),
            const Center(child: Icon(Icons.description_outlined, color: PxDecor.blue, size: 28)),
          ]),
        ),
        const SizedBox(height: 16),
        Text(emptyTitle, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
        const SizedBox(height: 4),
        Text(emptyMessage, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textMuted), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Individual note card ──
class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note, required this.index, this.onChanged});
  final NoteModel note;
  final int index;
  final VoidCallback? onChanged;

  static const _colors = [PxDecor.blue, PxDecor.teal, PxDecor.green, PxDecor.purple, PxDecor.orange];
  static const _darkColors = [PxDecor.blueDark, PxDecor.tealDark, PxDecor.greenDark, PxDecor.purpleDark, PxDecor.orangeDark];
  static const _icons = [Icons.description_rounded, Icons.article_rounded, Icons.note_rounded, Icons.auto_stories_rounded, Icons.book_rounded];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final color = _colors[index % _colors.length];
    final dark = _darkColors[index % _darkColors.length];
    final icon = _icons[index % _icons.length];

    return GestureDetector(
      onTap: () { Haptic.light(); context.go('/result/${note.id}'); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: dark.withAlpha(px.isDark ? 20 : 40), offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(children: [
          // Pixel icon badge
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: dark, width: 2),
              boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 2), blurRadius: 0)],
            ),
            child: Stack(children: [
              Positioned(top: 3, left: 3, child: Container(
                width: 10, height: 5,
                decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(2)),
              )),
              Center(child: Icon(icon, color: Colors.white, size: 22)),
            ]),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(note.subject, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: px.accentBg(color), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(80), width: 1)),
                child: Text('Ac', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: color)),
              ),
            ]),
          ])),
          // Actions
          _buildActions(context, ref, px, color),
        ]),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Px px, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Edit name
      GestureDetector(
        onTap: () async {
          Haptic.selection();
          final newName = await showDialog<String>(
            context: context,
            builder: (ctx) => _PixelEditNoteDialog(currentName: note.subject),
          );
          if (newName != null && newName.isNotEmpty) {
            await ref.read(noteRepositoryProvider).updateNoteSubject(note.id, newName);
            onChanged?.call();
          }
        },
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(9), border: Border.all(color: px.border, width: 1.5)),
          child: Icon(Icons.edit_rounded, size: 15, color: px.textMuted),
        ),
      ),
      const SizedBox(width: 6),
      // Delete
      GestureDetector(
        onTap: () async {
          Haptic.selection();
          final confirm = await PixelConfirmDialog.show(
            context,
            icon: Icons.delete_forever_rounded,
            iconColor: PxDecor.red,
            title: 'Notu Sil?',
            message: 'Bu islem geri alinamaz.\nNotu silmek istiyor musun?',
            confirmLabel: 'Sil',
            cancelLabel: 'Iptal',
          );
          if (confirm) {
            await ref.read(noteRepositoryProvider).deleteNote(note.id);
            onChanged?.call();
          }
        },
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: px.accentBg(PxDecor.red), borderRadius: BorderRadius.circular(9), border: Border.all(color: PxDecor.red.withAlpha(80), width: 1.5)),
          child: Icon(Icons.delete_outline_rounded, size: 15, color: PxDecor.red),
        ),
      ),
    ]);
  }
}

// ── Pixel-style edit note dialog ──
class _PixelEditNoteDialog extends StatefulWidget {
  const _PixelEditNoteDialog({required this.currentName});
  final String currentName;

  @override
  State<_PixelEditNoteDialog> createState() => _PixelEditNoteDialogState();
}

class _PixelEditNoteDialogState extends State<_PixelEditNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PxDecor.blue, width: 3),
          boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 5), blurRadius: 0)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: PxDecor.blue,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 3), blurRadius: 0)],
            ),
            child: const Column(children: [
              Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
              SizedBox(height: 6),
              Text('Not Ismini Degistir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
            ]),
          ),
          // Input
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  color: px.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: px.border, width: 2),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: px.text),
                  decoration: InputDecoration(
                    hintText: 'Yeni isim',
                    hintStyle: TextStyle(color: px.textMuted, fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 2), blurRadius: 0)]),
                    child: Center(child: Text('Iptal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.text))),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(context, _controller.text.trim()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: PxDecor.blue, borderRadius: BorderRadius.circular(12), border: Border.all(color: PxDecor.blueDark, width: 2), boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 2), blurRadius: 0)]),
                    child: const Center(child: Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white))),
                  ),
                )),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
