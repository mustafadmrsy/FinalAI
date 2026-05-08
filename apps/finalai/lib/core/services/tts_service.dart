import 'dart:math';

import 'package:flutter_tts/flutter_tts.dart';

// ═══════════════════════════════════════════════════════
//  AVATAR — dil derslerinde farkli karakterler
// ═══════════════════════════════════════════════════════

class LessonAvatar {
  const LessonAvatar({required this.emoji, required this.name, required this.gender});
  final String emoji;
  final String name;
  final String gender; // 'male' | 'female'

  double get pitch => gender == 'female' ? 1.3 : 0.85;
  double get rate => gender == 'female' ? 0.48 : 0.42;

  static const _all = <LessonAvatar>[
    LessonAvatar(emoji: '👩‍🏫', name: 'Hoca Hanim', gender: 'female'),
    LessonAvatar(emoji: '👨‍🏫', name: 'Hoca Bey', gender: 'male'),
    LessonAvatar(emoji: '🦉', name: 'Bilge Baykus', gender: 'male'),
    LessonAvatar(emoji: '🐱', name: 'Minnos', gender: 'female'),
    LessonAvatar(emoji: '🧙‍♂️', name: 'Usta', gender: 'male'),
    LessonAvatar(emoji: '👵', name: 'Buyukanne', gender: 'female'),
    LessonAvatar(emoji: '🤖', name: 'Robo', gender: 'male'),
    LessonAvatar(emoji: '🦊', name: 'Tilki', gender: 'female'),
    LessonAvatar(emoji: '🐻', name: 'Ayi', gender: 'male'),
    LessonAvatar(emoji: '👩‍🚀', name: 'Astronot', gender: 'female'),
  ];

  static final _rng = Random();

  /// stepIndex bazli deterministik ama cesitli avatar sec
  static LessonAvatar forStep(int stepIndex) => _all[stepIndex % _all.length];

  /// Rastgele avatar
  static LessonAvatar random() => _all[_rng.nextInt(_all.length)];
}

// ═══════════════════════════════════════════════════════
//  TTS SERVICE — avatar-aware ses
// ═══════════════════════════════════════════════════════

/// Text-to-Speech service for language learning tasks (Duolingo-style)
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  bool _initialized = false;
  String _currentLang = 'en-US';

  static const _langMap = <String, String>{
    'ingilizce': 'en-US',
    'english': 'en-US',
    'almanca': 'de-DE',
    'german': 'de-DE',
    'deutsch': 'de-DE',
    'fransizca': 'fr-FR',
    'french': 'fr-FR',
    'japonca': 'ja-JP',
    'japanese': 'ja-JP',
    'ispanyolca': 'es-ES',
    'spanish': 'es-ES',
    'italyanca': 'it-IT',
    'italian': 'it-IT',
    'korece': 'ko-KR',
    'korean': 'ko-KR',
    'cince': 'zh-CN',
    'chinese': 'zh-CN',
    'arapca': 'ar-SA',
    'arabic': 'ar-SA',
    'rusca': 'ru-RU',
    'russian': 'ru-RU',
  };

  Future<void> init() async {
    if (_initialized) return;
    _tts = FlutterTts();
    await _tts!.setVolume(1.0);
    await _tts!.setSpeechRate(0.45);
    await _tts!.setPitch(1.0);
    _initialized = true;
  }

  /// Set language based on subject name
  void setLanguageForSubject(String subject) {
    final s = subject.toLowerCase();
    for (final entry in _langMap.entries) {
      if (s.contains(entry.key)) {
        _currentLang = entry.value;
        return;
      }
    }
    _currentLang = 'en-US';
  }

  /// Speak text in current language
  Future<void> speak(String text) async {
    await init();
    await _tts!.setLanguage(_currentLang);
    await _tts!.speak(text);
  }

  /// Speak with specific language code
  Future<void> speakWithLang(String text, String langCode) async {
    await init();
    await _tts!.setLanguage(langCode);
    await _tts!.setPitch(1.0);
    await _tts!.setSpeechRate(0.45);
    await _tts!.speak(text);
  }

  /// Speak with avatar voice characteristics
  Future<void> speakAsAvatar(String text, String langCode, LessonAvatar avatar) async {
    await init();
    await _tts!.setLanguage(langCode);
    await _tts!.setPitch(avatar.pitch);
    await _tts!.setSpeechRate(avatar.rate);
    await _tts!.speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _tts?.stop();
  }

  /// Get TTS language code for a subject
  static String langCodeForSubject(String subject) {
    final s = subject.toLowerCase();
    for (final entry in _langMap.entries) {
      if (s.contains(entry.key)) return entry.value;
    }
    return 'en-US';
  }

  void dispose() {
    _tts?.stop();
  }
}
