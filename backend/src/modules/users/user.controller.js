import { z } from 'zod';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { User } from './user.model.js';
import { NotFound } from '../../utils/errors.js';

const updateSchema = z.object({
  name: z.string().min(2).max(80).optional(),
  avatarUrl: z.string().url().optional(),
  currency: z.string().length(3).optional(),
  locale: z.string().optional(),
  bio: z.string().max(280).optional(),
});

export const userController = {
  getMe: asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id);
    if (!user) throw NotFound('User not found');
    res.json({ ok: true, data: user.toPublic() });
  }),

  updateMe: asyncHandler(async (req, res) => {
    const body = updateSchema.parse(req.body);
    const user = await User.findByIdAndUpdate(req.user.id, body, { new: true });
    res.json({ ok: true, data: user.toPublic() });
  }),

  search: asyncHandler(async (req, res) => {
    const q = String(req.query.q || '').trim();
    if (q.length < 2) return res.json({ ok: true, data: [] });
    const users = await User.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
    })
      .limit(20)
      .lean();
    res.json({
      ok: true,
      data: users.map((u) => ({
        id: u._id.toString(),
        name: u.name,
        email: u.email,
        avatarUrl: u.avatarUrl,
      })),
    });
  }),

  registerFcmToken: asyncHandler(async (req, res) => {
    const token = String(req.body?.token || '').trim();
    if (token) {
      await User.findByIdAndUpdate(req.user.id, { $addToSet: { fcmTokens: token } });
    }
    res.json({ ok: true });
  }),
};
