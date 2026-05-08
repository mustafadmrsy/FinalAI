import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/repository_providers.dart';
import '../../../models/note_model.dart';
import '../../home/providers/notes_provider.dart';
import '../providers/upload_provider.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/pixel_confirm_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../shop/widgets/quota_popup.dart';

final _allNotesProvider = FutureProvider<List<NoteModel>>((ref) {
  // Auth state'e bagimli — kullanici degisince yeniden ceker
  final auth = ref.watch(authProvider);
  if (auth.session == null) return <NoteModel>[];
  return ref.watch(noteRepositoryProvider).getRecentNotes(limit: 50);
});

// ═══════════════════════════════════════════════════════════════
//  BELGELERIM — 2D Pixel Game Art Style
// ═══════════════════════════════════════════════════════════════

class PdfUploadScreen extends ConsumerStatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  ConsumerState<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends ConsumerState<PdfUploadScreen> {
  final _subjectCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Her acilista belgeleri yeniden getir
    Future.microtask(() {
      ref.invalidate(_allNotesProvider);
      ref.invalidate(recentNotesProvider);
    });
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final state = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final allNotes = ref.watch(_allNotesProvider);

    ref.listen(uploadProvider, (prev, next) {
      if (next.status == UploadStatus.processing && prev?.status != UploadStatus.processing) {
        context.go('/ai-processing');
      }
      if (next.status == UploadStatus.done && next.resultId != null) {
        ref.invalidate(recentNotesProvider);
        ref.invalidate(_allNotesProvider);
        notifier.reset();
        _subjectCtrl.clear();
        context.go('/home');
      }
    });

