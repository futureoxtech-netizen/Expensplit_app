import 'dotenv/config';

const required = (key, fallback) => {
  const v = process.env[key] ?? fallback;
  if (v === undefined || v === null || v === '') {
    throw new Error(`Missing required env var: ${key}`);
  }
  return v;
};

export const env = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: Number(process.env.PORT ?? 4000),
  CORS_ORIGIN: process.env.CORS_ORIGIN ?? '*',

  MONGO_URI: required('MONGO_URI', 'mongodb://localhost:27017/expense'),
  REDIS_URL: required('REDIS_URL', 'redis://localhost:6379'),

  JWT_ACCESS_SECRET: required('JWT_ACCESS_SECRET', 'dev-access-secret'),
  JWT_REFRESH_SECRET: required('JWT_REFRESH_SECRET', 'dev-refresh-secret'),
  JWT_ACCESS_TTL: process.env.JWT_ACCESS_TTL ?? '15m',
  JWT_REFRESH_TTL: process.env.JWT_REFRESH_TTL ?? '30d',

  UPLOAD_DIR: process.env.UPLOAD_DIR ?? './uploads',
  MAX_UPLOAD_MB: Number(process.env.MAX_UPLOAD_MB ?? 10),
};
