import mongoose from 'mongoose';
import { Expense } from './expense.model.js';
import { Group } from '../groups/group.model.js';
import { computeShares } from '../../utils/splitCalculator.js';
import { BadRequest, Forbidden, NotFound } from '../../utils/errors.js';
import { emitToGroup } from '../../socket/index.js';
import { activityService } from '../activity/activity.service.js';

async function getGroupAsMember(groupId, userId) {
  if (!mongoose.isValidObjectId(groupId)) throw NotFound('Group not found');
  const group = await Group.findById(groupId);
  if (!group) throw NotFound('Group not found');
  if (!group.isMember(userId)) throw Forbidden('Not a group member');
  return group;
}

function ensureSplitMembersInGroup(group, splits) {
  const memberIds = new Set(group.members.map((m) => m.user.toString()));
  for (const s of splits) {
    if (!memberIds.has(s.userId)) {
      throw BadRequest('All split participants must be group members');
    }
  }
}

export const expenseService = {
  async create({ userId, payload }) {
    const group = await getGroupAsMember(payload.groupId, userId);
    if (!group.isMember(payload.paidBy)) {
      throw BadRequest('Payer must be a group member');
    }
    ensureSplitMembersInGroup(group, payload.splits);

    const totalWithExtras = Number(payload.amount) + Number(payload.tax || 0) + Number(payload.tip || 0);
    const shares = computeShares({
      total: totalWithExtras,
      mode: payload.splitMode,
      splits: payload.splits,
    });

    const expense = await Expense.create({
      group: group._id,
      description: payload.description,
      notes: payload.notes,
      amount: totalWithExtras,
      currency: payload.currency || group.currency,
      category: payload.category || 'other',
      splitMode: payload.splitMode,
      paidBy: payload.paidBy,
      shares: shares.map((s) => ({ user: s.userId, amount: s.amount })),
      tax: payload.tax || 0,
      tip: payload.tip || 0,
      receiptUrl: payload.receiptUrl || '',
      spentAt: payload.spentAt || new Date(),
      recurring: payload.recurring
        ? { enabled: payload.recurring.enabled, cadence: payload.recurring.cadence || 'monthly' }
        : { enabled: false },
      createdBy: userId,
    });

    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'expense.created',
      message: `added "${expense.description}" (${expense.currency} ${expense.amount.toFixed(2)})`,
      meta: { expenseId: expense._id.toString() },
    });

    emitToGroup(group._id, 'expense:created', { groupId: group._id.toString(), expenseId: expense._id.toString() });

    return expense.populate(['paidBy', 'shares.user', 'createdBy']);
  },

  async list({ userId, groupId, page = 1, limit = 30 }) {
    const group = await getGroupAsMember(groupId, userId);
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Expense.find({ group: group._id, deletedAt: null })
        .sort({ spentAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('paidBy', 'name email avatarUrl')
        .populate('shares.user', 'name email avatarUrl')
        .lean(),
      Expense.countDocuments({ group: group._id, deletedAt: null }),
    ]);
    return { items, total, page, limit, hasMore: skip + items.length < total };
  },

  async getById({ userId, expenseId }) {
    const expense = await Expense.findById(expenseId)
      .populate('paidBy', 'name email avatarUrl')
      .populate('shares.user', 'name email avatarUrl');
    if (!expense || expense.deletedAt) throw NotFound('Expense not found');
    await getGroupAsMember(expense.group, userId);
    return expense;
  },

  async update({ userId, expenseId, patch }) {
    const expense = await Expense.findById(expenseId);
    if (!expense || expense.deletedAt) throw NotFound('Expense not found');
    const group = await getGroupAsMember(expense.group, userId);

    // Capture state before applying changes for the activity diff
    const before = {
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      splitMode: expense.splitMode,
      notes: expense.notes,
      currency: expense.currency,
      paidBy: expense.paidBy.toString(),
    };

    if (patch.splits || patch.splitMode || patch.amount || patch.tax !== undefined || patch.tip !== undefined) {
      const mode = patch.splitMode || expense.splitMode;
      const amount = patch.amount ?? expense.amount;
      const tax = patch.tax ?? expense.tax;
      const tip = patch.tip ?? expense.tip;
      const splits =
        patch.splits || expense.shares.map((s) => ({ userId: s.user.toString(), value: s.amount }));
      ensureSplitMembersInGroup(group, splits);
      const shares = computeShares({ total: amount + tax + tip, mode, splits });
      expense.splitMode = mode;
      expense.amount = amount + tax + tip;
      expense.tax = tax;
      expense.tip = tip;
      expense.shares = shares.map((s) => ({ user: s.userId, amount: s.amount }));
    }
    for (const field of ['description', 'notes', 'currency', 'category', 'paidBy', 'receiptUrl', 'spentAt']) {
      if (patch[field] !== undefined) expense[field] = patch[field];
    }
    await expense.save();

    // Build a human-readable diff of what changed
    const after = {
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      splitMode: expense.splitMode,
      notes: expense.notes,
      currency: expense.currency,
      paidBy: expense.paidBy.toString(),
    };
    const changes = [];
    for (const field of Object.keys(before)) {
      if (String(before[field]) !== String(after[field])) {
        changes.push({ field, from: before[field], to: after[field] });
      }
    }
    const changeSummary = changes
      .map((c) => {
        if (c.field === 'amount') {
          return `amount ${expense.currency} ${Number(c.from).toFixed(2)} → ${Number(c.to).toFixed(2)}`;
        }
        return `${c.field}: ${c.from} → ${c.to}`;
      })
      .join(', ');
    const message = changeSummary
      ? `edited "${expense.description}" (${changeSummary})`
      : `edited "${expense.description}"`;

    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'expense.updated',
      message,
      meta: { expenseId: expense._id.toString(), changes },
    });
    emitToGroup(group._id, 'expense:updated', { groupId: group._id.toString(), expenseId: expense._id.toString() });
    return expense.populate(['paidBy', 'shares.user']);
  },

  async remove({ userId, expenseId }) {
    const expense = await Expense.findById(expenseId);
    if (!expense || expense.deletedAt) throw NotFound('Expense not found');
    const group = await getGroupAsMember(expense.group, userId);
    // Any group member can delete an expense
    expense.deletedAt = new Date();
    await expense.save();
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'expense.deleted',
      message: `deleted "${expense.description}" (${expense.currency} ${expense.amount.toFixed(2)})`,
      meta: { expenseId: expense._id.toString(), description: expense.description, amount: expense.amount, currency: expense.currency },
    });
    emitToGroup(group._id, 'expense:deleted', { groupId: group._id.toString(), expenseId: expense._id.toString() });
    return { ok: true };
  },

  async myFeed({ userId, page = 1, limit = 30 }) {
    const groupIds = await Group.find({ 'members.user': userId }).distinct('_id');
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Expense.find({ group: { $in: groupIds }, deletedAt: null })
        .sort({ spentAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('paidBy', 'name avatarUrl')
        .populate('group', 'name coverColor icon')
        .lean(),
      Expense.countDocuments({ group: { $in: groupIds }, deletedAt: null }),
    ]);
    return { items, total, page, limit, hasMore: skip + items.length < total };
  },

  async report({ userId, from, to, groupId }) {
    const groupFilter = groupId
      ? { _id: groupId, 'members.user': userId }
      : { 'members.user': userId };
    const groupIds = await Group.find(groupFilter).distinct('_id');
    const fromDate = from ? new Date(from) : new Date(new Date().getFullYear(), 0, 1);
    const toDate = to ? new Date(to) : new Date();
    toDate.setHours(23, 59, 59, 999);

    const match = {
      group: { $in: groupIds },
      deletedAt: null,
      spentAt: { $gte: fromDate, $lte: toDate },
    };

    const userObj = new mongoose.Types.ObjectId(userId);

    const [byCategory, byDay, totals, list] = await Promise.all([
      Expense.aggregate([
        { $match: match },
        { $unwind: '$shares' },
        { $match: { 'shares.user': userObj } },
        { $group: { _id: '$category', amount: { $sum: '$shares.amount' }, count: { $sum: 1 } } },
        { $sort: { amount: -1 } },
      ]),
      Expense.aggregate([
        { $match: match },
        { $unwind: '$shares' },
        { $match: { 'shares.user': userObj } },
        {
          $group: {
            _id: {
              y: { $year: '$spentAt' },
              m: { $month: '$spentAt' },
              d: { $dayOfMonth: '$spentAt' },
            },
            amount: { $sum: '$shares.amount' },
          },
        },
        { $sort: { '_id.y': 1, '_id.m': 1, '_id.d': 1 } },
      ]),
      Expense.aggregate([
        { $match: match },
        { $unwind: '$shares' },
        { $match: { 'shares.user': userObj } },
        {
          $group: {
            _id: null,
            total: { $sum: '$shares.amount' },
            count: { $sum: 1 },
            paid: {
              $sum: {
                $cond: [{ $eq: ['$paidBy', userObj] }, '$amount', 0],
              },
            },
          },
        },
      ]),
      Expense.find(match)
        .sort({ spentAt: -1 })
        .limit(500)
        .populate('paidBy', 'name avatarUrl')
        .populate('group', 'name currency coverColor')
        .lean(),
    ]);

    const t = totals[0] ?? { total: 0, count: 0, paid: 0 };
    return {
      range: { from: fromDate, to: toDate },
      totals: {
        total: Math.round(t.total * 100) / 100,
        count: t.count,
        paid: Math.round(t.paid * 100) / 100,
      },
      byCategory: byCategory.map((c) => ({
        category: c._id,
        amount: Math.round(c.amount * 100) / 100,
        count: c.count,
      })),
      byDay: byDay.map((d) => ({
        date: new Date(Date.UTC(d._id.y, d._id.m - 1, d._id.d)).toISOString(),
        amount: Math.round(d.amount * 100) / 100,
      })),
      items: list,
    };
  },

  async monthlyAnalytics({ userId, months = 6 }) {
    const groupIds = await Group.find({ 'members.user': userId }).distinct('_id');
    const since = new Date();
    since.setMonth(since.getMonth() - (months - 1));
    since.setDate(1);
    since.setHours(0, 0, 0, 0);

    const rows = await Expense.aggregate([
      { $match: { group: { $in: groupIds }, deletedAt: null, spentAt: { $gte: since } } },
      { $unwind: '$shares' },
      { $match: { 'shares.user': new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: {
            y: { $year: '$spentAt' },
            m: { $month: '$spentAt' },
            category: '$category',
          },
          total: { $sum: '$shares.amount' },
        },
      },
      { $sort: { '_id.y': 1, '_id.m': 1 } },
    ]);

    return rows.map((r) => ({
      year: r._id.y,
      month: r._id.m,
      category: r._id.category,
      total: Math.round(r.total * 100) / 100,
    }));
  },
};