    final noteCount = allNotes.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            // ─── HEADER ───
            Row(children: [
              // Pixel page icon
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: PxDecor.purple,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PxDecor.purpleDark, width: 2),
                  boxShadow: [BoxShadow(color: PxDecor.purpleDark, offset: const Offset(0, 3), blurRadius: 0)],
                ),
                child: Stack(children: [
                  Positioned(top: 3, left: 3, child: Container(width: 10, height: 5, decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(2)))),
                  const Center(child: Icon(Icons.folder_rounded, color: Colors.white, size: 20)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Belgelerim', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text)),
                if (noteCount > 0)
                  Text('$noteCount belge', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: px.textMuted)),
              ])),
              if (noteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: PxDecor.teal, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: PxDecor.tealDark, offset: const Offset(0, 2), blurRadius: 0)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.description_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text('$noteCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                ),
            ]),
            const SizedBox(height: 20),

            // ─── UPLOAD SECTION — Pixel Game Card ───
            Container(
              decoration: BoxDecoration(
                color: px.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PxDecor.blue, width: 3),
                boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 5), blurRadius: 0)],
              ),
              child: Column(children: [
                // Card header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  decoration: BoxDecoration(
                    color: PxDecor.blue,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                      ),
                      child: Stack(children: [
                        Positioned(top: 3, left: 3, child: Container(width: 9, height: 4, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(2)))),
                        const Center(child: Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Yeni Belge Yukle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('PDF veya Word yukle', style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600, fontSize: 11)),
                    ])),
                  ]),
                ),

                // Card body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // Subject input
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: px.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: px.border, width: 2),
                      ),
                      child: Row(children: [
                        Icon(Icons.school_rounded, color: PxDecor.blue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(
                          controller: _subjectCtrl,
                          onChanged: notifier.setSubject,
                          style: TextStyle(color: px.text, fontWeight: FontWeight.w700, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ders / Konu (orn: Fizik)',
                            hintStyle: TextStyle(color: px.textMuted, fontWeight: FontWeight.w600),
                            border: InputBorder.none, isCollapsed: true,
                          ),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // File pick button
                    GestureDetector(
                      onTap: state.isBusy ? null : () { Haptic.medium(); _showFileTypePicker(context, notifier, px); },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: PxDecor.blue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PxDecor.blueDark, width: 2),
                          boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 3), blurRadius: 0)],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          if (state.isBusy)
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          else
                            const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(state.isBusy ? 'Yukleniyor...' : 'Dosya Sec', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),

            // ─── UPLOAD STATUS ───
            if (state.status == UploadStatus.error) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: px.accentBg(PxDecor.red),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PxDecor.red, width: 2),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: PxDecor.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.errorMessage ?? 'Bir hata olustu', style: TextStyle(color: px.text, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // ─── DOCUMENTS LIST ───
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: PxDecor.teal, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: PxDecor.tealDark, offset: const Offset(0, 2), blurRadius: 0)]),
                child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text('Tum Belgeler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
            ]),
            const SizedBox(height: 14),

            allNotes.when(
              loading: () => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                child: Column(children: [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: PxDecor.blue)),
                  const SizedBox(height: 10),
                  Text('Belgeler yukleniyor...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textMuted)),
                ]),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: px.accentBg(PxDecor.red), borderRadius: BorderRadius.circular(14), border: Border.all(color: PxDecor.red, width: 2)),
                child: Row(children: [
                  Icon(Icons.error_outline_rounded, color: PxDecor.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Yuklenemedi: $e', style: TextStyle(color: px.text, fontWeight: FontWeight.w600, fontSize: 13))),
                ]),
              ),
              data: (items) {
                if (items.isEmpty) return _buildEmptyState(px);
                return Column(children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _DocumentCard(note: items[i], index: i),
                    if (i < items.length - 1) const SizedBox(height: 10),
                  ],
                ]);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Px px) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
            color: px.accentBg(PxDecor.teal),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PxDecor.teal, width: 2),
            boxShadow: [BoxShadow(color: PxDecor.tealDark.withAlpha(30), offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Stack(children: [
            Positioned(top: 4, left: 4, child: Container(width: 14, height: 6, decoration: BoxDecoration(color: PxDecor.teal.withAlpha(30), borderRadius: BorderRadius.circular(3)))),
            const Center(child: Icon(Icons.folder_open_outlined, color: PxDecor.teal, size: 28)),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Henuz belge yok', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
        const SizedBox(height: 6),
        Text('Yukaridan PDF veya Word yukleyerek\nozet, quiz ve flashcard olustur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textMuted), textAlign: TextAlign.center),
      ]),
    );
  }

  Future<void> _showFileTypePicker(BuildContext context, UploadNotifier notifier, Px px) async {
    Haptic.selection();
    final fileType = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PxDecor.blue, width: 3),
          boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: px.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Dosya turu sec', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () { Haptic.light(); Navigator.pop(ctx, 'pdf'); },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: PxDecor.red, borderRadius: BorderRadius.circular(14), border: Border.all(color: PxDecor.redDark, width: 2), boxShadow: [BoxShadow(color: PxDecor.redDark, offset: const Offset(0, 3), blurRadius: 0)]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('PDF dosyasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () { Haptic.light(); Navigator.pop(ctx, 'docx'); },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: PxDecor.blue, borderRadius: BorderRadius.circular(14), border: Border.all(color: PxDecor.blueDark, width: 2), boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 3), blurRadius: 0)]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.description_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Word (.docx)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
    if (fileType == null) return;
    if (fileType == 'pdf') await _pickAndUploadPdf(context, notifier);
    else if (fileType == 'docx') await _pickAndUploadWord(context, notifier);
  }

  Future<bool> _ensurePdfCredit(BuildContext context) async {
    final stats = ref.read(userStatsProvider).valueOrNull;
    if (stats != null && stats.isPremium) return true;
    if (stats != null && stats.pdfCredits > 0) return true;
    if (!context.mounted) return false;
    final rewarded = await QuotaPopup.show(context, ref, type: QuotaType.pdfCredit);
    ref.invalidate(userStatsProvider);
    return rewarded;
  }

  Future<void> _deductPdfCredit() async {
    final repo = ref.read(userStatsRepositoryProvider);
    await repo.usePdfCredit();
    ref.invalidate(userStatsProvider);
  }

  Future<void> _pickAndUploadPdf(BuildContext context, UploadNotifier notifier) async {
    if (!await _ensurePdfCredit(context)) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf'], withData: false);
    final file = result?.files.single;
    if (file == null || file.path == null) return;
    try {
      await _deductPdfCredit();
      final bytes = await File(file.path!).readAsBytes();
      await notifier.uploadPdf(bytes, file.name);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF okunamadi: $e')));
    }
  }

  Future<void> _pickAndUploadWord(BuildContext context, UploadNotifier notifier) async {
    if (!await _ensurePdfCredit(context)) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['docx'], withData: true);
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null || file == null) return;
    try {
      final text = _extractTextFromDocx(bytes);
      if (text.isEmpty) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word dosyasindan metin cikarilamadi'))); return; }
      await _deductPdfCredit();
      await notifier.uploadWordAsText(text, file.name);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Word islenemedi: $e')));
    }
  }

  String _extractTextFromDocx(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentXml = archive.findFile('word/document.xml');
      if (documentXml == null) return '';
      final content = utf8.decode(documentXml.content as List<int>);
      final textPattern = RegExp(r'<w:t[^>]*>([^<]+)</w:t>');
      return textPattern.allMatches(content).map((m) => m.group(1) ?? '').join(' ');
    } catch (e) { return ''; }
  }
}

// ═══════════════════════════════════════════════════
//  Belge Karti — 2D Pixel Game Art
// ═══════════════════════════════════════════════════

class _DocumentCard extends ConsumerWidget {
  const _DocumentCard({required this.note, required this.index});
  final NoteModel note;
  final int index;

