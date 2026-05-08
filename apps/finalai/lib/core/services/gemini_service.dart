import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants/app_constants.dart';
import '../constants/app_secrets.dart';

class GeminiService {
  static int get apiKeyLength => AppSecrets.geminiApiKey.length;

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

  /// Generate placement test questions for a specific subject.
  /// Returns a list of 8 questions (easy → medium → hard) as JSON.
  static Future<List<Map<String, dynamic>>> generatePlacementQuestions({
    required String subject,
    String? goal,
    int? dailyMinutes,
  }) async {
    if (AppSecrets.geminiApiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Provide via --dart-define.');
    }

    final seed = DateTime.now().millisecondsSinceEpoch % 100000;
    final prompt = '''
Sen bir eğitim uzmanısın. "$subject" alanında seviye belirleme testi hazırlıyorsun.
${goal != null ? 'Öğrencinin hedefi: $goal.' : ''}
${dailyMinutes != null ? 'Günlük çalışma süresi: $dailyMinutes dakika.' : ''}
Rastgelelik tohumu: $seed

GÖREV: "$subject" konusunda TAM 8 adet çoktan seçmeli soru üret.

ZORLUK DAĞILIMI (sırayla):
- İlk 3 soru: "easy" — temel kavramlar, tanımlar, basit bilgi
- Sonraki 3 soru: "medium" — uygulama, analiz, orta seviye problem
- Son 2 soru: "hard" — ileri düzey, sentez, zor problem çözme

KURALLAR:
1) Her soru "$subject" konusuna ÖZGÜ olmalı. Genel öğrenme teorisi sorusu SORMA.
2) 4 seçenek olmalı. Doğru cevap her zaman farklı index'te olsun (0-3 arası dengeli dağıt).
3) Yanıltıcılar mantıklı olmalı — rastgele/saçma seçenek koyma.
4) Soru metni açık, net ve Türkçe olmalı.
5) Her soru birbirinden farklı alt konu/kavramı test etmeli.

ÇIKTI: Sadece JSON dizisi döndür, başka hiçbir şey yazma.
[
  {"q": "soru metni", "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"], "answer": 0, "difficulty": "easy"},
  ...
]

TAM 8 soru üret. JSON dışında hiçbir şey yazma.
''';

    final response = await _generateWithFallback([Content.text(prompt)]);
    final text = response.text ?? '[]';
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final decoded = jsonDecode(clean);
      if (decoded is List && decoded.length >= 4) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    throw Exception('AI placement question parse failed');
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
