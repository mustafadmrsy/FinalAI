import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AiUsage {
  const AiUsage({required this.inputTokens, required this.outputTokens});

  final int inputTokens;
  final int outputTokens;

  int get totalTokens => inputTokens + outputTokens;

  static AiUsage? fromJson(Object? value) {
    if (value is! Map) return null;
    final input = (value['input_tokens'] as int?) ?? 0;
    final output = (value['output_tokens'] as int?) ?? 0;
    return AiUsage(inputTokens: input, outputTokens: output);
  }
}

class AiPdfResult {
  const AiPdfResult({required this.data, this.usage});

  final Map<String, dynamic> data;
  final AiUsage? usage;
}

class AiService {
  AiService._();

  static const String _baseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static Future<AiPdfResult> processPdfWithProgress(
    List<int> pdfBytes, {
    required void Function(double percent, String? message) onProgress,
  }) async {
    Future<AiPdfResult> fallbackNonStream() async {
      // Locally simulate progress while waiting for the non-stream endpoint.
      var p = 32.0;
      final timer = Timer.periodic(const Duration(seconds: 4), (_) {
        p = (p + 1).clamp(32.0, 92.0);
        onProgress(p, 'AI analiz ediyor');
      });
      try {
        final res = await processPdf(pdfBytes);
        onProgress(96, 'Sonuç hazırlanıyor');
        return res;
      } finally {
        timer.cancel();
      }
    }

    final client = http.Client();
    try {
      final uri = Uri.parse('$_baseUrl/ai/process-pdf-stream');
      final req = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Accept'] = 'text/event-stream'
        ..body = jsonEncode({'pdfBase64': base64Encode(pdfBytes)});

      final streamed = await client.send(req).timeout(
        const Duration(minutes: 20),
        onTimeout: () => throw TimeoutException('PDF işleme zaman aşımına uğradı (20 dakika)'),
      );

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final body = await streamed.stream.bytesToString();
        throw Exception('AI request failed (${streamed.statusCode}): $body');
      }

      AiPdfResult? finalResult;
      String buffer = '';

      DateTime lastDataAt = DateTime.now();
      const inactivity = Duration(seconds: 18);

      final completer = Completer<AiPdfResult>();

      late final StreamSubscription<String> sub;
      Timer? watchdog;

      void stopWatchdog() {
        watchdog?.cancel();
        watchdog = null;
      }

      void startWatchdog() {
        watchdog ??= Timer.periodic(const Duration(seconds: 2), (_) async {
          if (completer.isCompleted) return;
          final idle = DateTime.now().difference(lastDataAt);
          if (idle >= inactivity) {
            stopWatchdog();
            try {
              await sub.cancel();
            } catch (_) {}
            try {
              client.close();
            } catch (_) {}
            onProgress(34, 'Bağlantı yenileniyor...');
            try {
              final fb = await fallbackNonStream();
              if (!completer.isCompleted) completer.complete(fb);
            } catch (e, st) {
              if (!completer.isCompleted) completer.completeError(e, st);
            }
          }
        });
      }

      startWatchdog();

      sub = streamed.stream.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;
          while (true) {
            final idx = buffer.indexOf('\n\n');
            if (idx == -1) break;
            final rawEvent = buffer.substring(0, idx);
            buffer = buffer.substring(idx + 2);

            // Ignore empty events and keep-alive comment lines like ": ping".
            // IMPORTANT: do NOT treat these as activity, otherwise the watchdog never triggers
            // when the server stalls after reaching ~92% but keeps sending pings.
            if (rawEvent.trim().isEmpty || rawEvent.startsWith(':')) continue;

            try {
              String? eventName;
              final dataLines = <String>[];
              for (final line in rawEvent.split('\n')) {
                if (line.startsWith('event:')) {
                  eventName = line.substring('event:'.length).trim();
                } else if (line.startsWith('data:')) {
                  dataLines.add(line.substring('data:'.length).trim());
                }
              }

              final dataText = dataLines.join('\n');
              if (dataText.isEmpty) continue;
              final payload = jsonDecode(dataText) as Map<String, dynamic>;

              if (eventName == 'progress') {
                // Only mark activity after we successfully parsed a real SSE event.
                lastDataAt = DateTime.now();
                final percent = (payload['percent'] as num?)?.toDouble() ?? 0;
                final msg = payload['message'] as String?;
                onProgress(percent, msg);
              } else if (eventName == 'result') {
                // Only mark activity after we successfully parsed a real SSE event.
                lastDataAt = DateTime.now();
                final serverJson = payload['json'];
                final normalized = payload['normalized'];
                final text = (payload['text'] as String?) ?? '{}';
                final usage = AiUsage.fromJson(payload['usage']);

                Map<String, dynamic> parsed;
                if (serverJson != null) {
                  parsed = (serverJson as Map).cast<String, dynamic>();
                } else if (normalized is String && normalized.isNotEmpty) {
                  parsed = _parseJson(normalized);
                } else {
                  parsed = _parseJson(text);
                }

                finalResult = AiPdfResult(data: parsed, usage: usage);
                if (!completer.isCompleted) completer.complete(finalResult!);
              } else if (eventName == 'error') {
                // Only mark activity after we successfully parsed a real SSE event.
                lastDataAt = DateTime.now();
                throw Exception(payload['error']?.toString() ?? 'AI stream error');
              }
            } catch (_) {
              continue;
            }
          }
        },
        onError: (e, st) async {
          stopWatchdog();
          if (completer.isCompleted) return;
          onProgress(34, 'Bağlantı yenileniyor...');
          try {
            final fb = await fallbackNonStream();
            if (!completer.isCompleted) completer.complete(fb);
          } catch (e2, st2) {
            if (!completer.isCompleted) completer.completeError(e2, st2);
          }
        },
        onDone: () async {
          stopWatchdog();
          if (completer.isCompleted) return;
          if (finalResult != null) {
            completer.complete(finalResult!);
            return;
          }
          onProgress(34, 'Bağlantı yenileniyor...');
          try {
            final fb = await fallbackNonStream();
            if (!completer.isCompleted) completer.complete(fb);
          } catch (e, st) {
            if (!completer.isCompleted) completer.completeError(e, st);
          }
        },
        cancelOnError: true,
      );

      final out = await completer.future;
      stopWatchdog();
      try {
        await sub.cancel();
      } catch (_) {}
      return out;
    } on http.ClientException {
      onProgress(34, 'Bağlantı yenileniyor...');
      return await fallbackNonStream();
    } catch (_) {
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<AiPdfResult> processText(String inputText) async {
    final uri = Uri.parse('$_baseUrl/ai/process-text');

    final client = HttpClient();
    try {
      final req = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 25), onTimeout: () {
        throw TimeoutException(
          'AI sunucusuna bağlanılamadı (timeout). URL: $_baseUrl',
        );
      });
      req.headers.contentType = ContentType.json;

      final body = jsonEncode({'text': inputText});
      req.add(utf8.encode(body));

      final res = await req.close().timeout(const Duration(minutes: 10), onTimeout: () {
        throw TimeoutException(
          'AI yanıtı beklenirken timeout. URL: $_baseUrl',
        );
      });
      final resBody = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('AI request failed (${res.statusCode}): $resBody');
      }

      final decoded = jsonDecode(resBody) as Map<String, dynamic>;
      final serverJson = decoded['json'];
      final normalized = decoded['normalized'];
      final text = (decoded['text'] as String?) ?? '{}';
      final usage = AiUsage.fromJson(decoded['usage']);

      Map<String, dynamic> parsed;
      if (serverJson != null) {
        parsed = (serverJson as Map).cast<String, dynamic>();
      } else if (normalized != null && normalized is String) {
        try {
          parsed = (jsonDecode(normalized) as Map).cast<String, dynamic>();
        } catch (_) {
          throw Exception('JSON parse hatası: $normalized');
        }
      } else {
        try {
          parsed = (jsonDecode(text) as Map).cast<String, dynamic>();
        } catch (_) {
          throw Exception('JSON parse hatası: $text');
        }
      }

      return AiPdfResult(data: parsed, usage: usage);
    } finally {
      client.close();
    }
  }

  static Future<AiPdfResult> processPdf(List<int> pdfBytes) async {
    // Use a custom client with longer timeout
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/ai/process-pdf'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'pdfBase64': base64Encode(pdfBytes)});
      
      final streamedResponse = await client.send(request).timeout(
        const Duration(minutes: 15),
        onTimeout: () => throw TimeoutException('PDF işleme zaman aşımına uğradı (15 dakika)'),
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI request failed (${response.statusCode}): ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final serverJson = decoded['json'];
      final normalized = decoded['normalized'];
      final text = (decoded['text'] as String?) ?? '{}';
      final usage = AiUsage.fromJson(decoded['usage']);
      
      if (serverJson is Map) {
        return AiPdfResult(
          data: serverJson.cast<String, dynamic>(),
          usage: usage,
        );
      }
      if (normalized is String && normalized.isNotEmpty) {
        return AiPdfResult(data: _parseJson(normalized), usage: usage);
      }
      return AiPdfResult(data: _parseJson(text), usage: usage);
    } finally {
      client.close();
    }
  }

  static Map<String, dynamic> _parseJson(String text) {
    String clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    if (!clean.startsWith('{') && clean.startsWith('"')) {
      clean = '{${clean}}';
    }
    // Remove common trailing commas before } or ]
    clean = clean.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      // Best-effort: extract the first top-level JSON object from the response.
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final slice = clean.substring(start, end + 1).trim();
        try {
          return jsonDecode(slice) as Map<String, dynamic>;
        } catch (_) {
          // fallthrough
        }
      }
      throw FormatException('AI JSON parse failed. Raw response: ${clean.length > 600 ? clean.substring(0, 600) : clean}');
    }
  }
}
