import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { loanController } from './loan.controller.js';
import { createLoanSchema, recordPaymentSchema } from './loan.validation.js';

const router = Router();

router.use(requireAuth);

router.get('/', loanController.list);
router.post('/', validate(createLoanSchema), loanController.create);
router.get('/:id', loanController.getById);
router.delete('/:id', loanController.deleteLoan);
router.post('/:id/approve', loanController.approve);
router.post('/:id/reject', loanController.reject);
router.post('/:id/payments', validate(recordPaymentSchema), loanController.recordPayment);
router.delete('/:id/payments/:paymentId', loanController.deletePayment);

export default router;
