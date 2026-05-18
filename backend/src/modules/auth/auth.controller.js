import { asyncHandler } from '../../utils/asyncHandler.js';
import { authService } from './auth.service.js';

export const authController = {
  register: asyncHandler(async (req, res) => {
    const result = await authService.register(req.body);
    res.status(201).json({ ok: true, data: result });
  }),

  login: asyncHandler(async (req, res) => {
    const result = await authService.login(req.body);
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
    const { User } = await import('../users/user.model.js');
    const user = await User.findById(req.user.id);
    res.json({ ok: true, data: user?.toPublic() ?? null });
  }),
};
