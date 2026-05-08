import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Speech-to-Text service for pronunciation tasks (Duolingo-style)
class SttService {
  SttService._();
  static final SttService instance = SttService._();

  stt.SpeechToText? _speech;
  bool _initialized = false;
  bool _available = false;

  Future<bool> init() async {
    if (_initialized) return _available;
    _speech = stt.SpeechToText();
    try {
      _available = await _speech!.initialize(
        onError: (err) {},
        onStatus: (status) {},
      );
    } catch (_) {
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  bool get isAvailable => _available;
  bool get isListening => _speech?.isListening ?? false;

  /// Start listening — partial results aninda callback ile gelir
  Future<void> listen({
    required String langCode,
    required void Function(String text, bool isFinal) onResult,
    Duration? listenFor,
  }) async {
    if (!_available) {
      final ok = await init();
      if (!ok) return;
    }
    if (_speech!.isListening) {
      await _speech!.stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _speech!.listen(
      localeId: langCode,
      listenFor: listenFor ?? const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stop() async {
    try { await _speech?.stop(); } catch (_) {}
  }

  /// Fuzzy match: Duolingo-style lenient comparison
  /// Returns similarity score 0.0 - 1.0
  static double similarity(String a, String b) {
    final na = _normalize(a);
    final nb = _normalize(b);
    if (na == nb) return 1.0;
    if (na.isEmpty || nb.isEmpty) return 0.0;

    // Kelime bazli kontrol: spoken expected'i iciyor mu?
    if (na.contains(nb) || nb.contains(na)) return 0.90;

    // Levenshtein distance based similarity
    final dist = _levenshtein(na, nb);
    final maxLen = na.length > nb.length ? na.length : nb.length;
    return 1.0 - (dist / maxLen);
  }

  /// Is pronunciation "close enough"? (>= 50% match — very lenient like Duolingo)
  static bool isCloseEnough(String spoken, String expected) {
    if (spoken.trim().isEmpty) return false;
    return similarity(spoken, expected) >= 0.50;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  void dispose() {
    _speech?.stop();
    _speech?.cancel();
  }
}
