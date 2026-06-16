import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes.js';
import userRoutes from '../modules/users/user.routes.js';
import groupRoutes from '../modules/groups/group.routes.js';
import expenseRoutes from '../modules/expenses/expense.routes.js';
import settlementRoutes from '../modules/settlements/settlement.routes.js';
import activityRoutes from '../modules/activity/activity.routes.js';
import personalRoutes from '../modules/personal/personal.routes.js';
import goalRoutes from '../modules/goals/goal.routes.js';
import reactionRoutes from '../modules/reactions/reaction.routes.js';
import uploadRoutes from '../modules/uploads/upload.routes.js';
import appConfigRoutes from '../modules/appConfig/appConfig.routes.js';
import syncRoutes from '../modules/sync/sync.routes.js';
import loanRoutes from '../modules/loans/loan.routes.js';
import guestContactRoutes from '../modules/loans/guest_contact.routes.js';

export const router = Router();

router.get('/', (_req, res) => {
  res.json({
    ok: true,
    name: 'Expense API',
    version: '0.1.0',
    endpoints: ['/auth', '/users', '/groups', '/expenses', '/settlements', '/activity'],
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/groups', groupRoutes);
router.use('/expenses', expenseRoutes);
router.use('/settlements', settlementRoutes);
router.use('/activity', activityRoutes);
router.use('/personal-expenses', personalRoutes);
router.use('/goals', goalRoutes);
router.use('/reactions', reactionRoutes);
router.use('/uploads', uploadRoutes);
router.use('/app', appConfigRoutes);
router.use('/sync', syncRoutes);
router.use('/loans', loanRoutes);
router.use('/guest-contacts', guestContactRoutes);
