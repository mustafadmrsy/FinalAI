import express from 'express';
import Anthropic from '@anthropic-ai/sdk';
import { jsonrepair } from 'jsonrepair';

import { requireEnv, processPdfCore, extractTextWithOcrFallback } from '../services/ai.service.js';
import { OCR_MIN_TEXT_CHARS, isLowQualityExtractedText, extractPdfTextFromBuffer, ocrPdfBufferToText } from '../services/pdf.service.js';
import { normalizeJsonText } from '../services/validation.service.js';

const router = express.Router();

/** Repair truncated JSON by closing all open brackets/braces in correct order. */
function repairTruncatedJson(text) {
  let clean = text;
  // Check if we're inside an unclosed string
  let inStr = false, escaped = false;
  for (let i = 0; i < clean.length; i++) {
    if (escaped) { escaped = false; continue; }
    if (clean[i] === '\\') { escaped = true; continue; }
    if (clean[i] === '"') inStr = !inStr;
  }
  if (inStr) clean += '"';
  // Remove trailing comma, colon or incomplete key
  clean = clean.replace(/[,:]\s*$/, '');
  // Track bracket/brace stack
  const stack = [];
  inStr = false;
  escaped = false;
  for (let i = 0; i < clean.length; i++) {
    if (escaped) { escaped = false; continue; }
    if (clean[i] === '\\') { escaped = true; continue; }
    if (clean[i] === '"') { inStr = !inStr; continue; }
    if (inStr) continue;
    if (clean[i] === '{') stack.push('}');
    if (clean[i] === '[') stack.push(']');
    if (clean[i] === '}' || clean[i] === ']') stack.pop();
  }
  return clean + stack.reverse().join('');
}

function sseWriteEvent(res, event, data) {
  try {
    if (res.writableEnded || res.destroyed) return;
    if (event) res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
    res.flush?.();
  } catch (_) {
    // ignore
  }
}

function sseWriteProgress(res, percent, message) {
  const p = Math.max(0, Math.min(100, Number(percent) || 0));
  sseWriteEvent(res, 'progress', { percent: p, message });
}

router.get('/models', async (req, res) => {
  try {
    const apiKey = requireEnv('ANTHROPIC_API_KEY');
    const client = new Anthropic({ apiKey });
    const models = await client.models.list();
    res.json(models);
  } catch (e) {
    const status = Number(e?.status ?? e?.statusCode ?? 500);
    const type = e?.error?.error?.type ?? e?.error?.type;
    const isOverloaded = status === 529 || type === 'overloaded_error';
    res.status(isOverloaded ? 503 : status).json({
      error: isOverloaded ? 'anthropic_overloaded' : (e?.message ?? String(e)),
      retryable: Boolean(isOverloaded),
      status: isOverloaded ? 503 : status,
      request_id: e?.request_id ?? e?.error?.request_id,
    });
  }
});

