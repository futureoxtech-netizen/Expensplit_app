import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { reactionController } from './reaction.controller.js';
import { toggleReactionSchema, targetParamsSchema } from './reaction.validation.js';

const router = Router();
router.use(requireAuth);

router.post('/', validate(toggleReactionSchema), reactionController.react);
// Idempotent set (same body shape as toggle) — the offline-first client path.
router.post('/set', validate(toggleReactionSchema), reactionController.set);
router.delete(
  '/:targetType/:targetId',
  validate(targetParamsSchema, 'params'),
  reactionController.clear,
);

export default router;
