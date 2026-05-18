import { Router } from 'express';
import { validate } from '../../middleware/validate.js';
import { requireAuth } from '../../middleware/auth.js';
import { authController } from './auth.controller.js';
import { loginSchema, refreshSchema, registerSchema } from './auth.validation.js';

const router = Router();

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);
router.post('/refresh', validate(refreshSchema), authController.refresh);
router.post('/logout', requireAuth, authController.logout);
router.get('/me', requireAuth, authController.me);

export default router;
