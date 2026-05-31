import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { expenseController } from './expense.controller.js';
import { createExpenseSchema, updateExpenseSchema } from './expense.validation.js';

const router = Router();
router.use(requireAuth);

router.post('/', validate(createExpenseSchema), expenseController.create);
router.get('/feed', expenseController.feed);
router.get('/analytics', expenseController.analytics);
router.get('/report', expenseController.report);
router.get('/group/:groupId', expenseController.listByGroup);
router.get('/group/:groupId/transactions', expenseController.groupTransactions);
router.get('/:id', expenseController.getById);
router.patch('/:id', validate(updateExpenseSchema), expenseController.update);
router.delete('/:id', expenseController.remove);

export default router;
