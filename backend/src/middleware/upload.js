/**
 * Image upload middleware + S3 helper.
 *
 * Flow:
 *   1. multer stores the incoming file in memory (Buffer).
 *   2. uploadToS3() streams the buffer to S3 and returns the public URL.
 *   3. If S3 is not configured the file is saved to the local UPLOAD_DIR
 *      as a fallback so development keeps working without AWS credentials.
 *
 * Usage (in a route handler):
 *   router.post('/me/avatar', uploadMiddleware, controller.uploadAvatar);
 */
import path from 'node:path';
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import multer from 'multer';
import { PutObjectCommand } from '@aws-sdk/client-s3';
import { env } from '../config/env.js';
import { s3, hasS3 } from '../config/s3.js';
import { logger } from '../config/logger.js';

// ── multer: memory storage (files stay in RAM until we decide where to send them) ──
const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

const storage = multer.memoryStorage();

export const uploadMiddleware = multer({
  storage,
  limits: { fileSize: env.MAX_UPLOAD_MB * 1024 * 1024 },
  fileFilter(_req, file, cb) {
    if (ALLOWED_MIME.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, WebP and GIF images are allowed'));
    }
  },
}).single('image');

// ── S3 upload ────────────────────────────────────────────────────────────────────

/**
 * Upload a file buffer to S3 under the given folder prefix.
 *
 * @param {Buffer} buffer       Raw file bytes.
 * @param {string} mimetype     MIME type (e.g. "image/jpeg").
 * @param {string} [folder]     S3 key prefix, e.g. "avatars" → "avatars/<uuid>.jpg"
 * @returns {Promise<string>}   Public HTTPS URL of the uploaded object, or null on error.
 */
export async function uploadToS3(buffer, mimetype, folder = 'uploads') {
  if (!hasS3()) {
    // Fall back to local disk so dev works without AWS credentials
    return uploadToLocal(buffer, mimetype, folder);
  }

  const ext = mimeToExt(mimetype);
  const key = `${folder}/${crypto.randomUUID()}${ext}`;

  try {
    await s3.send(
      new PutObjectCommand({
        Bucket: env.AWS_S3_BUCKET,
        Key: key,
        Body: buffer,
        ContentType: mimetype,
        // Objects are public-read — profile pictures and group covers
        // must be accessible directly from the browser / app.
        ACL: 'public-read',
      }),
    );
    return `https://${env.AWS_S3_BUCKET}.s3.${env.AWS_REGION}.amazonaws.com/${key}`;
  } catch (err) {
    logger.error({ err: err.message, key }, 'S3 upload failed');
    return null;
  }
}

// ── Local-disk fallback (development) ──────────────────────────────────────────

async function uploadToLocal(buffer, mimetype, folder) {
  const dir = path.resolve(env.UPLOAD_DIR, folder);
  await fs.mkdir(dir, { recursive: true });
  const ext = mimeToExt(mimetype);
  const filename = `${crypto.randomUUID()}${ext}`;
  await fs.writeFile(path.join(dir, filename), buffer);
  // Return a relative URL the client can fetch via the /uploads static route
  return `/uploads/${folder}/${filename}`;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function mimeToExt(mime) {
  const map = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
    'image/gif': '.gif',
  };
  return map[mime] ?? '.jpg';
}
