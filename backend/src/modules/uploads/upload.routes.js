import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { uploadMiddleware } from '../../middleware/upload.js';
import { uploadController } from './upload.controller.js';

const router = Router();
router.use(requireAuth);

router.post('/receipt', uploadMiddleware, uploadController.receipt);
router.delete('/receipt', uploadController.deleteReceipt);

export default router;
