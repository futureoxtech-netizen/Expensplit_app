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
    const groupIds = await Group.find({ 'members.user': req.user.id }).distinct('_id');
    const data = await activityService.listForUser({
      groupIds,
      page: Number(req.query.page) || 1,
      limit: Math.min(Number(req.query.limit) || 50, 100),
    });
    res.json({ ok: true, data });
  }),
};
