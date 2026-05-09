import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import aiRoutes from './routes/ai.routes.js';
import { errorMiddleware } from './middleware/error.middleware.js';
import { logPdfParseResolution } from './services/pdf.service.js';

process.on('uncaughtException', (err) => {
  console.error('[uncaughtException]', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('[unhandledRejection]', reason);
});

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Startup logging (kept from previous implementation)
logPdfParseResolution();

const port = Number.parseInt(process.env.PORT ?? '3000', 10);

// Routes
app.get('/health', (req, res) => {
  res.json({ ok: true });
});
app.use('/ai', aiRoutes);

// Error handler must be registered after routes.
app.use(errorMiddleware);

app.listen(port, '0.0.0.0', () => {
  console.log(`finalai-api listening on http://0.0.0.0:${port}`);
});
