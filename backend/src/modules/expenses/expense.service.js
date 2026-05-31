import mongoose from 'mongoose';
import { Expense } from './expense.model.js';
import { Group } from '../groups/group.model.js';
import { Settlement } from '../settlements/settlement.model.js';
import { computeShares } from '../../utils/splitCalculator.js';
import { BadRequest, Forbidden, NotFound } from '../../utils/errors.js';
import { emitToGroup } from '../../socket/index.js';
import { activityService } from '../activity/activity.service.js';
import { notifyUsers, actorName } from '../../services/notifications.service.js';
import { reactionService } from '../reactions/reaction.service.js';
import { deleteFromS3 } from '../../middleware/upload.js';

async function getGroupAsMember(groupId, userId) {
  if (!mongoose.isValidObjectId(groupId)) throw NotFound('Group not found');
  const group = await Group.findById(groupId);
  if (!group) throw NotFound('Group not found');
  if (!group.isMember(userId)) throw Forbidden('Not a group member');
  return group;
}

// Replace any null populated-user refs with the snapshot name/email we saved at
// deletion time (e.g. "Jane Smith (deleted)").  Falls back to a generic label
// only if no snapshot was stored (very old records before this feature).
const GHOST_USER = { _id: null, name: 'Deleted User', email: '', avatarUrl: null, deleted: true };

function ghostFromSnapshot(snapshot) {
  if (!snapshot || !snapshot.name) return GHOST_USER;
  return {
    _id: null,
    name: `${snapshot.name} (deleted)`,
    email: snapshot.email ?? '',
    avatarUrl: snapshot.avatarUrl ?? null,
    deleted: true,
  };
}

