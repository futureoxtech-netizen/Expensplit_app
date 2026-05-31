import { asyncHandler } from '../../utils/asyncHandler.js';
import { activityService } from './activity.service.js';
import { Group } from '../groups/group.model.js';
import { Forbidden, NotFound } from '../../utils/errors.js';
import mongoose from 'mongoose';

export const activityController = {
  byGroup: asyncHandler(async (req, res) => {
    if (!mongoose.isValidObjectId(req.params.groupId)) throw NotFound('Group not found');
    const group = await Group.findById(req.params.groupId);
    if (!group) throw NotFound('Group not found');
    if (!group.isMember(req.user.id)) throw Forbidden('Not a group member');
    const data = await activityService.listForGroup({
      groupId: group._id,
      page: Number(req.query.page) || 1,
      limit: Math.min(Number(req.query.limit) || 50, 100),
    });
    res.json({ ok: true, data });
  }),

  feed: asyncHandler(async (req, res) => {
    // Fetch groups where the user is a full member AND groups where they have
    // a pending invite. The service will filter pending-group activities to
    // group.invite only, so they see their own invitation but not unrelated
    // group activity they haven't been admitted to yet.
    const [groupIds, pendingGroupIds] = await Promise.all([
      Group.find({ 'members.user': req.user.id }).distinct('_id'),
      Group.find({ 'pendingMembers.user': req.user.id }).distinct('_id'),
    ]);
    const data = await activityService.listForUser({
      groupIds,
      pendingGroupIds,
      page: Number(req.query.page) || 1,
      limit: Math.min(Number(req.query.limit) || 50, 100),
    });
    res.json({ ok: true, data });
  }),
};
