import { ZodError } from 'zod';
import { AppError } from '../utils/errors.js';
import { logger } from '../config/logger.js';

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      ok: false,
      code: 'VALIDATION',
      message: 'Invalid request payload',
      errors: err.flatten(),
    });
  }
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      ok: false,
      code: err.code,
      message: err.message,
    });
  }
  if (err?.name === 'MongoServerError' && err.code === 11000) {
    return res.status(409).json({
      ok: false,
      code: 'DUPLICATE',
      message: 'Resource already exists',
    });
  }
  logger.error({ err, path: req.path }, 'Unhandled error');
  return res.status(500).json({
    ok: false,
    code: 'INTERNAL',
    message: 'Something went wrong',
  });
}

export function notFound(req, res) {
  res.status(404).json({ ok: false, code: 'NOT_FOUND', message: `Route ${req.path} not found` });
}
