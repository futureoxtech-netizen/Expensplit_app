import Redis from 'ioredis';
import { env } from './env.js';
import { logger } from './logger.js';

let client;

export async function connectRedis() {
  client = new Redis(env.REDIS_URL, { lazyConnect: true, maxRetriesPerRequest: 2 });
  client.on('error', (err) => logger.error({ err }, 'Redis error'));
  try {
    await client.connect();
    logger.info('Redis connected');
  } catch (err) {
    logger.warn({ err }, 'Redis unavailable — continuing without cache');
  }
  return client;
}

export function redis() {
  return client;
}
