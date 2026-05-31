import { Activity } from './activity.model.js';
import { emitToGroup, emitToUsers } from '../../socket/index.js';
import { Group } from '../groups/group.model.js';

export const activityService = {
  async log({ groupId, actor, type, message, meta = {} }) {
    const item = await Activity.create({ group: groupId, actor, type, message, meta });
    if (groupId) {
      const payload = {
        groupId: groupId.toString(),
        activityId: item._id.toString(),
        type,
      };
      // The `group:<id>` room only contains clients that are currently
      // viewing this group. Also fan out to every member's personal
      // `user:<id>` room so the global activity feed / unread badge
      // updates even for members who are on Home or haven't opened
      // this group during this session.
      emitToGroup(groupId, 'activity:new', payload);
      try {
        const group = await Group.findById(groupId).select('members.user').lean();
        const memberIds = (group?.members ?? [])
          .map((m) => (m.user?._id ? m.user._id : m.user))
          .filter(Boolean);
        emitToUsers(memberIds, 'activity:new', payload);
      } catch {
        // Non-fatal — group-room emit above already covers active viewers.
      }
    }
    return item;
  },

  async listForGroup({ groupId, page = 1, limit = 50 }) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Activity.find({ group: groupId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('actor', 'name avatarUrl')
        .lean(),
      Activity.countDocuments({ group: groupId }),
    ]);
    return { items, total, page, limit, hasMore: skip + items.length < total };
  },

  async listForUser({ groupIds, pendingGroupIds = [], page = 1, limit = 50 }) {
    const skip = (page - 1) * limit;
    // Build a query that includes:
    //  • All activities from groups the user is a full member of.
    //  • Only group.invite activities from groups where the user has a pending
    //    invite — so they can see the invitation in their Activity feed without
    //    seeing unrelated group activity they haven't been accepted into yet.
    const orClauses = [{ group: { $in: groupIds } }];
    if (pendingGroupIds.length) {
      // Only surface group.invite activities from groups where the user is
      // pending — they must not see other activity (expenses, balances, etc.)
      // until they accept. Use exact string match, not a regex, to be safe
      // across all MongoDB driver versions.
      orClauses.push({ group: { $in: pendingGroupIds }, type: 'group.invite' });
    }
    const filter = orClauses.length === 1 ? orClauses[0] : { $or: orClauses };
    const [items, total] = await Promise.all([
      Activity.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('actor', 'name avatarUrl')
        .populate('group', 'name coverColor')
        .lean(),
      Activity.countDocuments(filter),
    ]);
    return { items, total, page, limit, hasMore: skip + items.length < total };
  },
};