router.post('/process-pdf-stream', async (req, res) => {
  req.setTimeout(0);
  res.setTimeout(0);

  res.status(200);
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();

  const keepAlive = setInterval(() => {
    try {
      if (res.writableEnded || res.destroyed) {
        clearInterval(keepAlive);
        return;
      }
      res.write(': ping\n\n');
    } catch (_) {
      clearInterval(keepAlive);
    }
  }, 15000);

  let closed = false;
  let smoothTimer;

  res.on('close', () => {
    closed = true;
    console.log('[process-pdf-stream] client connection closed');
    clearInterval(keepAlive);
    if (smoothTimer) clearInterval(smoothTimer);
  });
  req.on('aborted', () => {
    closed = true;
    console.log('[process-pdf-stream] client request aborted');
    clearInterval(keepAlive);
    if (smoothTimer) clearInterval(smoothTimer);
  });

  try {
    const reqT0 = Date.now();
    const apiKey = requireEnv('ANTHROPIC_API_KEY');
    const maxTokensEnv = Number.parseInt(process.env.AI_MAX_TOKENS ?? '1024', 10);
    const maxTokens = Number.isFinite(maxTokensEnv) ? Math.max(maxTokensEnv, 8192) : 8192;
    const temperature = Number.parseFloat(process.env.AI_TEMPERATURE ?? '0.7');
    const preferredModel = process.env.AI_MODEL;

    const { pdfBase64 } = req.body ?? {};
    if (!pdfBase64 || typeof pdfBase64 !== 'string') {
      sseWriteEvent(res, 'error', { error: 'pdfBase64 is required' });
      res.end();
      return;
    }

    sseWriteProgress(res, 2, 'İstek alındı');
    sseWriteProgress(res, 8, 'PDF çözümleniyor');

    sseWriteProgress(res, 18, 'PDF metni çıkarılıyor');
    console.log('[process-pdf-stream] extraction start');

    let extractedText = '';
    let extractedPages = 0;
    try {
      const { extractedText: t, extractedPages: p } = await extractTextWithOcrFallback(pdfBase64, {
        onOcrProgress: ({ phase, page, total, pdfPage }) => {
          const base = phase === 'render' || phase === 'ocr' ? 22 : 22;
          const span = phase === 'render' || phase === 'ocr' ? 8 : 8;
          const ratio = total ? page / total : 0;
          const percent = base + Math.floor(span * ratio);
          const shown = pdfPage ?? page;
          const msg =
            phase === 'render'
              ? `OCR: PDF sayfa ${shown} (${page}/${total}) hazırlanıyor`
              : `OCR: PDF sayfa ${shown} (${page}/${total}) okunuyor`;
          sseWriteProgress(res, percent, msg);
        },
      });
      extractedText = t;
      extractedPages = p;
    } catch (_) {
      extractedText = '';
      extractedPages = 0;
    }

    console.log(
      `[process-pdf-stream] extraction done. pages=${extractedPages} textLen=${String(extractedText ?? '').length} dtMs=${Date.now() - reqT0}`
    );

    sseWriteProgress(res, 32, 'AI analizi başlatılıyor');

    let smooth = 32;
    smoothTimer = setInterval(() => {
      if (closed) return;
      smooth = Math.min(92, smooth + 1);
      console.log(`[process-pdf-stream] smooth tick: ${smooth}%`);
      sseWriteProgress(res, smooth, 'AI analiz ediyor');
    }, 4000);

    if (closed) return;
    const result = await processPdfCore({
      apiKey,
      preferredModel,
      temperature,
      maxTokens,
      pdfBase64,
      useCaching: true,
      pdfText: extractedText,
      pageCount: extractedPages,
    });

    console.log(
      `[process-pdf-stream] done. dtMs=${Date.now() - reqT0} model=${result?.model ?? 'unknown'} extractedTextLength=${result?.extractedTextLength ?? 0}`
    );

    clearInterval(smoothTimer);

    if (closed) return;
    sseWriteProgress(res, 96, 'Sonuç hazırlanıyor');
    sseWriteEvent(res, 'result', result);
    sseWriteProgress(res, 100, 'Tamamlandı');
    res.end();
  } catch (e) {
    console.error('process-pdf-stream error:', e);
    if (!closed) {
      const status = Number(e?.status ?? e?.statusCode ?? 500);
      const type = e?.error?.error?.type ?? e?.error?.type;
      const isOverloaded = status === 529 || type === 'overloaded_error';
      sseWriteEvent(res, 'error', {
        error: isOverloaded ? 'anthropic_overloaded' : (e?.message ?? String(e)),
        retryable: Boolean(isOverloaded),
        status: isOverloaded ? 503 : status,
        request_id: e?.request_id ?? e?.error?.request_id,
      });
      res.end();
    }
  } finally {
    clearInterval(keepAlive);
  }
});

