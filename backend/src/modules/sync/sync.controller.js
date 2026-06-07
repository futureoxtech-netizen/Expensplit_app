import { asyncHandler } from '../../utils/asyncHandler.js';
import { syncService } from './sync.service.js';

export const syncController = {
  // GET /api/v1/sync?since=<ISO>
  pull: asyncHandler(async (req, res) => {
    const data = await syncService.pull({
      userId: req.user.id,
      since: req.query.since,
      limit: req.query.limit,
    });
    res.json({ ok: true, data });
  }),
};
