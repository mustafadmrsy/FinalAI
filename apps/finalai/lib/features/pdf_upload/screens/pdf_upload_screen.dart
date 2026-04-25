import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:core_ui/core_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/providers/notes_provider.dart';
import '../providers/upload_provider.dart';

class PdfUploadScreen extends ConsumerWidget {
  const PdfUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    ref.listen(uploadProvider, (prev, next) {
      if (next.status == UploadStatus.processing && prev?.status != UploadStatus.processing) {
        context.go('/ai-processing');
      }
      if (next.status == UploadStatus.done && next.resultId != null) {
        ref.invalidate(recentNotesProvider);
        notifier.reset();
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Dosya Yükle')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Ders / Konu',
                hint: 'Örn: Fizik - Elektrik',
                onChanged: notifier.setSubject,
                prefixIcon: Icons.school_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Dosya Seç (PDF/Word)',
                icon: Icons.upload_file,
                isLoading: state.isBusy,
                onPressed: () => _showFileTypePicker(context, notifier),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _Body(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFileTypePicker(BuildContext context, UploadNotifier notifier) async {
    final fileType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dosya Türü Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: AppColors.primary),
              title: const Text('Word (.docx)'),
              onTap: () => Navigator.pop(ctx, 'docx'),
            ),
          ],
        ),
      ),
    );

    if (fileType == null) return;

    if (fileType == 'pdf') {
      await _pickAndUploadPdf(context, notifier);
    } else if (fileType == 'docx') {
      await _pickAndUploadWord(context, notifier);
    }
  }

  Future<void> _pickAndUploadPdf(BuildContext context, UploadNotifier notifier) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );

    final file = result?.files.single;
    if (file == null || file.path == null) return;

    try {
      final bytes = await File(file.path!).readAsBytes();
      await notifier.uploadPdf(bytes, file.name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF okunamadı: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadWord(BuildContext context, UploadNotifier notifier) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null || file == null) return;

    try {
      final text = _extractTextFromDocx(bytes);
      if (text.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Word dosyasından metin çıkarılamadı')),
          );
        }
        return;
      }

      await notifier.uploadWordAsText(text, file.name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Word dosyası işlenemedi: $e')),
        );
      }
    }
  }

  String _extractTextFromDocx(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentXml = archive.findFile('word/document.xml');
      if (documentXml == null) return '';

      final content = utf8.decode(documentXml.content as List<int>);
      final textPattern = RegExp(r'<w:t[^>]*>([^<]+)</w:t>');
      final matches = textPattern.allMatches(content);
      return matches.map((m) => m.group(1) ?? '').join(' ');
    } catch (e) {
      return '';
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final UploadViewState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == UploadStatus.processing || state.status == UploadStatus.uploading) {
      return _ProcessingIndicator(message: state.message);
    }

    if (state.status == UploadStatus.error) {
      return EmptyState(
        title: 'Bir hata oluştu',
        message: state.errorMessage,
        icon: Icons.error_outline,
      );
    }

    if (state.status == UploadStatus.done) {
      return EmptyState(
        title: 'Tamamlandı',
        message: 'Sonuç hazır: ${state.resultId}',
        icon: Icons.check_circle_outline,
      );
    }

    return const EmptyState(
      title: 'Dosya yükle',
      message: 'PDF veya Word dosyası seçerek özet, quiz ve flashcard oluşturabilirsin.',
      icon: Icons.upload_file_outlined,
    );
  }
}

class _ProcessingIndicator extends StatefulWidget {
  const _ProcessingIndicator({required this.message});

  final String message;

  @override
  State<_ProcessingIndicator> createState() => _ProcessingIndicatorState();
}

class _ProcessingIndicatorState extends State<_ProcessingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _elapsedSeconds = 0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    
    // Update elapsed time every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getEstimatedTime() {
    if (_elapsedSeconds < 30) {
      return 'Tahmini: 2-3 dakika';
    } else if (_elapsedSeconds < 60) {
      return 'Tahmini: 1-2 dakika daha';
    } else if (_elapsedSeconds < 120) {
      return 'Neredeyse bitti...';
    } else {
      return 'Büyük dosya işleniyor...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeText = minutes > 0 
        ? '${minutes}:${seconds.toString().padLeft(2, '0')}'
        : '${seconds}s';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated circular progress
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating gradient circle
                  RotationTransition(
                    turns: _animation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Inner white circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  // Icon
                  const Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              widget.message,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _getEstimatedTime(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Geçen süre: $timeText',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '💡 İpucu: Uzun PDF\'ler 2-5 dakika sürebilir',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
