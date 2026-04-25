import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/pdf_export_service.dart';
import '../providers/note_detail_provider.dart';
import '../widgets/summary_tab.dart';
import '../widgets/quiz_tab.dart';
import '../widgets/flashcard_tab.dart';

class AiResultScreen extends ConsumerStatefulWidget {
  const AiResultScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final noteAsync = ref.read(noteDetailProvider(widget.noteId));
      final note = noteAsync.value;
      if (note == null) throw Exception('Not yüklenemedi');

      final subject = note['subject'] as String? ?? 'Not';
      final summaryShort = note['summary_short'] as String? ?? '';
      final summaryLong = note['summary_long'] as String? ?? '';
      final questions = (note['questions'] as List?)?.cast<dynamic>() ?? [];
      final flashcards = (note['flashcards'] as List?)?.cast<dynamic>() ?? [];

      final pdfFile = await PdfExportService.generateNotePdf(
        subject: subject,
        summaryShort: summaryShort,
        summaryLong: summaryLong,
        questions: questions,
        flashcards: flashcards,
      );

      await PdfExportService.shareOrSavePdf(pdfFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF başarıyla oluşturuldu!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF oluşturulamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sonuç'),
          actions: [
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting ? null : _exportPdf,
              tooltip: 'PDF olarak indir',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Özet'),
              Tab(text: 'Quiz'),
              Tab(text: 'Flashcard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SummaryTab(noteId: widget.noteId),
            QuizTab(noteId: widget.noteId),
            FlashcardTab(noteId: widget.noteId),
          ],
        ),
      ),
    );
  }
}
