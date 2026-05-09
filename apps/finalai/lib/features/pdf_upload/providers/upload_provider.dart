import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/repositories/note_repository.dart';
import '../../../core/repositories/stats_repository.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../notifications/services/notification_service.dart';

enum UploadStatus { idle, uploading, processing, done, error }

class UploadViewState {
  const UploadViewState({
    required this.status,
    required this.message,
    required this.progress,
    this.resultId,
    this.errorMessage,
    required this.subject,
    this.lastAiTokensUsed,
    this.aiTokensRemainingToday,
  });

  final UploadStatus status;
  final String message;
  // 0.0 - 1.0
  final double progress;
  final String? resultId;
  final String? errorMessage;
  final String subject;
  final int? lastAiTokensUsed;
  final int? aiTokensRemainingToday;

  bool get isBusy => status == UploadStatus.uploading || status == UploadStatus.processing;

  UploadViewState copyWith({
    UploadStatus? status,
    String? message,
    double? progress,
    String? resultId,
    String? errorMessage,
    String? subject,
    int? lastAiTokensUsed,
    int? aiTokensRemainingToday,
  }) {
    return UploadViewState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      resultId: resultId ?? this.resultId,
      errorMessage: errorMessage,
      subject: subject ?? this.subject,
      lastAiTokensUsed: lastAiTokensUsed ?? this.lastAiTokensUsed,
      aiTokensRemainingToday: aiTokensRemainingToday ?? this.aiTokensRemainingToday,
    );
  }

  static const initial = UploadViewState(
    status: UploadStatus.idle,
    message: '',
    progress: 0,
    subject: '',
  );
}

class UploadNotifier extends StateNotifier<UploadViewState> {
  UploadNotifier(this._noteRepository, this._statsRepository) : super(UploadViewState.initial) {
    // Fire-and-forget initial token budget load.
    _refreshTokenBudget();
  }

  final NoteRepository _noteRepository;
  final StatsRepository _statsRepository;

  static const int _dailyTokenLimitFree = 20000;

  Future<void> _ensureCanUploadToday() async {
    final count = await StorageService.getTodayUploadCount();
    if (count >= AppConstants.freeUploadLimit) {
      throw Exception('Daily upload limit reached (${AppConstants.freeUploadLimit}).');
    }
  }

  Future<void> _onPdfUploaded() async {
    await StorageService.incrementTodayUploadCount();

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    final profile = await _statsRepository.getUserProfile();
    final lastUpload = profile == null ? null : DateTime.tryParse(profile['last_upload_date']?.toString() ?? '');
    final lastUploadDay = lastUpload == null ? null : DateTime(lastUpload.year, lastUpload.month, lastUpload.day);
    final currentDaily = (profile?['daily_upload_count'] as int?) ?? 0;
    final nextDaily = (lastUploadDay == null || lastUploadDay != day) ? 1 : (currentDaily + 1);

    await _statsRepository.upsertUserProfileFields({
      'daily_upload_count': nextDaily,
      'last_upload_date': day.toIso8601String(),
    });

    final stats = await _statsRepository.getUserStats();
    final currentTotal = (stats['total_pdfs'] as int?) ?? 0;
    await _statsRepository.upsertUserStats({
      'total_pdfs': currentTotal + 1,
    });
  }

