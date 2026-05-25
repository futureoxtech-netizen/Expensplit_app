import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import path from 'node:path';
import { env } from './config/env.js';
import { router } from './routes/index.js';
import { errorHandler, notFound } from './middleware/error.js';

export const app = express();

app.disable('x-powered-by');
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(cors({ origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','), credentials: true }));
app.use(compression());
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));
if (env.NODE_ENV !== 'test') app.use(morgan('dev'));

app.use(
  '/api/',
  rateLimit({ windowMs: 60_000, max: 300, standardHeaders: true, legacyHeaders: false }),
);

app.use('/uploads', express.static(path.resolve(env.UPLOAD_DIR)));

app.get('/health', (_req, res) => res.json({ ok: true, ts: Date.now(), service: 'expensplit-api' }));

app.use('/api/v1', router);

app.use(notFound);
app.use(errorHandler);
