import { asyncHandler } from '../../utils/asyncHandler.js';
import { authService } from './auth.service.js';
import { User } from '../users/user.model.js';

export const authController = {
  sendOtp: asyncHandler(async (req, res) => {
    const result = await authService.sendOtp(req.body);
    res.json({ ok: true, data: result });
  }),

  register: asyncHandler(async (req, res) => {
    const result = await authService.register(req.body);
    res.status(201).json({ ok: true, data: result });
  }),

  login: asyncHandler(async (req, res) => {
    const result = await authService.login(req.body);
    res.json({ ok: true, data: result });
  }),

  googleAuth: asyncHandler(async (req, res) => {
    const result = await authService.googleAuth(req.body);
    res.json({ ok: true, data: result });
  }),

  sendForgotOtp: asyncHandler(async (req, res) => {
    const result = await authService.sendForgotOtp(req.body);
    res.json({ ok: true, data: result });
  }),

  verifyResetOtp: asyncHandler(async (req, res) => {
    const result = await authService.verifyResetOtp(req.body);
    res.json({ ok: true, data: result });
  }),

  resetPassword: asyncHandler(async (req, res) => {
    const result = await authService.resetPassword(req.body);
    res.json({ ok: true, data: result });
  }),

  refresh: asyncHandler(async (req, res) => {
    const result = await authService.refresh(req.body);
    res.json({ ok: true, data: result });
  }),

  logout: asyncHandler(async (req, res) => {
    await authService.logout({ userId: req.user.id, refreshToken: req.body.refreshToken });
    res.json({ ok: true });
  }),

  me: asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id);
    res.json({ ok: true, data: user?.toPublic() ?? null });
  }),
};