  Future<void> _refreshTokenBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final keyDate = '${today.year}-${today.month}-${today.day}';
    final lastDate = prefs.getString('ai_tokens_date');
    if (lastDate != keyDate) {
      await prefs.setString('ai_tokens_date', keyDate);
      await prefs.setInt('ai_tokens_used', 0);
    }
    final used = prefs.getInt('ai_tokens_used') ?? 0;
    final remaining = (_dailyTokenLimitFree - used).clamp(0, _dailyTokenLimitFree);
    state = state.copyWith(aiTokensRemainingToday: remaining);
  }

  Future<int> _updateDailyTokensUsed(int delta) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final keyDate = '${today.year}-${today.month}-${today.day}';
    final lastDate = prefs.getString('ai_tokens_date');
    if (lastDate != keyDate) {
      await prefs.setString('ai_tokens_date', keyDate);
      await prefs.setInt('ai_tokens_used', 0);
    }
    final used = (prefs.getInt('ai_tokens_used') ?? 0) + delta;
    await prefs.setInt('ai_tokens_used', used);
    return used;
  }

  void reset() {
    state = UploadViewState.initial;
  }

  void setSubject(String value) {
    state = state.copyWith(subject: value);
  }

  Future<void> uploadWordAsText(String text, String fileName) async {
    try {
      await _ensureCanUploadToday();
      await _refreshTokenBudget();

      state = state.copyWith(
        status: UploadStatus.uploading,
        message: 'Word dosyası işleniyor...',
        errorMessage: null,
      );

      final path = await _noteRepository.uploadTextAsFile(text, fileName);
      try { await NotificationService.notifyPdfUploaded(fileName: fileName); } catch (_) {}

      state = state.copyWith(
        status: UploadStatus.processing,
        message: 'AI ile analiz ediliyor... (Uzun dosyalar için birkaç dakika sürebilir)',
      );

      final result = await AiService.processText(text);

      final usedTokens = result.usage?.totalTokens;
      if (usedTokens != null) {
        final usedToday = await _updateDailyTokensUsed(usedTokens);
        final remaining = (_dailyTokenLimitFree - usedToday).clamp(0, _dailyTokenLimitFree);
        state = state.copyWith(
          lastAiTokensUsed: usedTokens,
          aiTokensRemainingToday: remaining,
        );
      }

      state = state.copyWith(message: 'Sorular hazırlanıyor...');
      state = state.copyWith(progress: 0.96);

      final id = await _noteRepository.saveNote(
        subject: state.subject.isEmpty ? 'Genel' : state.subject,
        filePath: path,
        summary: result.data,
      );

      await _onPdfUploaded();

      try { await NotificationService.notifyPdfSummaryReady(fileName: fileName); } catch (_) {}

      state = state.copyWith(
        status: UploadStatus.done,
        message: '',
        resultId: id,
      );
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        message: '',
        errorMessage: e.toString(),
      );
    }
  }

  /// Extract text from PDF bytes using Syncfusion (runs on device)
  String _extractTextFromPdf(List<int> bytes) {
    try {
      final document = PdfDocument(inputBytes: Uint8List.fromList(bytes));
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text.trim();
    } catch (e) {
      debugPrint('PDF text extraction failed: $e');
      return '';
    }
  }

  Future<void> uploadPdf(List<int> bytes, String fileName) async {
    try {
      await _ensureCanUploadToday();

      // Ensure token budget is visible immediately on the processing screen.
      await _refreshTokenBudget();

      state = state.copyWith(
        status: UploadStatus.uploading,
        message: 'PDF okunuyor...',
        progress: 0.02,
        errorMessage: null,
      );

      // Extract text from PDF on device (no need to send full PDF to server)
      final extractedText = _extractTextFromPdf(bytes);
      if (extractedText.isEmpty || extractedText.length < 50) {
        throw Exception('PDF\'den metin çıkarılamadı. Lütfen metin içeren bir PDF yükleyin.');
      }

      state = state.copyWith(
        progress: 0.15,
        message: 'PDF metni çıkarıldı, yükleniyor...',
      );

      final path = await _noteRepository.uploadPdf(bytes, fileName);
      try { await NotificationService.notifyPdfUploaded(fileName: fileName); } catch (_) {}

      state = state.copyWith(
        status: UploadStatus.processing,
        message: 'AI ile analiz ediliyor... (Birkaç dakika sürebilir)',
        progress: 0.25,
      );

      // Send only extracted text to backend (Claude) — not the full PDF
      final result = await AiService.processText(extractedText);

      state = state.copyWith(progress: 0.90);

      final usedTokens = result.usage?.totalTokens;
      if (usedTokens != null) {
        final usedToday = await _updateDailyTokensUsed(usedTokens);
        final remaining = (_dailyTokenLimitFree - usedToday).clamp(0, _dailyTokenLimitFree);
        state = state.copyWith(
          lastAiTokensUsed: usedTokens,
          aiTokensRemainingToday: remaining,
        );
      } else {
        await _refreshTokenBudget();
      }

      state = state.copyWith(message: 'Sorular hazırlanıyor...');

      final id = await _noteRepository.saveNote(
        subject: state.subject.isEmpty ? 'Genel' : state.subject,
        filePath: path,
        summary: result.data,
      );

      await _onPdfUploaded();
      try { await NotificationService.notifyPdfSummaryReady(fileName: fileName); } catch (_) {}

      state = state.copyWith(status: UploadStatus.done, message: '', resultId: id, progress: 1.0);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        message: '',
        progress: 0,
        errorMessage: e.toString(),
      );
    }
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadViewState>(
  (ref) => UploadNotifier(
    ref.watch(noteRepositoryProvider),
    ref.watch(statsRepositoryProvider),
  ),
);
