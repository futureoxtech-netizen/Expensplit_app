import mongoose from 'mongoose';
import { env } from './env.js';
import { logger } from './logger.js';

mongoose.set('strictQuery', true);

export async function connectMongo() {
  try {
    await mongoose.connect(env.MONGO_URI, { autoIndex: true });
    logger.info('Mongo connected');
  } catch (err) {
    logger.error({ err }, 'Mongo connection failed');
    throw err;
  }
}