router.post('/process-pdf', async (req, res) => {
  req.setTimeout(600000);
  res.setTimeout(600000);

  try {
    const apiKey = requireEnv('ANTHROPIC_API_KEY');
    const maxTokensEnv = Number.parseInt(process.env.AI_MAX_TOKENS ?? '1024', 10);
    const maxTokens = Number.isFinite(maxTokensEnv) ? Math.max(maxTokensEnv, 8192) : 8192;
    const temperature = Number.parseFloat(process.env.AI_TEMPERATURE ?? '0.7');
    const preferredModel = process.env.AI_MODEL;

    const { pdfBase64 } = req.body ?? {};
    if (!pdfBase64 || typeof pdfBase64 !== 'string') {
      return res.status(400).json({ error: 'pdfBase64 is required' });
    }

    // Extract text once and reuse the same core logic.
    let extractedText = '';
    let extractedPages = 0;
    let pdfBuffer;
    try {
      pdfBuffer = Buffer.from(pdfBase64, 'base64');
      const pdfData = await extractPdfTextFromBuffer(pdfBuffer);
      extractedText = (pdfData.text ?? '').toString();
      extractedPages = Number(pdfData.numpages ?? 0) || 0;
    } catch (e) {
      console.warn('PDF text extraction failed:', e?.message ?? String(e));
    }

    if (extractedText) extractedText = String(extractedText).replace(/\s+/g, ' ').trim();

    const forceOcr =
      !extractedText ||
      extractedText.length < OCR_MIN_TEXT_CHARS ||
      isLowQualityExtractedText(extractedText);

    if (forceOcr && pdfBuffer) {
      try {
        const ocr = await ocrPdfBufferToText(pdfBuffer, {});
        extractedText = ocr.text;
        extractedPages = ocr.pageCount;
        if (extractedText && extractedText.length < OCR_MIN_TEXT_CHARS) {
          const ocr2 = await ocrPdfBufferToText(pdfBuffer, { maxPages: Math.min(24, ocr.pageCount || 24) });
          if (ocr2?.text && ocr2.text.length > extractedText.length) extractedText = ocr2.text;
        }
      } catch (e) {
        console.warn('[process-pdf] OCR failed:', e?.message ?? String(e));
      }
    }

    const result = await processPdfCore({
      apiKey,
      preferredModel,
      temperature,
      maxTokens,
      pdfBase64,
      useCaching: false,
      pdfText: extractedText,
      pageCount: extractedPages,
    });

    return res.json(result);
  } catch (e) {
    const status = e?.statusCode ?? 500;
    res.status(status).json({ error: e?.message ?? String(e) });
  }
});

