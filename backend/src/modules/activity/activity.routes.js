import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { activityController } from './activity.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/feed', activityController.feed);
router.get('/group/:groupId', activityController.byGroup);

export default router;
