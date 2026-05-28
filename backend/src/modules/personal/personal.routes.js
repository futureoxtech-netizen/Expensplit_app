import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as ctrl from './personal.controller.js';

const router = Router();
router.use(requireAuth);

router.post('/', ctrl.create);
router.get('/', ctrl.list);
router.get('/summary', ctrl.summary);
router.patch('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);

export default router;
