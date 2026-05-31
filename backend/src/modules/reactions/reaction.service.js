import mongoose from 'mongoose';
import { Reaction, ALLOWED_REACTIONS } from './reaction.model.js';
import { Expense } from '../expenses/expense.model.js';
import { Settlement } from '../settlements/settlement.model.js';
import { Group } from '../groups/group.model.js';
import { BadRequest, Forbidden, NotFound } from '../../utils/errors.js';
import { emitToGroup } from '../../socket/index.js';
import { activityService } from '../activity/activity.service.js';
import { notifyUser, actorName } from '../../services/notifications.service.js';

/**
 * Resolve a polymorphic reaction target to the data we need: which group it
 * belongs to (for the membership check + realtime room) and who "owns" it
 * (for the courtesy notification). Throws NotFound for missing / deleted
 * targets so a reaction can never be attached to a phantom record.
 */
async function resolveTarget(targetType, targetId) {
  if (!mongoose.isValidObjectId(targetId)) throw NotFound('Item not found');
  if (targetType === 'expense') {
    const exp = await Expense.findById(targetId).select('group createdBy deletedAt description').lean();
    if (!exp || exp.deletedAt) throw NotFound('Expense not found');
    return { group: exp.group, ownerId: exp.createdBy, label: `"${exp.description}"`, route: `/expenses/${targetId}` };
  }
  const st = await Settlement.findById(targetId).select('group createdBy').lean();
  if (!st) throw NotFound('Settlement not found');
  return { group: st.group, ownerId: st.createdBy, label: 'a payment', route: `/groups/${st.group.toString()}` };
}

async function assertMember(groupId, userId) {
  const group = await Group.findById(groupId).select('members').lean();
  if (!group) throw NotFound('Group not found');
  const isMember = (group.members ?? []).some((m) => m.user.toString() === userId.toString());
  if (!isMember) throw Forbidden('Not a group member');
}

/**
 * Fold a flat list of reaction docs into per-emoji summaries:
 *   [{ emoji, count, users: [{ id, name, avatarUrl }] }]
 * sorted most-reacted first. Note we deliberately do NOT emit a `mine` flag —
 * the same summary is broadcast to every group member over the socket, so each
 * client decides "is this me?" locally from the `users` ids.
 */
function buildSummary(reactions) {
  const byEmoji = new Map();
  for (const r of reactions) {
    const entry = byEmoji.get(r.emoji) ?? { emoji: r.emoji, count: 0, users: [] };
    entry.count += 1;
    const u = r.user;
    if (u && typeof u === 'object' && u._id) {
      entry.users.push({ id: u._id.toString(), name: u.name ?? '', avatarUrl: u.avatarUrl ?? null });
    } else if (u) {
      entry.users.push({ id: u.toString(), name: '', avatarUrl: null });
    }
    byEmoji.set(r.emoji, entry);
  }
  // Stable, deterministic order: count desc, then palette order.
  return [...byEmoji.values()].sort(
    (a, b) => b.count - a.count || ALLOWED_REACTIONS.indexOf(a.emoji) - ALLOWED_REACTIONS.indexOf(b.emoji),
  );
}

export const reactionService = {
  /**
   * Bulk-load reaction summaries for many targets of one type in a single
   * query. Returns a Map keyed by targetId string. Used to enrich expense /
   * settlement list payloads without N round-trips.
   */
  async summariesByTarget({ targetType, ids }) {
    const result = new Map();
    if (!ids || ids.length === 0) return result;
    const reactions = await Reaction.find({ targetType, targetId: { $in: ids } })
      .populate('user', 'name avatarUrl')
      .lean();
    const grouped = new Map();
    for (const r of reactions) {
      const key = r.targetId.toString();
      const arr = grouped.get(key) ?? [];
      arr.push(r);
      grouped.set(key, arr);
    }
    for (const [key, arr] of grouped) result.set(key, buildSummary(arr));
    return result;
  },

  async summaryFor({ targetType, targetId }) {
    const map = await this.summariesByTarget({ targetType, ids: [targetId] });
    return map.get(targetId.toString()) ?? [];
  },

  /** Drop every reaction on a target — called when the target is deleted. */
  async purgeForTarget({ targetType, targetId }) {
    await Reaction.deleteMany({ targetType, targetId });
  },

  /**
   * Toggle/switch the caller's reaction on a target (WhatsApp semantics):
   *   • no existing reaction        → add `emoji`
   *   • existing, same emoji        → remove (toggle off)
   *   • existing, different emoji   → switch to `emoji`
   * Returns the fresh summary for the target.
   */
  async react({ userId, targetType, targetId, emoji }) {
    if (!ALLOWED_REACTIONS.includes(emoji)) throw BadRequest('Unsupported reaction');
    const { group, ownerId, label, route } = await resolveTarget(targetType, targetId);
    await assertMember(group, userId);

    const existing = await Reaction.findOne({ targetType, targetId, user: userId });
    let action;
    if (existing && existing.emoji === emoji) {
      await existing.deleteOne();
      action = 'removed';
    } else if (existing) {
      existing.emoji = emoji;
      await existing.save();
      action = 'switched';
    } else {
      try {
        await Reaction.create({ group, targetType, targetId, user: userId, emoji });
      } catch (err) {
        // Lost a race against the caller's own concurrent tap — the unique
        // index rejected the duplicate. Fall back to a switch so the latest
        // emoji wins instead of 500-ing.
        if (err?.code === 11000) {
          await Reaction.updateOne({ targetType, targetId, user: userId }, { $set: { emoji } });
        } else {
          throw err;
        }
      }
      action = 'added';
    }

    const reactions = await this.summaryFor({ targetType, targetId });
    emitToGroup(group, 'reaction:changed', {
      groupId: group.toString(),
      targetType,
      targetId: targetId.toString(),
      reactions,
    });

    // First time this user reacts to this item → record it in the group
    // activity feed so every member sees "X reacted 👍 to …". Switching emoji
    // or toggling off doesn't spawn new entries, which keeps the feed quiet.
    if (action === 'added') {
      activityService
        .log({
          groupId: group,
          actor: userId,
          type: 'reaction.added',
          message: `reacted ${emoji} to ${label}`,
          meta: { targetType, targetId: targetId.toString(), emoji, route },
        })
        .catch(() => {});
    }

    // Also ping the item's author directly — but never for a removal, and
    // never notify yourself for reacting to your own item.
    if (action !== 'removed' && ownerId && ownerId.toString() !== userId.toString()) {
      const actor = await actorName(userId);
      notifyUser(ownerId, {
        title: 'New reaction',
        message: `${actor} reacted ${emoji} to ${label}`,
        type: 'reaction.added',
        data: { groupId: group.toString(), targetType, targetId: targetId.toString(), route },
      }).catch(() => {});
    }

    return { action, reactions };
  },

  /**
   * Explicitly clear the caller's reaction on a target (idempotent — clearing
   * a target you never reacted to is a no-op that still returns the summary).
   */
  async clear({ userId, targetType, targetId }) {
    const { group } = await resolveTarget(targetType, targetId);
    await assertMember(group, userId);
    await Reaction.deleteOne({ targetType, targetId, user: userId });
    const reactions = await this.summaryFor({ targetType, targetId });
    emitToGroup(group, 'reaction:changed', {
      groupId: group.toString(),
      targetType,
      targetId: targetId.toString(),
      reactions,
    });
    return { reactions };
  },
};
