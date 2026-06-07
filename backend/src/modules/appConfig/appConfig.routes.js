import { Router } from 'express';
import { appConfigController } from './appConfig.controller.js';

const router = Router();

// Public — no auth. The app polls this on every launch.
router.get('/version', appConfigController.checkVersion);

export default router;
