import { Router } from 'express';
import { validate } from '../../middleware/validate.js';
import { requireAuth } from '../../middleware/auth.js';
import { authController } from './auth.controller.js';
import {
  loginSchema,
  refreshSchema,
  registerSchema,
  sendOtpSchema,
  googleAuthSchema,
  forgotOtpSchema,
  verifyResetOtpSchema,
  resetPasswordSchema,
} from './auth.validation.js';

const router = Router();

// Registration flow
router.post('/send-otp', validate(sendOtpSchema), authController.sendOtp);
router.post('/register', validate(registerSchema), authController.register);

// Login
router.post('/login', validate(loginSchema), authController.login);

// Google OAuth
router.post('/google', validate(googleAuthSchema), authController.googleAuth);

// Forgot password flow
router.post('/forgot-password/send-otp', validate(forgotOtpSchema), authController.sendForgotOtp);
router.post('/forgot-password/verify-otp', validate(verifyResetOtpSchema), authController.verifyResetOtp);
router.post('/forgot-password/reset', validate(resetPasswordSchema), authController.resetPassword);

// Session management
router.post('/refresh', validate(refreshSchema), authController.refresh);
router.post('/logout', requireAuth, authController.logout);
router.get('/me', requireAuth, authController.me);

export default router;
