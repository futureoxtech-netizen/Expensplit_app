import { Activity } from './activity.model.js';
import { emitToGroup, emitToUsers } from '../../socket/index.js';
import { Group } from '../groups/group.model.js';

export const activityService = {
  async log({ groupId, actor, type, message, meta = {}, recipients = [] }) {
    const item = await Activity.create({ group: groupId, actor, type, message, meta, recipients });
    const payload = {
      activityId: item._id.toString(),
      type,
      ...(groupId ? { groupId: groupId.toString() } : {}),
    };
    if (groupId) {
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
    // Recipient-scoped activities (loans, group-deleted) have no group room, so
    // fan out directly to each recipient's personal room.
    if (recipients.length) {
      emitToUsers(recipients, 'activity:new', payload);
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

  async listForUser({ userId, groupIds, pendingGroupIds = [], page = 1, limit = 50 }) {
    const skip = (page - 1) * limit;
    // Build a query that includes:
    //  • All activities from groups the user is a full member of.
    //  • Recipient-scoped activities addressed directly to the user (loan
    //    events, "group deleted" trace) which have no group.
    //  • Only group.invite activities from groups where the user has a pending
    //    invite — so they can see the invitation in their Activity feed without
    //    seeing unrelated group activity they haven't been accepted into yet.
    const orClauses = [{ group: { $in: groupIds } }];
    if (userId) orClauses.push({ recipients: userId });
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
