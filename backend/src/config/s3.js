/**
 * AWS S3 client singleton.
 *
 * If AWS credentials are not configured the module still exports a client
 * object but every upload attempt will fail gracefully (uploadToS3 returns
 * null and the caller falls back to local storage).
 */
import { S3Client } from '@aws-sdk/client-s3';
import { env } from './env.js';

export const s3 = new S3Client({
  region: env.AWS_REGION || 'us-east-1',
  ...(env.AWS_ACCESS_KEY_ID && env.AWS_SECRET_ACCESS_KEY
    ? {
        credentials: {
          accessKeyId: env.AWS_ACCESS_KEY_ID,
          secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
        },
      }
    : {}),
});

export function hasS3() {
  return Boolean(
    env.AWS_ACCESS_KEY_ID && env.AWS_SECRET_ACCESS_KEY && env.AWS_S3_BUCKET,
  );
}
