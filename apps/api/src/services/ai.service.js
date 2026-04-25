import Anthropic from '@anthropic-ai/sdk';
import { jsonrepair } from 'jsonrepair';

import { normalizeJsonText, validateAiJson } from './validation.service.js';
import { OCR_MIN_TEXT_CHARS, extractPdfTextFromBuffer, isLowQualityExtractedText, ocrPdfBufferToText } from './pdf.service.js';

function splitIntoChunks(text, maxChars) {
  const out = [];
  if (!text) return out;
  const t = String(text);
  for (let i = 0; i < t.length; i += maxChars) {
    out.push(t.slice(i, i + maxChars));
  }
  return out;
}

export function requireEnv(name) {
  const v = process.env[name];
  if (!v) {
    const err = new Error(`Missing environment variable: ${name}`);
    err.statusCode = 500;
    throw err;
  }
  return v;
}

export async function processPdfCore({
  apiKey,
  preferredModel,
  temperature,
  maxTokens,
  pdfBase64,
  useCaching,
  pdfText: pdfTextOverride,
  pageCount: pageCountOverride,
}) {
  const t0 = Date.now();
  const hasPdfTextOverride = pdfTextOverride !== undefined && pdfTextOverride !== null;
  let pdfText = pdfTextOverride ?? '';
  let pageCount = Number(pageCountOverride ?? 0) || 0;

  if (!hasPdfTextOverride) {
    console.log('[processPdfCore] extracting text inside core...');
    try {
      const pdfBuffer = Buffer.from(pdfBase64, 'base64');
      const pdfData = await extractPdfTextFromBuffer(pdfBuffer);
      pdfText = pdfData.text ?? '';
      pageCount = Number(pdfData.numpages ?? 0) || 0;
    } catch (_) {
      pdfText = '';
      pageCount = 0;
    }
    console.log(
      `[processPdfCore] extraction done inside core. pages=${pageCount} textLen=${String(pdfText ?? '').length} dtMs=${Date.now() - t0}`
    );
  }

  if (pdfText) {
    pdfText = String(pdfText).replace(/\s+/g, ' ').trim();
  }

  console.log(
    `[processPdfCore] start. pages=${pageCount} compactTextLen=${pdfText.length} hasOverride=${hasPdfTextOverride} dtMs=${Date.now() - t0}`
  );

  await new Promise((resolve) => setImmediate(resolve));

  const client = new Anthropic({ apiKey });

  const system =
    'Sen FinalAI için çalışan bir öğretmen asistanısın. Hedef: Öğrencinin sınava hazırlanmasına yardım etmek.\n' +
    'Dil: Türkçe.\n' +
    'ÇIKTI KURALI: Her zaman SADECE geçerli JSON döndür. Markdown, açıklama, başlık, kod bloğu, ön/son metin YAZMA.\n' +
    'JSON KURALI: Çıktı tek bir JSON objesi olacak. Anahtarlar her zaman aynı isimlerle gelecek.\n' +
    'Metin türü ne olursa olsun (ders notu, makale, slayt, soru bankası, ödev, yönetmelik, form), en iyi tahmininle yapılandırılmış özet üret.';

  const prompt =
    'Aşağıdaki PDF metnini analiz et. Çıktın SADECE JSON olacak.\n\n' +
    'ÖNEMLİ DAVRANIŞ KURALLARI:\n' +
    '1) PDF içinde metin az/bozuk/eksikse bile boş dönme: PDF türünü tahmin et ve "confidence" alanını düşür.\n' +
    '2) PDF soru bankası ise: "questions" alanında PDF’deki tarzı taklit et (çoktan seçmeli ağırlıklı).\n' +
    '3) PDF konu anlatımı ise: tanımlar, formüller/kurallar ve en az 1-2 örnek uygulama çıkar.\n' +
    '4) Bilmediğin/çıkaramadığın yerde uydurma kaynak atma. Emin değilsen "assumptions" içinde belirt.\n' +
    '5) "questions" TAM 20 adet olacak (PDF ile ilgili). "flashcards" EN AZ 15 adet olacak. Eksik bırakma.\n' +
    '6) KISA ÖZET: PDF’deki TÜM ana konuları kapsa. "summary_short" TAM 5 madde olacak ve HER MADDE şu formatta olacak: "Konu Başlığı: 1 cümlelik özet".\n' +
    '7) DETAYLI ÖZET: "summary_long" alanı bölüm bölüm olacak. En az 5 bölüm/başlık üret. Her bölümde kısa açıklama + (tanım / formül-kural / örnek-uygulama) içeren madde işaretli alt başlıklar ver.\n\n' +
    'AŞAĞIDAKİ ŞEMAYA HARFİYEN UY:\n' +
    '{\n' +
    '  "doc_type": "lecture_notes|slides|question_bank|article|worksheet|exam|other",\n' +
    '  "language": "tr",\n' +
    '  "title": "PDF başlığı veya tahmini başlık",\n' +
    '  "main_topic": "ana konu (kısa)",\n' +
    '  "confidence": 0.0,\n' +
    '  "summary_short": ["Konu Başlığı: 1 cümle", "..."],\n' +
    '  "summary_long": "Başlık1:...\\n- ...\\n\\nBaşlık2:...\\n- ...",\n' +
    '  "key_concepts": ["kavram1", "kavram2"],\n' +
    '  "definitions": [{"term":"...","definition":"..."}],\n' +
    '  "formulas_or_rules": [{"name":"...","expression":"...","notes":"..."}],\n' +
    '  "common_mistakes": ["hata1", "hata2"],\n' +
    '  "questions": [\n' +
    '    {"question":"...","options":["A) ...","B) ...","C) ...","D) ..."],"correct_index":0,"explanation":"...","difficulty":"easy|medium|hard","topic":"..."}\n' +
    '  ],\n' +
    '  "flashcards": [{"front":"...","back":"..."}],\n' +
    '  "likely_exam_questions": ["...","..."],\n' +
    '  "assumptions": ["PDF’de metin azdı, konu şu olabilir..."],\n' +
    '  "recommended_next_steps": ["10 dakikalık tekrar planı", "hangi konulara çalışmalı" ]\n' +
    '}\n\n' +
    'NOT: summary_short TAM 5 madde olacak. questions TAM 20 eleman olacak. flashcards EN AZ 15 eleman olacak.\n' +
    'Eğer PDF bir sınav/soru bankası ise soruları ve konularını baz alarak yeni ama AYNİ konularla uyumlu sorular üret.\n' +
    'JSON dışında hiçbir şey yazma.';

  const chunkSystem = 'Türkçe yaz. Yalnızca düz metin döndür. Kısa, madde madde, bilgi yoğun özet çıkar.';

  const modelCandidates = [
    preferredModel,
    'claude-sonnet-4-6',
    'claude-opus-4-7',
    'claude-opus-4-6',
    'claude-sonnet-4-20250514',
    'claude-opus-4-20250514',
    'claude-haiku-4-5-20251001',
    'claude-sonnet-4-5-20250929',
    'claude-opus-4-5-20251101',
    'claude-opus-4-1-20250805',
  ].filter(Boolean);

  async function createMessageWithFallback(payloadBase) {
    let lastErr;
    for (const model of modelCandidates) {
      try {
        const payload = { ...payloadBase, model };
        const timeoutMs = Number(process.env.ANTHROPIC_TIMEOUT_MS ?? 180000) || 180000;
        const maxRetries = Number(process.env.ANTHROPIC_RETRY_MAX ?? 3) || 3;
        for (let attempt = 0; attempt < maxRetries; attempt += 1) {
          try {
            return await Promise.race([
              client.messages.create(payload),
              new Promise((_, reject) =>
                setTimeout(() => reject(new Error(`Anthropic request timeout after ${timeoutMs}ms`)), timeoutMs)
              ),
            ]);
          } catch (e) {
            lastErr = e;
            const status = e?.status ?? e?.statusCode;
            const type = e?.error?.error?.type ?? e?.error?.type;
            const retryable =
              status === 529 ||
              type === 'overloaded_error' ||
              e?.headers?.['x-should-retry'] === 'true' ||
              e?.headers?.['x-should-retry'] === true;

            if (!retryable || attempt === maxRetries - 1) throw e;
            const backoffMs = Math.min(15000, 750 * Math.pow(2, attempt)) + Math.floor(Math.random() * 250);
            console.warn(
              `[anthropic] retryable error (status=${status} type=${type}). attempt=${attempt + 1}/${maxRetries} waitingMs=${backoffMs}`
            );
            await new Promise((r) => setTimeout(r, backoffMs));
          }
        }
      } catch (e) {
        lastErr = e;
        const isNotFound =
          e?.error?.error?.type === 'not_found_error' ||
          e?.error?.type === 'not_found_error' ||
          String(e?.message ?? '').includes('not_found_error') ||
          String(e).includes('not_found_error');
        if (isNotFound) continue;
        throw e;
      }
    }
    throw lastErr ?? new Error('No model could be used');
  }

  const MAX_TEXT_CHARS = 20000;
  const CHUNK_CHARS = 2500;

  let effectiveText = pdfText;
  if (!effectiveText) {
    effectiveText =
      'PDF metni çıkarılamadı veya çok az metin içeriyor. ' +
      'Muhtemelen taranmış (image-based) bir PDF. Lütfen içeriği en iyi tahmininle özetle ve "assumptions" alanında bunu açıkça belirt.';
  }

  if (pdfText && pdfText.length > MAX_TEXT_CHARS) {
    console.log(
      `[processPdfCore] chunking start. originalLen=${pdfText.length} MAX_TEXT_CHARS=${MAX_TEXT_CHARS} CHUNK_CHARS=${CHUNK_CHARS} dtMs=${Date.now() - t0}`
    );
    pdfText = pdfText.slice(0, MAX_TEXT_CHARS);
    await new Promise((resolve) => setImmediate(resolve));

    const chunks = splitIntoChunks(pdfText, CHUNK_CHARS).slice(0, 12);
    console.log(
      `[processPdfCore] chunking prepared. chunks=${chunks.length} truncatedLen=${pdfText.length} dtMs=${Date.now() - t0}`
    );
    const summaries = [];
    for (let i = 0; i < chunks.length; i += 1) {
      const ct = Date.now();
      console.log(
        `[processPdfCore] chunk ${i + 1}/${chunks.length} anthropic call start. chunkLen=${chunks[i].length} dtMs=${ct - t0}`
      );
      const chunkMsg = await createMessageWithFallback({
        max_tokens: 400,
        temperature: 0.2,
        system: [
          {
            type: 'text',
            text: chunkSystem,
            cache_control: { type: 'ephemeral' },
          },
        ],
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Bu metni 6-10 maddede çok kısa özetle (sadece düz metin). Metin: ${chunks[i]}`,
                cache_control: { type: 'ephemeral' },
              },
            ],
          },
        ],
      });
      const chunkTextOut = chunkMsg?.content?.[0]?.text ?? '';
      summaries.push(`Bölüm ${i + 1}:\n${chunkTextOut}`);
      console.log(
        `[processPdfCore] chunk ${i + 1}/${chunks.length} done. outLen=${String(chunkTextOut).length} dtMs=${Date.now() - t0}`
      );
    }
    const combined = summaries.join('\n').slice(0, 16000);
    effectiveText = combined;
    console.log(`[processPdfCore] chunking done. combinedLen=${combined.length} dtMs=${Date.now() - t0}`);
  }

  await new Promise((resolve) => setImmediate(resolve));

  console.log(
    `[processPdfCore] final anthropic call start. effectiveTextLen=${String(effectiveText ?? '').length} dtMs=${Date.now() - t0}`
  );

  const msg = await createMessageWithFallback({
    max_tokens: maxTokens,
    temperature,
    system: [
      {
        type: 'text',
        text: system,
        cache_control: { type: 'ephemeral' },
      },
    ],
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: `PDF İçeriği (özetlenmiş olabilir):\n\n${effectiveText}\n\n---\n\n${prompt}`,
            cache_control: { type: 'ephemeral' },
          },
        ],
      },
    ],
  });

  const text = msg?.content?.[0]?.text ?? '';
  console.log(
    `[processPdfCore] final anthropic call done. outTextLen=${String(text).length} model=${msg?.model ?? 'unknown'} dtMs=${Date.now() - t0}`
  );

  const normalized = normalizeJsonText(text);
  let repaired = normalized;
  try {
    repaired = jsonrepair(normalized);
  } catch (_) {}

  let json = null;
  try {
    json = JSON.parse(repaired);
  } catch (_) {
    json = null;
  }

  async function generateMissingItems({ kind, existing, needCount }) {
    const existingArr = Array.isArray(existing) ? existing : [];
    const need = Math.max(0, Number(needCount) || 0);
    if (need === 0) return [];

    const commonRules =
      'KURALLAR:\n' +
      '- PDF içeriği ile alakalı olmalı.\n' +
      '- SADECE geçerli JSON array döndür. Başka hiçbir şey yazma.\n\n';

    const baseContext =
      `MEVCUT OGELER (tekrar etme):\n${JSON.stringify(existingArr, null, 2)}\n\n` +
      `PDF METNİ (özetlenmiş olabilir):\n${String(effectiveText ?? '').slice(0, 16000)}\n`;

    let userPrompt = '';
    if (kind === 'questions') {
      userPrompt =
        `Eksik quiz sorularını üret. HEDEF: Tam ${need} adet yeni soru üret (sadece yeni sorular).\n` +
        commonRules +
        'ŞEMA (ARRAY ELEMANI):\n' +
        '{"question":"...","options":["A) ...","B) ...","C) ...","D) ..."],"correct_index":0,"explanation":"...","difficulty":"easy|medium|hard","topic":"..."}\n\n' +
        baseContext;
    } else {
      userPrompt =
        `Eksik flashcardları üret. HEDEF: Tam ${need} adet yeni flashcard üret (sadece yeni flashcardlar).\n` +
        commonRules +
        'ŞEMA (ARRAY ELEMANI):\n' +
        '{"front":"...","back":"..."}\n\n' +
        baseContext;
    }

    const extraMsg = await createMessageWithFallback({
      max_tokens: Math.min(2200, Math.max(900, Math.floor(maxTokens / 2))),
      temperature: Math.min(0.6, Number(temperature) || 0.4),
      system,
      messages: [{ role: 'user', content: userPrompt }],
    });

    const out = extraMsg?.content?.[0]?.text ?? '';
    const outNorm = normalizeJsonText(out);
    let outRep = outNorm;
    try {
      outRep = jsonrepair(outNorm);
    } catch (_) {}

    try {
      const parsed = JSON.parse(outRep);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }

  try {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const v = validateAiJson(json);
      if (v.ok) break;

      const issues = Array.isArray(v.issues) ? v.issues : [];
      const onlyCountIssues =
        issues.length > 0 && issues.every((x) => x === 'questions_missing' || x === 'flashcards_missing');
      const hasSummaries =
        json &&
        typeof json === 'object' &&
        Array.isArray(json.summary_short) &&
        json.summary_short.length === 5 &&
        typeof json.summary_long === 'string' &&
        json.summary_long.trim().length >= 120;
      if (onlyCountIssues && hasSummaries) {
        console.log(
          `[processPdfCore] skipping completion pass (only count issues). issues=${issues.join(',')} dtMs=${Date.now() - t0}`
        );
        break;
      }

      console.log(
        `[processPdfCore] completion pass start. attempt=${attempt + 1}/3 issues=${(v.issues ?? []).join(',')} dtMs=${Date.now() - t0}`
      );

      const invalidSnippet = (() => {
        const src = (repaired && repaired !== '{}' ? repaired : normalized) || text || '';
        const s = String(src).trim();
        if (!s) return '';
        return s.length > 6000 ? `${s.slice(0, 6000)}\n...<truncated>...` : s;
      })();

      const completionPrompt =
        'Önceki çıktıda eksikler/kuralsızlıklar var. Lütfen aşağıdaki KURALLARA UYARAK aynı JSON objesini düzelt ve tamamla.\n' +
        '- summary_short: TAM 5 eleman olacak ve her eleman "Konu Başlığı: 1 cümle" formatında olacak (PDF’deki TÜM ana konuları kapsayacak).\n' +
        '- summary_long: Başlık başlık, kısa özetin daha detaylı hali olacak. En az 5 başlık/bölüm olacak. Her başlıkta tanım + formül/kural + örnek/uygulama maddeleri olsun.\n' +
        '- questions: TAM 20 adet olacak. options TAM 4 ve correct_index 0-3.\n' +
        '- flashcards: EN AZ 15 adet olacak.\n' +
        'SADECE JSON döndür.\n\n' +
        (json
          ? `Mevcut JSON:\n${JSON.stringify(json, null, 2)}\n\n`
          : `Mevcut (geçersiz/eksik) çıktı parçası:\n${invalidSnippet || '(boş)'}\n\n`) +
        `Tespit edilen problemler: ${v.issues.join(', ')}\n` +
        `Düzeltme denemesi: ${attempt + 1}/3\n`;

      const completionMsg = await createMessageWithFallback({
        max_tokens: maxTokens,
        temperature,
        system,
        messages: [
          { role: 'user', content: prompt },
          { role: 'assistant', content: text },
          { role: 'user', content: completionPrompt },
        ],
      });

      console.log(
        `[processPdfCore] completion pass done. attempt=${attempt + 1}/3 outLen=${String(completionMsg?.content?.[0]?.text ?? '').length} dtMs=${Date.now() - t0}`
      );

      const completionText = completionMsg?.content?.[0]?.text ?? '';
      const completionNormalized = normalizeJsonText(completionText);
      let completionRepaired = completionNormalized;
      try {
        completionRepaired = jsonrepair(completionNormalized);
      } catch (_) {}

      try {
        const completionJson = JSON.parse(completionRepaired);
        if (completionJson) json = completionJson;
      } catch (_) {}
    }

    if (json && typeof json === 'object') {
      const q = Array.isArray(json.questions) ? json.questions : [];
      const f = Array.isArray(json.flashcards) ? json.flashcards : [];
      const qNeed = Math.max(0, 20 - q.length);
      const fNeed = Math.max(0, 15 - f.length);

      if (qNeed > 0) {
        console.log(`[processPdfCore] generating missing questions. need=${qNeed} dtMs=${Date.now() - t0}`);
        const more = await generateMissingItems({ kind: 'questions', existing: q, needCount: qNeed });
        json.questions = [...q, ...more].slice(0, 20);
        console.log(
          `[processPdfCore] missing questions done. got=${Array.isArray(more) ? more.length : 0} dtMs=${Date.now() - t0}`
        );
      }
      if (fNeed > 0) {
        console.log(`[processPdfCore] generating missing flashcards. need=${fNeed} dtMs=${Date.now() - t0}`);
        const more = await generateMissingItems({ kind: 'flashcards', existing: f, needCount: fNeed });
        json.flashcards = [...f, ...more].slice(0, 15);
        console.log(
          `[processPdfCore] missing flashcards done. got=${Array.isArray(more) ? more.length : 0} dtMs=${Date.now() - t0}`
        );
      }
    }
  } catch (e) {
    console.warn('[processPdfCore] validation/completion pass failed:', e?.message ?? String(e));
  }

  return {
    data: json,
    json,
    text,
    normalized,
    repaired,
    usage: msg?.usage ?? null,
    model: msg?.model ?? 'unknown',
    extractedTextLength: pdfText?.length ?? 0,
  };
}

export async function extractTextWithOcrFallback(pdfBase64, { onOcrProgress } = {}) {
  const pdfBuffer = Buffer.from(pdfBase64, 'base64');
  let extractedText = '';
  let extractedPages = 0;

  try {
    const pdfData = await extractPdfTextFromBuffer(pdfBuffer);
    extractedText = (pdfData.text ?? '').toString();
    extractedPages = Number(pdfData.numpages ?? 0) || 0;
  } catch (_) {
    extractedText = '';
    extractedPages = 0;
  }

  if (extractedText) extractedText = String(extractedText).replace(/\s+/g, ' ').trim();

  const forceOcr = !extractedText || extractedText.length < OCR_MIN_TEXT_CHARS || isLowQualityExtractedText(extractedText);

  if (forceOcr) {
    try {
      const ocr = await ocrPdfBufferToText(pdfBuffer, { onProgress: onOcrProgress });
      extractedText = ocr.text;
      extractedPages = ocr.pageCount;
      if (extractedText && extractedText.length < OCR_MIN_TEXT_CHARS) {
        const ocr2 = await ocrPdfBufferToText(pdfBuffer, {
          maxPages: Math.min(24, ocr.pageCount || 24),
          onProgress: onOcrProgress,
        });
        if (ocr2?.text && ocr2.text.length > extractedText.length) extractedText = ocr2.text;
      }
    } catch (e) {
      console.warn('[extractTextWithOcrFallback] OCR failed:', e?.message ?? String(e));
    }
  }

  return { extractedText, extractedPages };
}
