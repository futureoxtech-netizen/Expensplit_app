import http from 'http';
import { app } from './src/app.js';
import { env } from './src/config/env.js';
import { connectMongo } from './src/config/db.js';
import { syncOfflineIndexes } from './src/config/syncIndexes.js';
import { initSocket } from './src/socket/index.js';
import { logger } from './src/config/logger.js';

const server = http.createServer(app);

async function bootstrap() {
  await connectMongo();
  await syncOfflineIndexes();
  initSocket(server);

  server.listen(env.PORT, () => {
    logger.info(`API ready on http://localhost:${env.PORT}`);
  });
}

bootstrap().catch((err) => {
  logger.error({ err }, 'failing to start server');
  process.exit(1);
});

const shutdown = (signal) => {
  logger.info(`Received ${signal}, shutting down`);
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 10_000).unref();
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