function sanitiseExpense(exp) {
  const obj = typeof exp.toObject === 'function' ? exp.toObject({ virtuals: false }) : { ...exp };
  if (!obj.paidBy) {
    obj.paidBy = ghostFromSnapshot(obj.paidBySnapshot);
  }
  if (Array.isArray(obj.shares)) {
    obj.shares = obj.shares.map((s) =>
      s.user ? s : { ...s, user: ghostFromSnapshot(s.userSnapshot) },
    );
  }
  return obj;
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

    // Notify everybody in the group who is *involved* in the expense —
    // i.e. the payer + every sharer — except the actor who just added it.
    const recipientIds = new Set([
      expense.paidBy.toString(),
      ...expense.shares.map((s) => s.user.toString()),
    ]);
    recipientIds.delete(userId.toString());
    if (recipientIds.size) {
      const actor = await actorName(userId);
      notifyUsers(
        [...recipientIds],
        {
          title: `${group.name}`,
          message: `${actor} added "${expense.description}" — ${expense.currency} ${expense.amount.toFixed(2)}`,
          type: 'expense.created',
          data: {
            groupId: group._id.toString(),
            expenseId: expense._id.toString(),
            route: `/groups/${group._id.toString()}`,
          },
        },
      ).catch(() => {});
    }

    const populated = await expense.populate(['paidBy', 'shares.user', 'createdBy']);
    return sanitiseExpense(populated);
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
    const sanitised = items.map(sanitiseExpense);
    const reactionMap = await reactionService.summariesByTarget({
      targetType: 'expense',
      ids: sanitised.map((e) => e._id),
    });
    for (const e of sanitised) e.reactions = reactionMap.get(e._id.toString()) ?? [];
    return { items: sanitised, total, page, limit, hasMore: skip + items.length < total };
  },

  // Unified group activity for the group-detail "Expenses" tab: expenses and
  // settlements merged into one date-sorted stream, so a recorded payment
  // ("Sara paid you") shows up alongside expenses just like Splitwise. Both
  // collections are small per-group, so we merge in memory and page the
  // result (mirrors the friend-transactions endpoint).
  async groupTransactions({ userId, groupId, page = 1, limit = 30 }) {
    const group = await getGroupAsMember(groupId, userId);

    const [expenses, settlements] = await Promise.all([
      Expense.find({ group: group._id, deletedAt: null })
        .sort({ spentAt: -1 })
        .populate('paidBy', 'name email avatarUrl')
        .populate('shares.user', 'name email avatarUrl')
        .lean(),
      Settlement.find({ group: group._id })
        .sort({ settledAt: -1 })
        .populate('from', 'name avatarUrl')
        .populate('to', 'name avatarUrl')
        .lean(),
    ]);

    const expenseItems = expenses.map((e) => ({
      ...sanitiseExpense(e),
      type: 'expense',
      _sortDate: e.spentAt,
    }));

    const userLabel = (u) =>
      u ? { id: u._id.toString(), name: u.name, avatarUrl: u.avatarUrl ?? null } : null;

    const settlementItems = settlements.map((s) => ({
      type: 'settlement',
      id: s._id.toString(),
      groupId: group._id.toString(),
      from: userLabel(s.from),
      to: userLabel(s.to),
      amount: s.amount,
      currency: s.currency,
      note: s.note ?? '',
      settledAt: s.settledAt,
      _sortDate: s.settledAt,
    }));

    const all = [...expenseItems, ...settlementItems].sort(
      (a, b) => new Date(b._sortDate) - new Date(a._sortDate),
    );

    const skip = (page - 1) * limit;
    const pageItems = all
      .slice(skip, skip + limit)
      // Drop the internal sort key before sending.
      .map(({ _sortDate, ...rest }) => rest);

    // Attach reactions only for the items actually on this page — both shapes
    // can carry reactions, so resolve each target type in one query apiece.
    const [expReactions, setReactions] = await Promise.all([
      reactionService.summariesByTarget({
        targetType: 'expense',
        ids: pageItems.filter((i) => i.type === 'expense').map((i) => i._id),
      }),
      reactionService.summariesByTarget({
        targetType: 'settlement',
        ids: pageItems.filter((i) => i.type === 'settlement').map((i) => i.id),
      }),
    ]);
    for (const item of pageItems) {
      item.reactions =
        item.type === 'expense'
          ? expReactions.get(item._id.toString()) ?? []
          : setReactions.get(item.id.toString()) ?? [];
    }

    return {
      items: pageItems,
      total: all.length,
      page,
      limit,
      hasMore: skip + pageItems.length < all.length,
    };
  },

  async getById({ userId, expenseId }) {
    const expense = await Expense.findById(expenseId)
      .populate('paidBy', 'name email avatarUrl')
      .populate('shares.user', 'name email avatarUrl');
    if (!expense || expense.deletedAt) throw NotFound('Expense not found');
    await getGroupAsMember(expense.group, userId);
    const out = sanitiseExpense(expense);
    out.reactions = await reactionService.summaryFor({ targetType: 'expense', targetId: expense._id });
    return out;
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
    const oldReceipt = expense.receiptUrl;
    for (const field of ['description', 'notes', 'currency', 'category', 'paidBy', 'receiptUrl', 'spentAt']) {
      if (patch[field] !== undefined) expense[field] = patch[field];
    }
    await expense.save();

    // Receipt replaced or removed → clean up the previous image from storage.
    if (patch.receiptUrl !== undefined && oldReceipt && oldReceipt !== expense.receiptUrl) {
      deleteFromS3(oldReceipt).catch(() => {});
    }

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

    const recipients = new Set([
      expense.paidBy.toString(),
      ...expense.shares.map((s) => s.user.toString()),
    ]);
    recipients.delete(userId.toString());
    if (recipients.size && changes.length) {
      const actor = await actorName(userId);
      notifyUsers(
        [...recipients],
        {
          title: group.name,
          message: `${actor} edited "${expense.description}"`,
          type: 'expense.updated',
          data: {
            groupId: group._id.toString(),
            expenseId: expense._id.toString(),
            route: `/groups/${group._id.toString()}`,
          },
        },
      ).catch(() => {});
    }

    const updatedPopulated = await expense.populate(['paidBy', 'shares.user']);
    return sanitiseExpense(updatedPopulated);
  },

  async remove({ userId, expenseId }) {
    const expense = await Expense.findById(expenseId);
    if (!expense || expense.deletedAt) throw NotFound('Expense not found');
    const group = await getGroupAsMember(expense.group, userId);
    // Any group member can delete an expense
    expense.deletedAt = new Date();
    await expense.save();
    // Reactions on a deleted expense are never surfaced again — drop them.
    await reactionService.purgeForTarget({ targetType: 'expense', targetId: expense._id }).catch(() => {});
    // The receipt is gone for good once the expense is deleted — clean up S3.
    if (expense.receiptUrl) deleteFromS3(expense.receiptUrl).catch(() => {});
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'expense.deleted',
      message: `deleted "${expense.description}" (${expense.currency} ${expense.amount.toFixed(2)})`,
      meta: { expenseId: expense._id.toString(), description: expense.description, amount: expense.amount, currency: expense.currency },
    });
    emitToGroup(group._id, 'expense:deleted', { groupId: group._id.toString(), expenseId: expense._id.toString() });

    const recipients = new Set([
      expense.paidBy.toString(),
      ...expense.shares.map((s) => s.user.toString()),
    ]);
    recipients.delete(userId.toString());
    if (recipients.size) {
      const actor = await actorName(userId);
      notifyUsers(
        [...recipients],
        {
          title: group.name,
          message: `${actor} deleted "${expense.description}"`,
          type: 'expense.deleted',
          data: {
            groupId: group._id.toString(),
            expenseId: expense._id.toString(),
            route: `/groups/${group._id.toString()}`,
          },
        },
      ).catch(() => {});
    }

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
    const sanitised = items.map(sanitiseExpense);
    const reactionMap = await reactionService.summariesByTarget({
      targetType: 'expense',
      ids: sanitised.map((e) => e._id),
    });
    for (const e of sanitised) e.reactions = reactionMap.get(e._id.toString()) ?? [];
    return { items: sanitised, total, page, limit, hasMore: skip + items.length < total };
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