router.post('/process-text', async (req, res) => {
  req.setTimeout(600000);
  res.setTimeout(600000);

  try {
    const apiKey = requireEnv('ANTHROPIC_API_KEY');
    const maxTokensEnv = Number.parseInt(process.env.AI_MAX_TOKENS ?? '1024', 10);
    const maxTokens = Number.isFinite(maxTokensEnv) ? Math.max(maxTokensEnv, 4096) : 4096;
    const temperature = Number.parseFloat(process.env.AI_TEMPERATURE ?? '0.7');
    const preferredModel = process.env.AI_MODEL;

    const { text: inputText } = req.body ?? {};
    if (!inputText || typeof inputText !== 'string') {
      return res.status(400).json({ error: 'text is required' });
    }

    const client = new Anthropic({ apiKey });

    const system =
      'Sen FinalAI için çalışan bir öğretmen asistanısın. Hedef: Öğrencinin sınava hazırlanmasına yardım etmek.\n' +
      'Dil: Türkçe.\n' +
      'ÇIKTI KURALI: Her zaman SADECE geçerli JSON döndür. Markdown, açıklama, başlık, kod bloğu, ön/son metin YAZMA.\n' +
      'JSON KURALI: Çıktı tek bir JSON objesi olacak. Anahtarlar her zaman aynı isimlerle gelecek.\n' +
      'Metin türü ne olursa olsun (ders notu, makale, slayt, soru bankası, ödev, yönetmelik, form), en iyi tahmininle yapılandırılmış özet üret.';

    const prompt =
      'Aşağıdaki metni analiz et. Çıktın SADECE JSON olacak.\n\n' +
      'ÖNEMLİ DAVRANIŞ KURALLARI:\n' +
      '1) Metin az/bozuk/eksikse bile boş dönme: Metin türünü tahmin et ve "confidence" alanını düşür.\n' +
      '2) Metin soru bankası ise: "questions" alanında metindeki tarzı taklit et (çoktan seçmeli ağırlıklı).\n' +
      '3) Metin konu anlatımı ise: tanımlar, formüller/kurallar ve örnekler çıkar.\n' +
      '4) Bilmediğin/çıkaramadığın yerde uydurma kaynak atma. Emin değilsen "assumptions" içinde belirt.\n' +
      '5) MUTLAKA 10 adet soru ve 10 adet flashcard üret. Eksik bırakma.\n\n' +
      'JSON ŞEMASI (AYNEN KULLAN):\n' +
      '{\n' +
      '  "summary_short": "1-2 cümle özet",\n' +
      '  "summary_long": "Detaylı özet (paragraf formatında)",\n' +
      '  "questions": [\n' +
      '    {\n' +
      '      "question": "Soru metni",\n' +
      '      "options": ["A", "B", "C", "D"],\n' +
      '      "correctIndex": 0,\n' +
      '      "explanation": "Neden doğru açıklaması"\n' +
      '    }\n' +
      '  ],\n' +
      '  "flashcards": [\n' +
      '    {\n' +
      '      "front": "Soru/Terim",\n' +
      '      "back": "Cevap/Tanım"\n' +
      '    }\n' +
      '  ],\n' +
      '  "confidence": 0.9,\n' +
      '  "assumptions": ["Varsayım 1", "Varsayım 2"]\n' +
      '}\n\n' +
      `İşte metin:\n\n${inputText}`;

    const modelCandidates = preferredModel
      ? [preferredModel]
      : ['claude-sonnet-4-20250514', 'claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'];

    let msg;
    let usedModel;
    for (const modelId of modelCandidates) {
      try {
        msg = await client.messages.create({
          model: modelId,
          max_tokens: maxTokens,
          temperature,
          system,
          messages: [{ role: 'user', content: prompt }],
        });
        usedModel = modelId;
        console.log(`[ai/process-text] Using model: ${modelId}`);
        break;
      } catch (e) {
        console.warn(`[ai/process-text] Model ${modelId} failed: ${e?.status ?? e?.message}`);
        if (e?.status === 404) continue;
        throw e;
      }
    }

    if (!msg) {
      return res.status(500).json({
        error: `No available model found. Tried: ${modelCandidates.join(', ')}`,
      });
    }

    const textContent = msg.content.find((c) => c.type === 'text');
    let text = textContent?.text ?? '{}';

    const normalized = normalizeJsonText(text);
    let repaired;
    try {
      repaired = jsonrepair(normalized);
    } catch {
      repaired = normalized;
    }

    let parsed = null;
    let jsonError = null;
    try {
      parsed = JSON.parse(repaired);
    } catch (e) {
      jsonError = e.message;
      console.warn(
        `[ai/process-text] JSON parse failed for model ${usedModel}. Error: ${jsonError}. Normalized (first 400 chars): ${normalized.slice(0, 400)}`
      );
    }

    const needsCompletion =
      !parsed ||
      !parsed.questions ||
      !Array.isArray(parsed.questions) ||
      parsed.questions.length < 10 ||
      !parsed.flashcards ||
      !Array.isArray(parsed.flashcards) ||
      parsed.flashcards.length < 10 ||
      !parsed.summary_short ||
      !parsed.summary_long;

    if (needsCompletion && parsed) {
      const completionPrompt =
        'Önceki çıktında eksikler var. Lütfen şu JSON şemasını TAM OLARAK doldur:\n' +
        '{\n' +
        '  "summary_short": "1-2 cümle özet",\n' +
        '  "summary_long": "Detaylı özet",\n' +
        '  "questions": [ ... 10 adet ... ],\n' +
        '  "flashcards": [ ... 10 adet ... ],\n' +
        '  "confidence": 0.9,\n' +
        '  "assumptions": []\n' +
        '}\n\n' +
        `Mevcut çıktın:\n${JSON.stringify(parsed, null, 2)}\n\n` +
        'Eksikleri tamamla ve SADECE JSON döndür.';

      try {
        const completionMsg = await client.messages.create({
          model: usedModel,
          max_tokens: maxTokens,
          temperature,
          system,
          messages: [
            { role: 'user', content: prompt },
            { role: 'assistant', content: text },
            { role: 'user', content: completionPrompt },
          ],
        });

        const completionText = completionMsg.content.find((c) => c.type === 'text')?.text ?? '{}';
        const completionNormalized = normalizeJsonText(completionText);
        const completionRepaired = jsonrepair(completionNormalized);
        const completionParsed = JSON.parse(completionRepaired);

        if (completionParsed) {
          parsed = completionParsed;
          text = completionText;
          jsonError = null;
        }
      } catch (e) {
        console.warn(`[ai/process-text] Completion pass failed: ${e.message}`);
      }
    }

    res.json({
      text,
      json: parsed,
      normalized,
      repaired,
      json_error: jsonError,
      usage: msg.usage ?? null,
      model: msg.model ?? 'unknown',
    });
  } catch (e) {
    const status = e?.statusCode ?? 500;
    res.status(status).json({ error: e?.message ?? String(e) });
  }
});

