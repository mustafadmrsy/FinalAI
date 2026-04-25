import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  static Future<File> generateNotePdf({
    required String subject,
    required String summaryShort,
    required String summaryLong,
    required List<dynamic> questions,
    required List<dynamic> flashcards,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(subject),
          pw.SizedBox(height: 24),
          _buildSection('📝 Kısa Özet', summaryShort),
          pw.SizedBox(height: 24),
          _buildSection('📖 Detaylı Özet', summaryLong),
          pw.SizedBox(height: 32),
          _buildQuizSection(questions),
          pw.SizedBox(height: 32),
          _buildFlashcardSection(flashcards),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/finalai_${subject.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(String subject) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromHex('#667eea'), PdfColor.fromHex('#764ba2')],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FinalAI',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            subject,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#667eea'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#f5f5f5'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildQuizSection(List<dynamic> questions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '🧠 Quiz Soruları',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#667eea'),
          ),
        ),
        pw.SizedBox(height: 12),
        ...questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = (entry.value as Map).cast<String, dynamic>();
          final question = q['question'] as String? ?? '';
          final options = (q['options'] as List?)?.cast<String>() ?? [];
          final correctIndex = q['correctIndex'] as int? ?? 0;
          final explanation = q['explanation'] as String? ?? '';

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#e0e0e0')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Soru ${i + 1}: $question',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                ...options.asMap().entries.map((opt) {
                  final isCorrect = opt.key == correctIndex;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          isCorrect ? '✓' : '○',
                          style: pw.TextStyle(
                            color: isCorrect ? PdfColors.green : PdfColors.grey,
                            fontWeight: isCorrect ? pw.FontWeight.bold : pw.FontWeight.normal,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            opt.value,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: isCorrect ? PdfColors.green800 : PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (explanation.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#f0f9ff'),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Açıklama: $explanation',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFlashcardSection(List<dynamic> flashcards) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '🎴 Flashcardlar',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#667eea'),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: flashcards.map((fc) {
            final card = (fc as Map).cast<String, dynamic>();
            final front = card['front'] as String? ?? '';
            final back = card['back'] as String? ?? '';

            return pw.Container(
              width: 250,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColor.fromHex('#4facfe'), PdfColor.fromHex('#00f2fe')],
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Soru',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    front,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Cevap',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    back,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Future<void> shareOrSavePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }
}
