import mongoose from 'mongoose';
import { Settlement } from './settlement.model.js';
import { Group } from '../groups/group.model.js';
import { BadRequest, Forbidden, NotFound } from '../../utils/errors.js';
import { emitToGroup } from '../../socket/index.js';
import { activityService } from '../activity/activity.service.js';
import { notifyUser, actorName } from '../../services/notifications.service.js';

async function assertMember(groupId, userId) {
  if (!mongoose.isValidObjectId(groupId)) throw NotFound('Group not found');
  const group = await Group.findById(groupId);
  if (!group) throw NotFound('Group not found');
  if (!group.isMember(userId)) throw Forbidden('Not a group member');
  return group;
}

export const settlementService = {
  async create({ userId, payload }) {
    if (payload.amount <= 0) throw BadRequest('Amount must be positive');
    if (payload.from === payload.to) throw BadRequest('from and to must differ');
    const group = await assertMember(payload.groupId, userId);
    if (!group.isMember(payload.from) || !group.isMember(payload.to)) {
      throw BadRequest('Both parties must be group members');
    }
    const settlement = await Settlement.create({
      group: group._id,
      from: payload.from,
      to: payload.to,
      amount: Math.round(payload.amount * 100) / 100,
      currency: payload.currency || group.currency,
      method: payload.method || 'cash',
      note: payload.note || '',
      settledAt: payload.settledAt || new Date(),
      createdBy: userId,
    });
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'settlement.created',
      message: `recorded a settlement of ${settlement.currency} ${settlement.amount.toFixed(2)}`,
      meta: { settlementId: settlement._id.toString() },
    });
    emitToGroup(group._id, 'settlement:created', {
      groupId: group._id.toString(),
      settlementId: settlement._id.toString(),
    });

    // Notify the *recipient* of the payment. If the actor is the `from`
    // party (the most common case — "I just paid you back"), tell `to`.
    // If the actor logged it on behalf of someone else, notify both.
    const actor = await actorName(userId);
    const recipients = new Set();
    if (userId.toString() === payload.from.toString()) {
      recipients.add(payload.to);
    } else if (userId.toString() === payload.to.toString()) {
      recipients.add(payload.from);
    } else {
      recipients.add(payload.from);
      recipients.add(payload.to);
    }
    for (const uid of recipients) {
      notifyUser(uid, {
        title: group.name,
        message: `${actor} recorded a payment of ${settlement.currency} ${settlement.amount.toFixed(2)}`,
        type: 'settlement.created',
        data: {
          groupId: group._id.toString(),
          settlementId: settlement._id.toString(),
          route: `/groups/${group._id.toString()}`,
        },
      }).catch(() => {});
    }

    return settlement.populate(['from', 'to']);
  },

  async listByGroup({ userId, groupId, page = 1, limit = 50 }) {
    await assertMember(groupId, userId);
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Settlement.find({ group: groupId })
        .sort({ settledAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('from', 'name avatarUrl')
        .populate('to', 'name avatarUrl')
        .lean(),
      Settlement.countDocuments({ group: groupId }),
    ]);
    return { items, total, page, limit, hasMore: skip + items.length < total };
  },
};