// ── Learning Plan Generation ────────────────────────────────────────
router.post('/generate-plan', async (req, res) => {
  req.setTimeout(600000);
  res.setTimeout(600000);

  try {
    const apiKey = requireEnv('ANTHROPIC_API_KEY');
    const temperature = Number.parseFloat(process.env.AI_TEMPERATURE ?? '0.7');
    const preferredModel = process.env.AI_MODEL;
    // 2 units × 5 lessons per chunk — smaller requests for speed
    const maxTokens = 8192;

    const { prompt: userPrompt } = req.body ?? {};
    if (!userPrompt || typeof userPrompt !== 'string') {
      return res.status(400).json({ error: 'prompt is required' });
    }

    const client = new Anthropic({ apiKey });

    const system =
      'Sen FinalAI icin calisilan bir egitim planlayicisisin.\n' +
      'CIKTI KURALI: SADECE gecerli JSON dondur. Markdown, aciklama, baslık, kod blogu, on/son metin YAZMA.\n' +
      'Cıktı tek bir JSON objesi olacak: {"units": [...]}.\n' +
      'Dil: Turkce.';

    const modelCandidates = preferredModel
      ? [preferredModel]
      : ['claude-sonnet-4-20250514', 'claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'];

    let msg;
    let usedModel;
    for (const modelId of modelCandidates) {
      try {
        msg = await client.messages.create({
          model: modelId,
          max_tokens: maxTokens,
          temperature,
          system,
          messages: [{ role: 'user', content: userPrompt }],
        });
        usedModel = modelId;
        break;
      } catch (e) {
        console.warn(`[ai/generate-plan] Model ${modelId} failed: ${e?.status ?? e?.message}`);
        if (e?.status === 404) continue;
        throw e;
      }
    }

    if (!msg) {
      return res.status(500).json({
        error: `No available model found. Tried: ${modelCandidates.join(', ')}`,
      });
    }

    const textContent = msg.content.find((c) => c.type === 'text');
    let text = textContent?.text ?? '{}';

    const normalized = normalizeJsonText(text);
    let repaired;
    try {
      repaired = jsonrepair(normalized);
    } catch {
      repaired = normalized;
    }

    const stopReason = msg.stop_reason ?? 'unknown';

    let parsed = null;
    let jsonError = null;
    try {
      parsed = JSON.parse(repaired);
    } catch (e) {
      jsonError = e.message;
      console.warn(
        `[ai/generate-plan] JSON parse failed (stop=${stopReason}). Error: ${jsonError}. First 400 chars: ${normalized.slice(0, 400)}`
      );
    }

    // If truncated (e.g. max_tokens hit), use smart repair
    if (!parsed) {
      try {
        const smartRepaired = repairTruncatedJson(normalized);
        parsed = JSON.parse(smartRepaired);
        jsonError = null;
        console.log(`[ai/generate-plan] Smart repair succeeded`);
      } catch (e2) {
        console.warn(`[ai/generate-plan] Smart repair also failed: ${e2.message}`);
      }
    }

    console.log(
      `[ai/generate-plan] model=${usedModel} stop=${stopReason} units=${parsed?.units?.length ?? 0} textLen=${text.length}`
    );

    res.json({
      text,
      json: parsed,
      normalized,
      repaired,
      json_error: jsonError,
      usage: msg.usage ?? null,
      model: usedModel ?? 'unknown',
    });
  } catch (e) {
    console.error('[ai/generate-plan] Error:', e?.message ?? e);
    const status = Number(e?.status ?? e?.statusCode ?? 500);
    const type = e?.error?.error?.type ?? e?.error?.type;
    const isOverloaded = status === 529 || type === 'overloaded_error';
    res.status(isOverloaded ? 503 : status).json({
      error: isOverloaded ? 'anthropic_overloaded' : (e?.message ?? String(e)),
      retryable: Boolean(isOverloaded),
    });
  }
});

