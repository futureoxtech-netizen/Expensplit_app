import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { userController } from './user.controller.js';

const router = Router();

router.use(requireAuth);

router.get('/me', userController.getMe);
router.patch('/me', userController.updateMe);
router.get('/search', userController.search);
router.post('/me/fcm-token', userController.registerFcmToken);

export default router;
