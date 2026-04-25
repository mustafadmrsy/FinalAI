import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants/app_constants.dart';
import '../constants/app_secrets.dart';

class GeminiService {
  static GenerativeModel _createModel() {
    return GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: AppSecrets.geminiApiKey,
    );
  }

  static GenerativeModel _createModelWithName(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: AppSecrets.geminiApiKey,
    );
  }

  static Future<GenerateContentResponse> _generateWithFallback(
    List<Content> content,
  ) async {
    final candidates = <String>{
      AppConstants.geminiModel,
      'gemini-flash-lite-latest',
      'gemini-2.5-pro',
      'gemini-flash-latest',
      'gemini-pro-latest',
      'gemini-2.0-flash',
    }.toList();

    Object? lastError;
    for (final modelName in candidates) {
      try {
        final model = _createModelWithName(modelName);
        return await model.generateContent(content);
      } catch (e) {
        lastError = e;
        final msg = e.toString();
        final deniedAccess = msg.contains('Your project has been denied access') ||
            msg.contains('PERMISSION_DENIED');
        if (deniedAccess) {
          throw Exception(
            'Gemini API erişimi bu Google projesi için engellenmiş. '
            'Çözüm: AI Studio üzerinden farklı bir Google hesabı/proje ile yeni API key oluşturun '
            've uygulamada kullanın. (Hata: Your project has been denied access)');
        }
        final isModelMissing = msg.contains('is not found') || msg.contains('not supported');
        final isUnavailable = msg.contains('503') ||
            msg.contains('UNAVAILABLE') ||
            msg.contains('high demand') ||
            msg.contains('experiencing high demand');

        if (isUnavailable) {
          // Transient capacity issue: small backoff then try next model.
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        if (!isModelMissing) {
          rethrow;
        }
      }
    }

    throw Exception(
      'Gemini model not available. Tried: ${candidates.join(', ')}. '
      'Set --dart-define=GEMINI_MODEL=<model>. Last error: ${lastError ?? ''}',
    );
  }

  static Future<Map<String, dynamic>> processPdf(List<int> pdfBytes) async {
    if (AppSecrets.geminiApiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Provide via --dart-define.');
    }
    final bytes = Uint8List.fromList(pdfBytes);
    final prompt = '''
Sen bir sınav hazırlık asistanısın. Türkçe yanıt ver.

Bu PDF'i analiz et ve aşağıdaki JSON formatında SADECE JSON döndür, başka hiçbir şey yazma:

{
  "summary_short": ["madde1", "madde2", "madde3", "madde4", "madde5"],
  "summary_long": "konunun detaylı açıklaması",
  "questions": [
    {
      "question": "soru metni",
      "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
      "correct_index": 1,
      "explanation": "neden bu cevap doğru"
    }
  ],
  "flashcards": [
    {"front": "kavram", "back": "açıklama"}
  ],
  "likely_exam_questions": ["olası sınav sorusu 1", "olası sınav sorusu 2"]
}

10 soru ve 10 flashcard üret.
''';

    final response = await _generateWithFallback([
      Content.multi([
        DataPart('application/pdf', bytes),
        TextPart(prompt),
      ])
    ]);

    final text = response.text ?? '{}';
    return _parseJson(text);
  }

  static Future<String> generateStudyPlan({
    required String subject,
    required int daysLeft,
    required List<String> topics,
  }) async {
    if (AppSecrets.geminiApiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Provide via --dart-define.');
    }
    final prompt = '''
Öğrenci için Türkçe çalışma planı oluştur.
Ders: $subject
Kalan gün: $daysLeft
Konular: ${topics.join(', ')}

Gün gün plan yap. JSON formatında döndür:
{
  "days": [
    {"day": 1, "tasks": ["görev1", "görev2"], "focus": "konu adı"}
  ],
  "tip": "motivasyon mesajı"
}
''';

    final response = await _generateWithFallback([Content.text(prompt)]);
    return response.text ?? '';
  }

  static Map<String, dynamic> _parseJson(String text) {
    try {
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
