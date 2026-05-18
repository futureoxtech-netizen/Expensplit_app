import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { settlementController } from './settlement.controller.js';
import { createSettlementSchema } from './settlement.validation.js';

const router = Router();
router.use(requireAuth);

router.post('/', validate(createSettlementSchema), settlementController.create);
router.get('/group/:groupId', settlementController.listByGroup);

export default router;
