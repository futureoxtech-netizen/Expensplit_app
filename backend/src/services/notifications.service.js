/**
 * Unified notification gateway.
 *
 * Rule:
 *   1. If the recipient has a live socket connection, fire a real-time
 *      `notification:new` socket event (instant in-app delivery).
 *   2. Always also dispatch a OneSignal push notification (so the user
 *      sees a system-tray notification on lock-screen / when the app is
 *      backgrounded). The Flutter client de-duplicates by `data.id`
 *      when it receives both.
 *
 * If OneSignal credentials are not configured the service silently no-ops
 * the push side, so local development keeps working.
 */
import { env } from '../config/env.js';
import { logger } from '../config/logger.js';
import { emitToUser, isUserConnected } from '../socket/index.js';
import { User } from '../modules/users/user.model.js';

const ONESIGNAL_ENDPOINT = 'https://api.onesignal.com/notifications';

function hasOneSignal() {
  return Boolean(env.ONESIGNAL_APP_ID && env.ONESIGNAL_REST_API_KEY);
}

/**
 * Low-level OneSignal HTTP call.  Uses external user IDs (the backend
 * Mongo user id) so we don't have to track device player ids ourselves.
 */
async function callOneSignal(payload) {
  if (!hasOneSignal()) return null;
  try {
    const res = await fetch(ONESIGNAL_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${env.ONESIGNAL_REST_API_KEY}`,
        accept: 'application/json',
      },
      body: JSON.stringify({ app_id: env.ONESIGNAL_APP_ID, ...payload }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      logger.warn({ status: res.status, body }, 'OneSignal push failed');
    }
    return body;
  } catch (err) {
    logger.warn({ err: err.message }, 'OneSignal push error');
    return null;
  }
}

/**
 * Send a notification to a single user.
 *
 * @param {string|object} userId  Mongo user id.
 * @param {object} opts
 * @param {string} opts.title     Notification title.
 * @param {string} opts.message   Body text.
 * @param {object} [opts.data]    Arbitrary JSON payload (groupId, expenseId,
 *                                etc.) that the client uses for deep-linking
 *                                and de-duplication.
 * @param {string} [opts.type]    Logical event type (expense.created, …).
 */
export async function notifyUser(userId, { title, message, data = {}, type } = {}) {
  if (!userId) return;
  const id = userId.toString();
  const payload = {
    id: data.id ?? `${type ?? 'evt'}:${Date.now()}:${Math.random().toString(36).slice(2, 7)}`,
    type: type ?? 'generic',
    title,
    message,
    data,
    createdAt: new Date().toISOString(),
  };

  // 1. Always push to the in-app socket stream — clients use this to
  //    refresh state and to show a snackbar / banner when active.
  if (isUserConnected(id)) {
    emitToUser(id, 'notification:new', payload);
  }

  // 2. Also fire the OneSignal push so backgrounded / killed apps wake up.
  //    The mobile client filters out duplicates that already arrived via
  //    socket by checking `data.id`.
  if (hasOneSignal()) {
    await callOneSignal({
      include_aliases: { external_id: [id] },
      target_channel: 'push',
      headings: { en: title },
      contents: { en: message },
      data: { ...data, type: payload.type, id: payload.id },
    });
  }
}

/**
 * Fan-out helper. Skips a `skipUserId` (usually the actor that produced
 * the event — they don't need to be notified of their own action).
 */
export async function notifyUsers(userIds, opts, skipUserId = null) {
  const skip = skipUserId ? skipUserId.toString() : null;
  const unique = [...new Set(userIds.map((u) => u.toString()).filter((u) => u && u !== skip))];
  if (unique.length === 0) return;
  await Promise.all(unique.map((uid) => notifyUser(uid, opts)));
}

/**
 * Convenience: notify every member of a group except the actor.
 */
export async function notifyGroup(group, opts, actorUserId = null) {
  const memberIds = (group.members ?? [])
    .map((m) => (m.user?._id ? m.user._id : m.user))
    .filter(Boolean);
  await notifyUsers(memberIds, opts, actorUserId);
}

/**
 * Look up the active display name we should show inside a push body.
 */
export async function actorName(userId) {
  if (!userId) return 'Someone';
  try {
    const u = await User.findById(userId).select('name').lean();
    return u?.name ?? 'Someone';
  } catch {
    return 'Someone';
  }
}
