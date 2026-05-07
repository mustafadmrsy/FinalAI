export function errorMiddleware(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  const message = err?.message ?? String(err);

  // Express/body-parser payload too large
  if (err?.type === 'entity.too.large' || err?.status === 413) {
    return res.status(413).json({
      error: 'payload_too_large',
      message: 'Payload too large',
    });
  }

  // Client aborted request
  // (Node/Express can surface this as various errors; keep it permissive)
  if (message.toLowerCase().includes('request aborted')) {
    return res.status(499).json({
      error: 'request_aborted',
      message: 'Request aborted by the client',
    });
  }

  console.error('[api:error]', err);

  return res.status(500).json({
    error: 'internal_server_error',
    message,
  });
}
