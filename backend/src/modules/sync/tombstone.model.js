import mongoose from 'mongoose';

// A record that a syncable entity was deleted, so offline clients can drop it
// from their local database on the next delta pull. `users` is the set of
// people who should receive this deletion (captured at delete time, since the
// entity — and its membership — may be gone by sync time).
const tombstoneSchema = new mongoose.Schema(
  {
    entityType: {
      type: String,
      required: true,
      enum: ['expense', 'settlement', 'group', 'personalExpense', 'goal', 'member', 'reaction'],
    },
    entityId: { type: String, required: true },
    groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group' },
    users: { type: [mongoose.Schema.Types.ObjectId], default: [], index: true },
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
    deletedAt: { type: Date, default: Date.now, index: true },
  },
  { timestamps: false },
);

tombstoneSchema.index({ users: 1, deletedAt: 1 });

export const Tombstone = mongoose.model('Tombstone', tombstoneSchema);

/**
 * Record a deletion so offline clients can reconcile it. Fire-and-forget safe:
 * callers may `.catch(() => {})` — a missed tombstone only means a client keeps
 * a stale row until the next full snapshot, never data loss on the server.
 *
 * @param {object} p
 * @param {string} p.entityType
 * @param {string} p.entityId
 * @param {*} [p.groupId]
 * @param {Array} [p.users]  recipient user ids
 * @param {object} [p.meta]
 */
export async function recordTombstone({ entityType, entityId, groupId, users = [], meta = {} }) {
  return Tombstone.create({
    entityType,
    entityId: String(entityId),
    groupId: groupId ?? undefined,
    users,
    meta,
    deletedAt: new Date(),
  });
}
