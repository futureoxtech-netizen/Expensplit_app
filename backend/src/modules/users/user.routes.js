import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { userController } from './user.controller.js';

const router = Router();

router.use(requireAuth);

router.get('/me', userController.getMe);
router.patch('/me', userController.updateMe);
router.delete('/me', userController.deleteMe);
router.get('/search', userController.search);
router.post('/me/fcm-token', userController.registerFcmToken);
router.post('/me/push-subscription', userController.registerPushSubscription);
router.get('/friends-summary', userController.friendsSummary);
router.get('/friends/:friendId/transactions', userController.friendTransactions);

export default router;
