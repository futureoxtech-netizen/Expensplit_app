import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { syncController } from './sync.controller.js';

const router = Router();
router.use(requireAuth);

// Delta pull: everything visible to the user changed since ?since=<ISO>.
router.get('/', syncController.pull);

export default router;
