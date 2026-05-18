import { asyncHandler } from '../../utils/asyncHandler.js';
import { settlementService } from './settlement.service.js';

export const settlementController = {
  create: asyncHandler(async (req, res) => {
    const settlement = await settlementService.create({ userId: req.user.id, payload: req.body });
    res.status(201).json({ ok: true, data: settlement });
  }),

  listByGroup: asyncHandler(async (req, res) => {
    const page = Number(req.query.page) || 1;
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const data = await settlementService.listByGroup({
      userId: req.user.id,
      groupId: req.params.groupId,
      page,
      limit,
    });
    res.json({ ok: true, data });
  }),
};
