import { createRequire } from 'module';
import * as pdfjsLib from 'pdfjs-dist/legacy/build/pdf.mjs';
import { createCanvas } from '@napi-rs/canvas';
import { createWorker } from 'tesseract.js';
import { PDFParse as PDFParseClass } from 'pdf-parse';

const require = createRequire(import.meta.url);

// pdf-parse is CommonJS; load it via require for Node ESM compatibility.
let pdfParse = require('pdf-parse');
if (pdfParse && typeof pdfParse !== 'function') {
  if (typeof pdfParse.default === 'function') {
    pdfParse = pdfParse.default;
  } else if (typeof pdfParse.pdfParse === 'function') {
    pdfParse = pdfParse.pdfParse;
  } else if (pdfParse.default && typeof pdfParse.default.default === 'function') {
    // Some bundlers/nodes produce a nested default export.
    pdfParse = pdfParse.default.default;
  }
}

export function logPdfParseResolution() {
  console.log(
    '[startup] pdf-parse resolved. typeof=',
    typeof pdfParse,
    'keys=',
    pdfParse && typeof pdfParse === 'object' ? Object.keys(pdfParse) : []
  );
}

export const OCR_MIN_TEXT_CHARS = Number(process.env.OCR_MIN_TEXT_CHARS ?? 200) || 200;

export function isLowQualityExtractedText(text) {
  if (!text) return true;
  const s = String(text).trim();
  if (!s) return true;

  // Detect common page label artifacts like "-- 1 of 136 --".
  const pageMarkerRe = /--\s*\d+\s+of\s+\d+\s*--/gi;
  const markerMatches = s.match(pageMarkerRe) ?? [];
  const markerCount = markerMatches.length;

  // Character composition heuristic: if mostly non-letters, it's likely garbage.
  const letters = (s.match(/[A-Za-zÇĞİÖŞÜçğıöşü]/g) ?? []).length;
  const digits = (s.match(/[0-9]/g) ?? []).length;
  const spaces = (s.match(/\s/g) ?? []).length;
  const nonSpace = Math.max(1, s.length - spaces);
  const letterRatio = letters / nonSpace;
  const digitRatio = digits / nonSpace;

  // Token variety: if extremely repetitive, likely headers/footers/page labels.
  const tokens = s
    .toLowerCase()
    .replace(/[^a-z0-9çğıöşü\s]+/gi, ' ')
    .split(/\s+/)
    .filter(Boolean);
  const unique = new Set(tokens);
  const uniqueRatio = tokens.length ? unique.size / tokens.length : 0;

  const markerDominant = markerCount >= 3;
  const compositionBad = letterRatio < 0.12 || digitRatio > 0.35;
  const varietyBad = tokens.length >= 40 && uniqueRatio < 0.25;

  return markerDominant || compositionBad || varietyBad;
}

export async function extractPdfTextFromBuffer(pdfBuffer) {
  // pdf-parse v2+ is class-based. Prefer it to avoid CJS/ESM interop issues.
  try {
    if (PDFParseClass) {
      const parser = new PDFParseClass({ data: pdfBuffer });
      try {
        const textRes = await parser.getText();
        const text = (textRes?.text ?? '').toString();
        const numpages = Number(textRes?.total ?? 0) || 0;
        return { text, numpages };
      } finally {
        await parser.destroy();
      }
    }
  } catch (e) {
    console.warn('[extractPdfTextFromBuffer] PDFParseClass failed:', e?.message ?? String(e));
  }

  // Fallback for older pdf-parse versions that export a function.
  if (typeof pdfParse === 'function') {
    const pdfData = await pdfParse(pdfBuffer);
    return {
      text: (pdfData?.text ?? '').toString(),
      numpages: Number(pdfData?.numpages ?? 0) || 0,
    };
  }

  return { text: '', numpages: 0 };
}

export async function ocrPdfBufferToText(pdfBuffer, { lang, maxPages, onProgress } = {}) {
  const resolvedLang = lang || process.env.OCR_LANG || 'tur';
  const maxPagesResolved = Number(maxPages ?? process.env.OCR_MAX_PAGES ?? 12) || 12;

  const dataBytes = new Uint8Array(pdfBuffer.buffer, pdfBuffer.byteOffset, pdfBuffer.byteLength);
  const loadingTask = pdfjsLib.getDocument({ data: dataBytes, disableWorker: true });
  const pdf = await loadingTask.promise;
  const totalPages = pdf.numPages || 0;

  // Pick representative pages across the whole document to cover all topics
  // without OCR-ing every single page.
  const pickSamplePages = (nPages, budget) => {
    const out = new Set();
    if (!nPages || nPages <= 0 || !budget || budget <= 0) return [];

    // Always include first pages (titles/TOC/intro) and last page (summary/appendix)
    out.add(1);
    if (nPages >= 2) out.add(2);
    if (nPages >= 3) out.add(3);
    if (nPages >= 4 && budget >= 6) out.add(4);
    out.add(nPages);

    // Evenly spaced pages for topic coverage.
    const remaining = Math.max(0, budget - out.size);
    if (remaining > 0) {
      const step = nPages / (remaining + 1);
      for (let i = 1; i <= remaining; i += 1) {
        const p = Math.max(1, Math.min(nPages, Math.round(i * step)));
        out.add(p);
      }
    }

    // If still under budget due to duplicates, fill sequentially.
    for (let p = 1; out.size < budget && p <= nPages; p += 1) out.add(p);

    return [...out].sort((a, b) => a - b);
  };

  const pagesSelected = pickSamplePages(totalPages, Math.min(totalPages, maxPagesResolved));
  const pagesToProcess = pagesSelected.length;

  let worker;
  try {
    worker = await createWorker(resolvedLang);
  } catch (e) {
    console.warn('[ocr] createWorker failed for lang=', resolvedLang, 'retrying with eng');
    worker = await createWorker('eng');
  }
  let allText = '';
  try {
    for (let i = 0; i < pagesSelected.length; i += 1) {
      const p = pagesSelected[i];
      onProgress?.({ phase: 'render', page: i + 1, total: pagesToProcess, pdfPage: p });
      const page = await pdf.getPage(p);
      const viewport = page.getViewport({ scale: 2 });
      const canvas = createCanvas(Math.ceil(viewport.width), Math.ceil(viewport.height));
      const ctx = canvas.getContext('2d');
      await page.render({ canvasContext: ctx, viewport }).promise;
      const png = canvas.toBuffer('image/png');
      onProgress?.({ phase: 'ocr', page: i + 1, total: pagesToProcess, pdfPage: p });
      const bytes = new Uint8Array(png.buffer, png.byteOffset, png.byteLength);
      const rec = await worker.recognize(bytes);
      const txt = (rec?.data?.text ?? '').toString();
      if (txt) allText += `\n\n${txt}`;
    }
  } finally {
    await worker.terminate();
  }

  return {
    text: String(allText).replace(/\s+/g, ' ').trim(),
    pageCount: totalPages,
    ocrPagesProcessed: pagesToProcess,
    ocrPagesSelected: pagesSelected,
  };
}
