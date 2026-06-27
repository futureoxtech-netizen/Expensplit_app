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

  JWT_ACCESS_SECRET: required('JWT_ACCESS_SECRET', 'dev-access-secret'),
  JWT_REFRESH_SECRET: required('JWT_REFRESH_SECRET', 'dev-refresh-secret'),
  JWT_ACCESS_TTL: process.env.JWT_ACCESS_TTL ?? '15m',
  JWT_REFRESH_TTL: process.env.JWT_REFRESH_TTL ?? '30d',

  UPLOAD_DIR: process.env.UPLOAD_DIR ?? './uploads',
  MAX_UPLOAD_MB: Number(process.env.MAX_UPLOAD_MB ?? 10),

  SMTP_HOST: process.env.SMTP_HOST ?? 'mail.privateemail.com',
  SMTP_PORT: Number(process.env.SMTP_PORT ?? 587),
  SMTP_USER: required('SMTP_USER', ''),
  SMTP_PASS: required('SMTP_PASS', ''),
  SMTP_FROM: process.env.SMTP_FROM ?? 'Expensplit <noreply@example.com>',

  GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID ?? '',
  // All OAuth client IDs whose Google ID tokens we accept as valid audiences.
  // Mobile platforms mint ID tokens with DIFFERENT audiences:
  //   • Android → the web/server client id (because the app sets serverClientId)
  //   • iOS     → the iOS client id (its own OAuth client)
  //   • Web     → the web client id
  // So `verifyIdToken` must be given the full set, otherwise a token that is
  // perfectly valid for one platform is rejected as "invalid" on another.
  // Configure via GOOGLE_CLIENT_IDS (comma-separated); falls back to the single
  // GOOGLE_CLIENT_ID for backward compatibility.
  GOOGLE_CLIENT_IDS: (process.env.GOOGLE_CLIENT_IDS ?? process.env.GOOGLE_CLIENT_ID ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),

  // AWS S3 (leave blank to fall back to local disk storage)
  AWS_ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID ?? '',
  AWS_SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY ?? '',
  AWS_REGION: process.env.AWS_REGION ?? 'us-east-1',
  AWS_S3_BUCKET: process.env.AWS_S3_BUCKET ?? '',

  // OneSignal push (leave blank to disable — sockets still work)
  ONESIGNAL_APP_ID: process.env.ONESIGNAL_APP_ID ?? '',
  ONESIGNAL_REST_API_KEY: process.env.ONESIGNAL_REST_API_KEY ?? '',
};
