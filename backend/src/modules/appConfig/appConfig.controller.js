import { asyncHandler } from '../../utils/asyncHandler.js';
import { appConfigService } from './appConfig.service.js';

export const appConfigController = {
  // Public: called by the mobile app on launch to decide whether to show a
  // soft or forced update prompt. Never requires auth so it works even when a
  // session has expired.
  checkVersion: asyncHandler(async (req, res) => {
    const platform = String(req.query.platform || 'android').toLowerCase();
    const version = String(req.query.version || '0.0.0');
    const result = await appConfigService.checkVersion({ platform, version });
    res.json({ ok: true, data: result });
  }),
};
