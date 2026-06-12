import { Group } from '../groups/group.model.js';
import { Expense } from '../expenses/expense.model.js';
import { Settlement } from '../settlements/settlement.model.js';
import { Activity } from '../activity/activity.model.js';
import { PersonalExpense } from '../personal/personal.model.js';
import { Goal } from '../goals/goal.model.js';
import { User } from '../users/user.model.js';
import { Tombstone } from './tombstone.model.js';
import { reactionService } from '../reactions/reaction.service.js';
import { loanService } from '../loans/loan.service.js';

// Populate specs mirror the existing list endpoints so the Flutter client can
// reuse its `fromJson` parsers unchanged.
const EXPENSE_POPULATE = [
  { path: 'paidBy', select: 'name email avatarUrl' },
  { path: 'payers.user', select: 'name email avatarUrl' },
  { path: 'shares.user', select: 'name email avatarUrl' },
];

export const syncService = {
  /**
   * Delta sync: everything visible to the user that changed since `since`,
   * paginated by ascending `updatedAt`. When `since` is omitted, returns a full
   * snapshot from the beginning (first sync / fresh login on a new device).
   *
   * Each collection returns at most `limit` rows. `hasMore` is true when any
   * collection filled its page, and `nextSince` is the cursor to fetch the next
   * page. The client loops until `hasMore` is false, then stores `serverTime`.
   * Deletes are reported separately as `deletions` (from the tombstone log).
   */
  async pull({ userId, since, limit = 300 }) {
    const serverTime = new Date();
    const page = Math.min(Math.max(Number(limit) || 300, 1), 1000);
    const sinceDate = since ? new Date(since) : null;
    const changedSince = (field = 'updatedAt') =>
      sinceDate && !Number.isNaN(sinceDate.getTime()) ? { [field]: { $gt: sinceDate } } : {};

    // All groups the user currently belongs to — scopes expenses/settlements/
    // activity even when those parent groups themselves didn't change.
    const myGroups = await Group.find({ 'members.user': userId }).lean();
    const allGroupIds = myGroups.map((g) => g._id);

    const memberUserIds = new Set([userId.toString()]);
    for (const g of myGroups) {
      for (const m of g.members) memberUserIds.add(m.user.toString());
      for (const p of g.pendingMembers ?? []) memberUserIds.add(p.user.toString());
    }

    const [groups, expenses, settlements, personalExpenses, goals, activity, users, tombstones, loans] =
      await Promise.all([
        Group.find({ 'members.user': userId, ...changedSince() })
          .sort({ updatedAt: 1 }).limit(page)
          .populate('members.user', 'name email avatarUrl isPlaceholder')
          .populate('pendingMembers.user', 'name email avatarUrl')
          .populate('pendingMembers.invitedBy', 'name avatarUrl')
          .lean(),
        Expense.find({ group: { $in: allGroupIds }, deletedAt: null, ...changedSince() })
          .sort({ updatedAt: 1 }).limit(page)
          .populate(EXPENSE_POPULATE)
          .lean(),
        Settlement.find({ group: { $in: allGroupIds }, ...changedSince() })
          .sort({ updatedAt: 1 }).limit(page)
          .populate('from', 'name email avatarUrl')
          .populate('to', 'name email avatarUrl')
          .lean(),
        PersonalExpense.find({ user: userId, ...changedSince() }).sort({ updatedAt: 1 }).limit(page).lean(),
        Goal.find({ user: userId, ...changedSince() }).sort({ updatedAt: 1 }).limit(page).lean(),
        Activity.find({ group: { $in: allGroupIds }, ...changedSince('createdAt') })
          .populate('actor', 'name avatarUrl')
          .populate('group', 'name coverColor')
          .sort({ createdAt: 1 })
          .limit(page)
          .lean(),
        User.find({ _id: { $in: [...memberUserIds] }, ...changedSince() })
          .sort({ updatedAt: 1 }).limit(page)
          .select('name email avatarUrl isPlaceholder currency')
          .lean(),
        Tombstone.find({ users: userId, ...changedSince('deletedAt') })
          .sort({ deletedAt: 1 }).limit(page)
          .select('entityType entityId groupId deletedAt')
          .lean(),
        loanService.deltaSince({ userId, since, limit: page }),
      ]);

    // Each collection is sorted ascending, so the last item carries its largest
    // timestamp. The next-page cursor is the *minimum* of the last timestamps of
    // the *full* collections, which guarantees no full collection is advanced
    // past its own last row (so nothing is skipped). Overlap re-fetches are
    // harmless — the client's upserts are idempotent.
    const collections = [
      [groups, 'updatedAt'],
      [expenses, 'updatedAt'],
      [settlements, 'updatedAt'],
      [personalExpenses, 'updatedAt'],
      [goals, 'updatedAt'],
      [users, 'updatedAt'],
      [activity, 'createdAt'],
      [tombstones, 'deletedAt'],
      [loans, 'updatedAt'],
    ];
    const fullLastTs = [];
    for (const [arr, field] of collections) {
      if (arr.length >= page) {
        const last = arr[arr.length - 1][field];
        fullLastTs.push(last ? new Date(last).getTime() : 0);
      }
    }
    const hasMore = fullLastTs.length > 0;
    const nextSince = hasMore ? new Date(Math.min(...fullLastTs)).toISOString() : null;

    // Attach reaction summaries so they persist offline like everything else.
    if (expenses.length) {
      const map = await reactionService.summariesByTarget({
        targetType: 'expense',
        ids: expenses.map((e) => e._id),
      });
      for (const e of expenses) e.reactions = map.get(e._id.toString()) ?? [];
    }
    if (settlements.length) {
      const map = await reactionService.summariesByTarget({
        targetType: 'settlement',
        ids: settlements.map((s) => s._id),
      });
      for (const s of settlements) s.reactions = map.get(s._id.toString()) ?? [];
    }

    return {
      serverTime: serverTime.toISOString(),
      hasMore,
      nextSince,
      groups,
      expenses,
      settlements,
      personalExpenses,
      goals,
      activity,
      users,
      loans,
      deletions: tombstones.map((t) => ({
        entityType: t.entityType,
        entityId: t.entityId,
        groupId: t.groupId ? t.groupId.toString() : null,
      })),
    };
  },
};
