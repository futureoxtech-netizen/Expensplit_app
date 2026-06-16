import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { guestContactController } from './guest_contact.controller.js';

const router = Router();

router.use(requireAuth);

router.get('/', guestContactController.list);
router.post('/', guestContactController.create);
router.patch('/:id', guestContactController.update);
router.delete('/:id', guestContactController.delete);

export default router;
