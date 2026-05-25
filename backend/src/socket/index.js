import { Server } from 'socket.io';
import { verifyAccess } from '../utils/jwt.js';
import { logger } from '../config/logger.js';

let io = null;

// userId -> Set<socketId>. A user with at least one live socket is "online".
const userSockets = new Map();

function addUserSocket(userId, socketId) {
  const set = userSockets.get(userId) ?? new Set();
  set.add(socketId);
  userSockets.set(userId, set);
}

function removeUserSocket(userId, socketId) {
  const set = userSockets.get(userId);
  if (!set) return;
  set.delete(socketId);
  if (set.size === 0) userSockets.delete(userId);
}

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
    const uid = socket.user.id.toString();
    logger.debug({ userId: uid }, 'socket connected');
    addUserSocket(uid, socket.id);
    socket.join(`user:${uid}`);

    socket.on('group:join', ({ groupId }) => {
      if (groupId) socket.join(`group:${groupId}`);
    });

    socket.on('group:leave', ({ groupId }) => {
      if (groupId) socket.leave(`group:${groupId}`);
    });

    socket.on('disconnect', () => {
      logger.debug({ userId: uid }, 'socket disconnected');
      removeUserSocket(uid, socket.id);
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

/**
 * Fan out to a list of user-rooms in one call. Use this when an event
 * needs to reach every member of a group regardless of whether they've
 * joined the `group:<id>` socket room yet (e.g. they're on Home and
 * haven't opened the group during this session).
 */
export function emitToUsers(userIds, event, payload) {
  if (!io || !Array.isArray(userIds) || userIds.length === 0) return;
  const rooms = [];
  const seen = new Set();
  for (const id of userIds) {
    if (!id) continue;
    const key = id.toString();
    if (seen.has(key)) continue;
    seen.add(key);
    rooms.push(`user:${key}`);
  }
  if (rooms.length === 0) return;
  io.to(rooms).emit(event, payload);
}

/**
 * Returns true when the given user has at least one active socket.
 * Used by the notifications service to skip push when the in-app
 * channel will deliver instantly.
 */
export function isUserConnected(userId) {
  if (!userId) return false;
  return userSockets.has(userId.toString());
}
