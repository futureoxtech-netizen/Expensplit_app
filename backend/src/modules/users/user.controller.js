import { z } from 'zod';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { User } from './user.model.js';
import { Group } from '../groups/group.model.js';
import { Expense } from '../expenses/expense.model.js';
import { Settlement } from '../settlements/settlement.model.js';
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

  friendsSummary: asyncHandler(async (req, res) => {
    const userId = req.user.id.toString();

    const groups = await Group.find({ 'members.user': userId, archived: false })
      .populate('members.user', 'name email avatarUrl')
      .lean();

    const netByFriend = new Map();    // friendId -> total net amount
    const friendUserMap = new Map();  // friendId -> user object
    const groupsByFriend = new Map(); // friendId -> [{groupId, groupName, net}]

    for (const group of groups) {
      // Collect friend info from members
      for (const m of group.members) {
        const mid = (m.user._id ?? m.user).toString();
        if (mid !== userId && m.user.name && !friendUserMap.has(mid)) {
          friendUserMap.set(mid, m.user);
        }
      }

      const expenses = await Expense.find({ group: group._id, deletedAt: null }).lean();
      const settlements = await Settlement.find({ group: group._id }).lean();

      // pairwise[friendId] = net (positive = friend owes me, negative = I owe friend)
      const pairwise = new Map();

      for (const exp of expenses) {
        const payer = exp.paidBy.toString();
        if (payer === userId) {
          // I paid — each sharer owes me their share
          for (const share of exp.shares) {
            const debtor = share.user.toString();
            if (debtor === userId) continue;
            pairwise.set(debtor, (pairwise.get(debtor) ?? 0) + share.amount);
          }
        } else {
          // Someone else paid — I owe them my share
          const myShare = exp.shares.find((s) => s.user.toString() === userId);
          if (myShare) {
            pairwise.set(payer, (pairwise.get(payer) ?? 0) - myShare.amount);
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
      const payer = (exp.paidBy._id ?? exp.paidBy).toString();
      let net = 0;
      if (payer === userId) {
        const share = exp.shares.find((s) => s.user.toString() === friendId);
        net = share?.amount ?? 0; // friend owes me
      } else {
        const share = exp.shares.find((s) => s.user.toString() === userId);
        net = -(share?.amount ?? 0); // I owe friend
      }
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
    });

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

    res.json({ ok: true, data: { transactions: all, groups: [...groupMap.values()].map(g => ({ id: g._id.toString(), name: g.name, coverColor: g.coverColor })) } });
  }),
};
