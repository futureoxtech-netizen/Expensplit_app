import { asyncHandler } from '../../utils/asyncHandler.js';
import { reactionService } from './reaction.service.js';

export const reactionController = {
  // Add / switch / toggle-off the caller's reaction on a target.
  react: asyncHandler(async (req, res) => {
    const data = await reactionService.react({ userId: req.user.id, ...req.body });
    res.json({ ok: true, data });
  }),

  // Remove the caller's reaction on a target.
  clear: asyncHandler(async (req, res) => {
    const data = await reactionService.clear({
      userId: req.user.id,
      targetType: req.params.targetType,
      targetId: req.params.targetId,
    });
    res.json({ ok: true, data });
  }),
};
