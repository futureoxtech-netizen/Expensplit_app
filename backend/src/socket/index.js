import { Server } from 'socket.io';
import { verifyAccess } from '../utils/jwt.js';
import { logger } from '../config/logger.js';

let io = null;

export function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: { origin: true, credentials: true },
    transports: ['websocket', 'polling'],
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) return next(new Error('Unauthorized'));
    try {
      const decoded = verifyAccess(token);
      socket.user = { id: decoded.sub, email: decoded.email };
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    logger.debug({ userId: socket.user.id }, 'socket connected');
    socket.join(`user:${socket.user.id}`);

    socket.on('group:join', ({ groupId }) => {
      if (groupId) socket.join(`group:${groupId}`);
    });

    socket.on('group:leave', ({ groupId }) => {
      if (groupId) socket.leave(`group:${groupId}`);
    });

    socket.on('disconnect', () => {
      logger.debug({ userId: socket.user.id }, 'socket disconnected');
    });
  });

  return io;
}

export function emitToGroup(groupId, event, payload) {
  if (!io) return;
  io.to(`group:${groupId.toString()}`).emit(event, payload);
}

export function emitToUser(userId, event, payload) {
  if (!io) return;
  io.to(`user:${userId.toString()}`).emit(event, payload);
}
