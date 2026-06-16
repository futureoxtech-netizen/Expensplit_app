import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { User } from './user.model.js';
import { Group } from '../groups/group.model.js';
import { Expense } from '../expenses/expense.model.js';
import { Settlement } from '../settlements/settlement.model.js';
import { Activity } from '../activity/activity.model.js';
import { Otp } from '../auth/otp.model.js';
import { DeletedAccount } from '../auth/deleted_account.model.js';
import { PersonalExpense } from '../personal/personal.model.js';
import { NotFound, BadRequest } from '../../utils/errors.js';
import { uploadToS3, deleteManyFromS3 } from '../../middleware/upload.js';
import { effectivePayers, pairwiseNetForExpense } from '../../utils/expensePayers.js';
import { PAYMENT_TYPES } from '../../utils/paymentFields.js';

const updateSchema = z.object({
  name: z.string().min(2).max(80).optional(),
  avatarUrl: z.string().url().optional(),
  currency: z.string().length(3).optional(),
  locale: z.string().optional(),
  bio: z.string().max(280).optional(),
  groupInvitePolicy: z.enum(['anyone', 'approval']).optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8).max(128),
});

// Shared validation for a payment method / payment info payload. `accountNumber`
// is required because it's the actual "where to send money" value; everything
// else is optional context. Exported so the groups module reuses the exact
// same rules for shared in-group payment info.
export const paymentInputSchema = z.object({
  type: z.enum(PAYMENT_TYPES),
  label: z.string().trim().max(60).optional().default(''),
  accountName: z.string().trim().max(80).optional().default(''),
  accountNumber: z.string().trim().min(1, 'Account number / handle is required').max(120),
  bankName: z.string().trim().max(80).optional().default(''),
  note: z.string().trim().max(200).optional().default(''),
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

  // PATCH /users/me/password — change password while logged in.
  // Verifies the current password before setting the new one. Google-only
  // accounts (no passwordHash) are rejected with a clear, actionable code.
  changePassword: asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);

    // passwordHash is `select: false`, so load it explicitly.
    const user = await User.findById(req.user.id).select('+passwordHash');
    if (!user) throw NotFound('User not found');

    if (!user.passwordHash) {
      throw BadRequest(
        'This account signs in with Google and has no password to change.',
        'USE_GOOGLE',
      );
    }

    const matches = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!matches) throw BadRequest('Your current password is incorrect.', 'WRONG_PASSWORD');

    const sameAsOld = await bcrypt.compare(newPassword, user.passwordHash);
    if (sameAsOld) {
      throw BadRequest(
        'Your new password must be different from your current one.',
        'SAME_PASSWORD',
      );
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();

    // Note: we intentionally keep existing refresh tokens valid so the user
    // stays signed in on this device after changing their password.
    res.json({ ok: true, message: 'Password updated successfully' });
  }),

  // ── Payment methods ─────────────────────────────────────────────────────────
  // All three return the full updated user (toPublic), so the client just
  // replaces its cached user — no separate list endpoint needed.
  addPaymentMethod: asyncHandler(async (req, res) => {
    const data = paymentInputSchema.parse(req.body);
    const user = await User.findById(req.user.id);
    if (!user) throw NotFound('User not found');
    if (user.paymentMethods.length >= 20) {
      throw BadRequest('You can save up to 20 payment methods.', 'PAYMENT_METHOD_LIMIT');
    }
    user.paymentMethods.push(data);
    await user.save();
    res.status(201).json({ ok: true, data: user.toPublic() });
  }),

  updatePaymentMethod: asyncHandler(async (req, res) => {
    const data = paymentInputSchema.parse(req.body);
    const user = await User.findById(req.user.id);
    if (!user) throw NotFound('User not found');
    const method = user.paymentMethods.id(req.params.methodId);
    if (!method) throw NotFound('Payment method not found');
    method.set(data);
    await user.save();
    res.json({ ok: true, data: user.toPublic() });
  }),

  deletePaymentMethod: asyncHandler(async (req, res) => {
    const user = await User.findById(req.user.id);
    if (!user) throw NotFound('User not found');
    const method = user.paymentMethods.id(req.params.methodId);
    if (!method) throw NotFound('Payment method not found');
    method.deleteOne();
    await user.save();
    res.json({ ok: true, data: user.toPublic() });
  }),

  search: asyncHandler(async (req, res) => {
    const q = String(req.query.q || '').trim();
    if (q.length < 2) return res.json({ ok: true, data: [] });
    const users = await User.find({
      isPlaceholder: { $ne: true },
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

  // POST /users/me/avatar  (multipart/form-data, field: "image")
  uploadAvatar: asyncHandler(async (req, res) => {
    if (!req.file) throw BadRequest('No image file provided');
    const url = await uploadToS3(req.file.buffer, req.file.mimetype, 'avatars');
    if (!url) throw BadRequest('Image upload failed — please try again');
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { avatarUrl: url },
      { new: true },
    );
    res.json({ ok: true, data: user.toPublic() });
  }),

  registerFcmToken: asyncHandler(async (req, res) => {
    const token = String(req.body?.token || '').trim();
    if (token) {
      await User.findByIdAndUpdate(req.user.id, { $addToSet: { fcmTokens: token } });
    }
    res.json({ ok: true });
  }),

  // Called by the Flutter client after OneSignal hands us a subscription id.
  // Stored mainly for debugging/diagnostics — the primary push delivery path
  // targets external_id == user._id, which the client sets on login.
  registerPushSubscription: asyncHandler(async (req, res) => {
    const subscriptionId = String(req.body?.subscriptionId || req.body?.playerId || '').trim();
    if (subscriptionId) {
      await User.findByIdAndUpdate(req.user.id, {
        $addToSet: { oneSignalIds: subscriptionId },
      });
    }
    res.json({ ok: true });
  }),

  friendsSummary: asyncHandler(async (req, res) => {
    const userId = req.user.id.toString();

    const groups = await Group.find({ 'members.user': userId, archived: false })
      .populate('members.user', 'name email avatarUrl isPlaceholder')
      .lean();

    const netByFriend = new Map();    // friendId -> total net amount
    const friendUserMap = new Map();  // friendId -> user object
    const groupsByFriend = new Map(); // friendId -> [{groupId, groupName, net}]
    const placeholderIds = new Set(); // guest members — excluded from Friends

    for (const group of groups) {
      // Collect friend info from members
      for (const m of group.members) {
        if (!m.user) continue; // user deleted their account
        const mid = (m.user._id ?? m.user).toString();
        // Guests (placeholders) live inside group balances, not the global
        // Friends list — track them so we can drop them from the result.
        if (m.user.isPlaceholder) {
          placeholderIds.add(mid);
          continue;
        }
        if (mid !== userId && m.user.name && !friendUserMap.has(mid)) {
          friendUserMap.set(mid, m.user);
        }
      }

      const expenses = await Expense.find({ group: group._id, deletedAt: null }).lean();
      const settlements = await Settlement.find({ group: group._id }).lean();

      // pairwise[friendId] = net (positive = friend owes me, negative = I owe friend)
      const pairwise = new Map();

      for (const exp of expenses) {
        const payers = effectivePayers(exp);
        const totalPaid = payers.reduce((a, p) => a + p.amount, 0);
        if (totalPaid <= 0) continue; // all payers deleted their accounts — skip
        // Allocate each sharer's debt across the payers in proportion to how
        // much each paid (handles single- and multi-payer expenses alike).
        for (const share of exp.shares) {
          if (!share.user) continue;
          const debtor = share.user.toString();
          for (const p of payers) {
            const payer = p.user.toString();
            if (payer === debtor) continue; // never owe yourself
            const portion = share.amount * (p.amount / totalPaid);
            if (payer === userId) {
              // I paid this slice — the sharer owes me.
              pairwise.set(debtor, (pairwise.get(debtor) ?? 0) + portion);
            } else if (debtor === userId) {
              // Someone else paid this slice of my share — I owe them.
              pairwise.set(payer, (pairwise.get(payer) ?? 0) - portion);
            }
          }
        }
      }

      for (const s of settlements) {
        const from = s.from.toString();
        const to = s.to.toString();
        if (from === userId) {
          // I paid friend back — my debt decreases
          pairwise.set(to, (pairwise.get(to) ?? 0) + s.amount);
        } else if (to === userId) {
          // Friend paid me back — their debt decreases
          pairwise.set(from, (pairwise.get(from) ?? 0) - s.amount);
        }
      }

      // Merge into global totals
      for (const [friendId, amt] of pairwise) {
        netByFriend.set(friendId, (netByFriend.get(friendId) ?? 0) + amt);
        const rounded = Math.round(amt * 100) / 100;
        if (Math.abs(rounded) > 0.001) {
          if (!groupsByFriend.has(friendId)) groupsByFriend.set(friendId, []);
          groupsByFriend.get(friendId).push({
            groupId: group._id.toString(),
            groupName: group.name,
            net: rounded,
          });
        }
      }
    }

    const result = [...netByFriend.entries()]
      .filter(([friendId]) => !placeholderIds.has(friendId))
      .map(([friendId, net]) => {
        const u = friendUserMap.get(friendId);
        return {
          userId: friendId,
          user: {
            id: friendId,
            name: u?.name ?? 'Unknown',
            email: u?.email ?? '',
            avatarUrl: u?.avatarUrl ?? null,
          },
          net: Math.round(net * 100) / 100,
          groups: (groupsByFriend.get(friendId) ?? []).sort(
            (a, b) => Math.abs(b.net) - Math.abs(a.net),
          ),
        };
      })
      .sort((a, b) => Math.abs(b.net) - Math.abs(a.net));

    res.json({ ok: true, data: result });
  }),

  friendTransactions: asyncHandler(async (req, res) => {
    const userId = req.user.id.toString();
    const friendId = req.params.friendId;

    // Shared groups
    const groups = await Group.find({
      'members.user': { $all: [userId, friendId], },
      archived: false,
    }).select('_id name coverColor').lean();

    const groupMap = new Map(groups.map((g) => [g._id.toString(), g]));

    // Expenses in shared groups involving both parties
    const expenses = await Expense.find({
      group: { $in: groups.map((g) => g._id) },
      deletedAt: null,
      $or: [
        { paidBy: userId, 'shares.user': friendId },
        { paidBy: friendId, 'shares.user': userId },
        { 'payers.user': userId, 'shares.user': friendId },
        { 'payers.user': friendId, 'shares.user': userId },
      ],
    })
      .sort({ spentAt: -1 })
      .populate('paidBy', 'name avatarUrl')
      .lean();

    // Settlements between the two users in shared groups
    const settlements = await Settlement.find({
      group: { $in: groups.map((g) => g._id) },
      $or: [
        { from: userId, to: friendId },
        { from: friendId, to: userId },
      ],
    })
      .sort({ settledAt: -1 })
      .lean();

    const expenseItems = expenses.map((exp) => {
      // Positive → friend owes me; negative → I owe friend. Handles
      // single- and multi-payer expenses via proportional allocation.
      const net = pairwiseNetForExpense(exp, userId, friendId);
      const grp = groupMap.get(exp.group.toString());
      return {
        type: 'expense',
        id: exp._id.toString(),
        description: exp.description,
        groupId: exp.group.toString(),
        groupName: grp?.name ?? '',
        groupColor: grp?.coverColor ?? '#6C5CE7',
        category: exp.category,
        currency: exp.currency,
        totalAmount: exp.amount,
        net: Math.round(net * 100) / 100,
        date: exp.spentAt,
      };
    }).filter((item) => Math.abs(item.net) > 0.001);

    const settlementItems = settlements.map((s) => {
      const from = s.from.toString();
      // from paid to, so if from=me I paid friend (reducing my debt) → net positive to me
      const net = from === userId ? s.amount : -s.amount;
      const grp = groupMap.get(s.group.toString());
      return {
        type: 'settlement',
        id: s._id.toString(),
        description: 'Payment',
        groupId: s.group.toString(),
        groupName: grp?.name ?? '',
        groupColor: grp?.coverColor ?? '#6C5CE7',
        category: 'settlement',
        currency: s.currency,
        totalAmount: s.amount,
        net: Math.round(net * 100) / 100,
        date: s.settledAt,
      };
    });

    const all = [...expenseItems, ...settlementItems].sort(
      (a, b) => new Date(b.date) - new Date(a.date),
    );

    // Paginate the merged stream in memory — the underlying expense /
    // settlement queries don't share a unified index so we can't paginate
    // them in the DB without overfetching. This caps the payload size for
    // power users without changing the existing response shape.
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 30));
    const skip = (page - 1) * limit;
    const slice = all.slice(skip, skip + limit);
    const hasMore = skip + slice.length < all.length;

    res.json({
      ok: true,
      data: {
        transactions: slice,
        total: all.length,
        page,
        limit,
        hasMore,
        groups: [...groupMap.values()].map((g) => ({
          id: g._id.toString(),
          name: g.name,
          coverColor: g.coverColor,
        })),
      },
    });
  }),

  // ── Delete account ────────────────────────────────────────────────────────
  deleteMe: asyncHandler(async (req, res) => {
    const userId = req.user.id.toString();

    // ── Step 0: Load user before anything else ────────────────────────────
    const user = await User.findById(userId);
    if (!user) throw NotFound('User not found');
    const snapshot = { name: user.name, email: user.email, avatarUrl: user.avatarUrl ?? null };

    // ── Step 1: Freeze user's name into every group expense they touched ──
    // So group members still see "Jane Smith (deleted)" not "Deleted User".
    await Expense.updateMany(
      { paidBy: userId, deletedAt: null },
      { $set: { paidBySnapshot: snapshot } },
    );
    await Expense.updateMany(
      { 'shares.user': userId, deletedAt: null },
      { $set: { 'shares.$[elem].userSnapshot': snapshot } },
      { arrayFilters: [{ 'elem.user': user._id }] },
    );

    // ── Step 2: Handle groups ─────────────────────────────────────────────
    const myGroups = await Group.find({ 'members.user': userId });

    for (const group of myGroups) {
      const otherMembers = group.members.filter((m) => m.user.toString() !== userId);

      if (otherMembers.length === 0) {
        // Sole member — delete everything related to this group
        const grpReceipts = await Expense.find({
          group: group._id,
          receiptUrl: { $nin: [null, ''] },
        })
          .select('receiptUrl')
          .lean();
        await Expense.deleteMany({ group: group._id });
        await Settlement.deleteMany({ group: group._id });
        await Activity.deleteMany({ group: group._id });
        deleteManyFromS3(grpReceipts.map((e) => e.receiptUrl)).catch(() => {});
        await group.deleteOne();
      } else {
        // Has other members
        const role = group.members.find((m) => m.user.toString() === userId)?.role;

        if (role === 'owner') {
          // Transfer ownership: prefer an existing admin, else the earliest-joined member
          const nextOwner =
            otherMembers.find((m) => m.role === 'admin') ?? otherMembers[0];
          group.members = group.members
            .filter((m) => m.user.toString() !== userId)
            .map((m) => {
              if (m.user.toString() === nextOwner.user.toString()) {
                return { ...m.toObject(), role: 'owner' };
              }
              return m.toObject();
            });
        } else {
          // Just remove from members
          group.members = group.members.filter((m) => m.user.toString() !== userId);
        }

        await group.save();
      }
    }

    // ── Step 2b: Drop any pending group invitations for this user ──────────
    // They were never a member of those groups, so the loop above misses them.
    // Leaves invites *sent* by this user intact (the invitee can still act on
    // them); only their own outstanding invites are cleared.
    await Group.updateMany(
      { 'pendingMembers.user': userId },
      { $pull: { pendingMembers: { user: userId } } },
    );

    // ── Step 3: Wipe personal data ────────────────────────────────────────
    const personalReceipts = await PersonalExpense.find({
      user: userId,
      receiptUrl: { $nin: [null, ''] },
    })
      .select('receiptUrl')
      .lean();
    await PersonalExpense.deleteMany({ user: userId });
    deleteManyFromS3(personalReceipts.map((e) => e.receiptUrl)).catch(() => {});
    await Otp.deleteMany({ email: user.email });
    await Activity.deleteMany({ actor: userId, group: null });

    // ── Step 4: Record deletion for 3-day re-registration cooldown ────────
    await DeletedAccount.create({ email: user.email, name: user.name, avatarUrl: user.avatarUrl ?? null });

    // ── Step 5: Delete the user document ─────────────────────────────────
    await User.findByIdAndDelete(userId);

    res.json({ ok: true, message: 'Account deleted successfully' });
  }),
};
