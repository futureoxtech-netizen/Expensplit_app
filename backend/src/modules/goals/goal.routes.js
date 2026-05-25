import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as ctrl from './goal.controller.js';

const router = Router();
router.use(requireAuth);

// Goals CRUD
router.post('/',     ctrl.create);
router.get('/',      ctrl.list);
router.get('/:id',   ctrl.getOne);
router.patch('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);

// Contributions
router.post('/:id/contributions',              ctrl.addContribution);
router.patch('/:id/contributions/:cId',        ctrl.updateContribution);
router.delete('/:id/contributions/:cId',       ctrl.removeContribution);

export default router;