  static const _colors = [PxDecor.blue, PxDecor.teal, PxDecor.purple, PxDecor.orange, PxDecor.green];
  static const _darks = [PxDecor.blueDark, PxDecor.tealDark, PxDecor.purpleDark, PxDecor.orangeDark, PxDecor.greenDark];
  static const _icons = [Icons.description_rounded, Icons.article_rounded, Icons.auto_stories_rounded, Icons.book_rounded, Icons.note_rounded];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    final color = _colors[index % _colors.length];
    final dark = _darks[index % _darks.length];
    final icon = _icons[index % _icons.length];
    final daysDiff = DateTime.now().difference(note.createdAt).inDays;
    final dateLabel = daysDiff == 0 ? 'Bugun' : daysDiff == 1 ? 'Dun' : '${note.createdAt.day}.${note.createdAt.month}.${note.createdAt.year}';

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Pixel icon badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dark, width: 2),
                boxShadow: [BoxShadow(color: dark, offset: const Offset(0, 2), blurRadius: 0)],
              ),
              child: Stack(children: [
                Positioned(top: 3, left: 3, child: Container(width: 10, height: 4, decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(2)))),
                Center(child: Icon(icon, color: Colors.white, size: 20)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(note.subject.isNotEmpty ? note.subject : 'Isimsiz belge', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: note.subject.isNotEmpty ? px.text : px.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: px.accentBg(color), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(60), width: 1)),
                child: Text(dateLabel, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: color)),
              ),
            ])),
            // Actions
            _buildActions(context, ref, px, color, dark),
          ]),
          const SizedBox(height: 12),
          // Action chips
          Row(children: [
            _pxChip(px, 'Ozet', Icons.summarize_rounded, PxDecor.teal, () { Haptic.light(); context.go('/result/${note.id}'); }),
            const SizedBox(width: 8),
            _pxChip(px, 'Quiz', Icons.bolt_rounded, PxDecor.blue, () { Haptic.light(); context.push('/quiz/${note.id}'); }),
            const SizedBox(width: 8),
            _pxChip(px, 'Flashcard', Icons.style_rounded, PxDecor.purple, () { Haptic.light(); context.go('/result/${note.id}'); }),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Px px, Color color, Color dark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () async {
          Haptic.selection();
          final newName = await showDialog<String>(
            context: context,
            builder: (ctx) => _PixelEditDialog(currentName: note.subject),
          );
          if (newName != null && newName.isNotEmpty) {
            await ref.read(noteRepositoryProvider).updateNoteSubject(note.id, newName);
            ref.invalidate(_allNotesProvider);
            ref.invalidate(recentNotesProvider);
          }
        },
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: px.border, width: 1.5)),
          child: Icon(Icons.edit_rounded, size: 14, color: px.textMuted),
        ),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () async {
          Haptic.selection();
          final confirm = await PixelConfirmDialog.show(
            context,
            icon: Icons.delete_forever_rounded,
            iconColor: PxDecor.red,
            title: 'Belgeyi Sil?',
            message: 'Bu islem geri alinamaz.\nBelgeyi silmek istiyor musun?',
            confirmLabel: 'Sil',
            cancelLabel: 'Iptal',
          );
          if (confirm) {
            await ref.read(noteRepositoryProvider).deleteNote(note.id);
            ref.invalidate(_allNotesProvider);
            ref.invalidate(recentNotesProvider);
          }
        },
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: px.accentBg(PxDecor.red), borderRadius: BorderRadius.circular(8), border: Border.all(color: PxDecor.red.withAlpha(80), width: 1.5)),
          child: Icon(Icons.delete_outline_rounded, size: 14, color: PxDecor.red),
        ),
      ),
    ]);
  }

  static Widget _pxChip(Px px, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: px.accentBg(color),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Pixel-style edit dialog ──
class _PixelEditDialog extends StatefulWidget {
  const _PixelEditDialog({required this.currentName});
  final String currentName;
  @override
  State<_PixelEditDialog> createState() => _PixelEditDialogState();
}

class _PixelEditDialogState extends State<_PixelEditDialog> {
  late final TextEditingController _controller;
  @override
  void initState() { super.initState(); _controller = TextEditingController(text: widget.currentName); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: PxDecor.blue, borderRadius: const BorderRadius.vertical(top: Radius.circular(17)), boxShadow: [BoxShadow(color: PxDecor.blueDark, offset: const Offset(0, 3), blurRadius: 0)]),
            child: const Column(children: [
              Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
              SizedBox(height: 6),
              Text('Belge Ismini Degistir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2)),
                child: TextField(
                  controller: _controller, autofocus: true,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: px.text),
                  decoration: InputDecoration(hintText: 'Yeni isim', hintStyle: TextStyle(color: px.textMuted), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () { Haptic.light(); Navigator.pop(context); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: px.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 2), blurRadius: 0)]),
                    child: Center(child: Text('Iptal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.text))),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () { Haptic.medium(); Navigator.pop(context, _controller.text.trim()); },
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

