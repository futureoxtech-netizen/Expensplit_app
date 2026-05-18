import { Activity } from './activity.model.js';
import { emitToGroup } from '../../socket/index.js';

export const activityService = {
  async log({ groupId, actor, type, message, meta = {} }) {
    const item = await Activity.create({ group: groupId, actor, type, message, meta });
    if (groupId) emitToGroup(groupId, 'activity:new', { groupId: groupId.toString(), activityId: item._id.toString() });
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

  async listForUser({ groupIds, page = 1, limit = 50 }) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Activity.find({ group: { $in: groupIds } })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('actor', 'name avatarUrl')
        .populate('group', 'name coverColor')
        .lean(),
      Activity.countDocuments({ group: { $in: groupIds } }),
    ]);
    return { items, total, page, limit, hasMore: skip + items.length < total };
  },
};
