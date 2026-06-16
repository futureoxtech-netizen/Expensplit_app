import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { groupController } from './group.controller.js';
import {
  createGroupSchema,
  joinByCodeSchema,
  updateGroupSchema,
  updateNotesSchema,
} from './group.validation.js';

const router = Router();
router.use(requireAuth);

router.post('/', validate(createGroupSchema), groupController.create);
router.get('/', groupController.list);
router.post('/join', validate(joinByCodeSchema), groupController.joinByCode);
// Must be declared before '/:id' so "invites" isn't swallowed as a group id.
router.get('/invites', groupController.listInvites);
router.get('/:id', groupController.getById);
router.patch('/:id', validate(updateGroupSchema), groupController.update);
router.patch('/:id/notes', validate(updateNotesSchema), groupController.updateNotes);
router.post('/:id/members', groupController.addMember);
router.post('/:id/placeholders', groupController.addPlaceholder);
router.delete('/:id/members/:memberId', groupController.removeMember);
router.post('/:id/invites/accept', groupController.acceptInvite);
router.post('/:id/invites/decline', groupController.declineInvite);
router.post('/:id/leave', groupController.leave);
router.delete('/:id', groupController.remove);
router.get('/:id/balances', groupController.balances);
router.get('/:id/payment-infos', groupController.listPaymentInfos);
router.post('/:id/payment-infos', groupController.addPaymentInfo);
router.patch('/:id/payment-infos/:infoId', groupController.updatePaymentInfo);
router.delete('/:id/payment-infos/:infoId', groupController.deletePaymentInfo);

export default router;
