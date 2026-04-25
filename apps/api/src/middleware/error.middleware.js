export function errorMiddleware(err, req, res, next) {
  if (!err) return next();

  const msg = String(err?.message ?? err);
  const isAborted = err?.type === 'request.aborted' || msg.toLowerCase().includes('request aborted');
  const isTooLarge =
    err?.type === 'entity.too.large' ||
    err?.status === 413 ||
    err?.statusCode === 413 ||
    msg.toLowerCase().includes('request entity too large');

  if (isAborted) {
    return res.status(499).json({ error: 'request_aborted' });
  }
  if (isTooLarge) {
    return res.status(413).json({ error: 'payload_too_large' });
  }

  const status = Number(err?.statusCode ?? err?.status ?? 500);
  return res.status(Number.isFinite(status) ? status : 500).json({ error: msg });
}
