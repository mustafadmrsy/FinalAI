import { jsonrepair } from 'jsonrepair';

export function normalizeJsonText(raw) {
  if (!raw) return '{}';
  let s = String(raw).replaceAll('```json', '').replaceAll('```', '').trim();

  // If the model returns a JSON fragment without outer braces, wrap it.
  // Example: "doc_type": "exam", ...
  if (!s.startsWith('{')) {
    const firstChar = s[0];
    if (firstChar === '"' || firstChar === "'") {
      s = `{${s}}`;
    }
  }

  // Extract first JSON object if extra text exists.
  const start = s.indexOf('{');
  const end = s.lastIndexOf('}');
  if (start >= 0 && end > start) {
    s = s.substring(start, end + 1);
  }

  // Remove trailing commas before } or ] (common model slip).
  s = s.replace(/,\s*([}\]])/g, '$1');
  return s;
}

export function validateAiJson(obj) {
  if (!obj || typeof obj !== 'object') {
    return { ok: false, issues: ['json_not_object'] };
  }
  const issues = [];

  const summaryShort = obj.summary_short;
  if (!Array.isArray(summaryShort) || summaryShort.length !== 5) issues.push('summary_short_missing');
  if (Array.isArray(summaryShort)) {
    const badFormat = summaryShort.some(
      (s) => typeof s !== 'string' || !String(s).includes(':') || String(s).split(':')[0].trim().length < 3
    );
    if (badFormat) issues.push('summary_short_format');
  }

  const summaryLong = obj.summary_long;
  if (typeof summaryLong !== 'string' || summaryLong.trim().length < 120) issues.push('summary_long_missing');
  if (typeof summaryLong === 'string') {
    const headingCount = (summaryLong.match(/\n\s*[^\n]{2,60}:\s*/g) ?? []).length;
    if (headingCount < 4) issues.push('summary_long_not_sectioned');
  }

  const questions = obj.questions;
  if (!Array.isArray(questions) || questions.length !== 20) issues.push('questions_missing');

  const flashcards = obj.flashcards;
  if (!Array.isArray(flashcards) || flashcards.length < 15) issues.push('flashcards_missing');

  return { ok: issues.length === 0, issues };
}

export function safeParseJson(rawText) {
  const normalized = normalizeJsonText(rawText);
  let repaired = normalized;
  try {
    repaired = jsonrepair(normalized);
  } catch (_) {
    // ignore
  }

  try {
    return {
      json: JSON.parse(repaired),
      normalized,
      repaired,
      error: null,
    };
  } catch (e) {
    return {
      json: null,
      normalized,
      repaired,
      error: e?.message ?? String(e),
    };
  }
}