// ── Placement Test Question Generation ────────────────────────────
router.post('/placement-questions', async (req, res) => {
  req.setTimeout(120000);
  res.setTimeout(120000);

  try {
    const apiKey = requireEnv('ANTHROPIC_API_KEY');
    const { subject, goal, dailyMinutes } = req.body ?? {};

    if (!subject || typeof subject !== 'string') {
      return res.status(400).json({ error: 'subject is required' });
    }

    const client = new Anthropic({ apiKey });

    const seed = Date.now() % 100000;
    const system =
      'Sen bir eğitim uzmanısın. Seviye belirleme testi hazırlıyorsun.\n' +
      'ÇIKTI KURALI: SADECE geçerli JSON dizisi döndür. Markdown, açıklama, kod bloğu YAZMA.\n' +
      'Dil: Türkçe.';

    const prompt =
      `"${subject}" alanında seviye belirleme testi hazırla.\n` +
      (goal ? `Öğrencinin hedefi: ${goal}.\n` : '') +
      (dailyMinutes ? `Günlük çalışma süresi: ${dailyMinutes} dakika.\n` : '') +
      `Rastgelelik tohumu: ${seed}\n\n` +
      `GÖREV: "${subject}" konusunda TAM 8 adet çoktan seçmeli soru üret.\n\n` +
      'ZORLUK DAĞILIMI (sırayla):\n' +
      '- İlk 3 soru: "easy" — temel kavramlar, tanımlar, basit bilgi\n' +
      '- Sonraki 3 soru: "medium" — uygulama, analiz, orta seviye problem\n' +
      '- Son 2 soru: "hard" — ileri düzey, sentez, zor problem çözme\n\n' +
      'KURALLAR:\n' +
      `1) Her soru "${subject}" konusuna ÖZGÜ olmalı. Genel öğrenme teorisi sorusu SORMA.\n` +
      '2) 4 seçenek olmalı. Doğru cevap her zaman farklı index\'te olsun (0-3 arası dengeli dağıt).\n' +
      '3) Yanıltıcılar mantıklı olmalı — rastgele/saçma seçenek koyma.\n' +
      '4) Soru metni açık, net ve Türkçe olmalı.\n' +
      '5) Her soru birbirinden farklı alt konu/kavramı test etmeli.\n\n' +
      'ÇIKTI: Sadece JSON dizisi döndür, başka hiçbir şey yazma.\n' +
      '[\n' +
      '  {"q": "soru metni", "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"], "answer": 0, "difficulty": "easy"},\n' +
      '  ...\n' +
      ']\n\n' +
      'TAM 8 soru üret. JSON dışında hiçbir şey yazma.';

    const modelCandidates = [
      'claude-sonnet-4-20250514',
      'claude-3-5-sonnet-20241022',
      'claude-3-haiku-20240307',
    ];

    let msg;
    for (const modelId of modelCandidates) {
      try {
        msg = await client.messages.create({
          model: modelId,
          max_tokens: 4096,
          temperature: 0.8,
          system,
          messages: [{ role: 'user', content: prompt }],
        });
        console.log(`[ai/placement-questions] Using model: ${modelId}`);
        break;
      } catch (e) {
        console.warn(`[ai/placement-questions] Model ${modelId} failed: ${e?.status ?? e?.message}`);
        if (e?.status === 404) continue;
        throw e;
      }
    }

    if (!msg) {
      return res.status(500).json({ error: 'No available Claude model found.' });
    }

    const textContent = msg.content.find((c) => c.type === 'text');
    let text = textContent?.text ?? '[]';

    // Clean markdown wrappers
    text = text.replace(/```json\s*/gi, '').replace(/```\s*/gi, '').trim();

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      try {
        parsed = JSON.parse(jsonrepair(text));
      } catch {
        return res.status(500).json({ error: 'JSON parse failed', raw: text });
      }
    }

    if (!Array.isArray(parsed) || parsed.length < 4) {
      return res.status(500).json({ error: 'Invalid questions array', raw: text });
    }

    res.json({
      questions: parsed,
      model: msg.model ?? 'unknown',
      usage: msg.usage ?? null,
    });
  } catch (e) {
    console.error('[ai/placement-questions] Error:', e?.message ?? e);
    const status = e?.statusCode ?? 500;
    res.status(status).json({ error: e?.message ?? String(e) });
  }
});

export default router;
