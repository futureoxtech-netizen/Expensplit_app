import { Goal } from './goal.model.js';
import { NotFound, Forbidden, BadRequest } from '../../utils/errors.js';
import { recordTombstone } from '../sync/tombstone.model.js';

// ─── Create ───────────────────────────────────────────────────────────────────
export async function createGoal(userId, body) {
  const { title, description, emoji, category, targetAmount,
          currency, targetDate, priority, color, notes, clientOpId } = body;

  // Idempotent replay for offline-first sync.
  if (clientOpId) {
    const dup = await Goal.findOne({ user: userId, clientOpId });
    if (dup) return dup;
  }

  const goal = await Goal.create({
    user: userId,
    title,
    description,
    emoji: emoji || '🎯',
    category: category || 'other',
    targetAmount: Number(targetAmount),
    currency: currency || 'USD',
    targetDate: targetDate ? new Date(targetDate) : null,
    priority: priority || 'medium',
    color: color || '#6C5CE7',
    notes: notes || '',
    clientOpId: clientOpId || null,
  });

  return goal;
}

// ─── List ─────────────────────────────────────────────────────────────────────
export async function listGoals(userId, { status, page = 1, limit = 20 } = {}) {
  const filter = { user: userId };
  if (status) filter.status = status;

  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    Goal.find(filter)
        .sort({ status: 1, createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .select('-contributions'),     // contributions loaded separately via getById
    Goal.countDocuments(filter),
  ]);

  // Summary stats
  const allGoals = await Goal.find({ user: userId }).select('savedAmount targetAmount status');
  const totalSaved  = allGoals.reduce((s, g) => s + g.savedAmount, 0);
  const totalTarget = allGoals.reduce((s, g) => s + g.targetAmount, 0);
  const completedCount = allGoals.filter(g => g.status === 'completed').length;

  return {
    items,
    pagination: { page: Number(page), limit: Number(limit), total, pages: Math.ceil(total / Number(limit)) },
    stats: { totalSaved, totalTarget, completedCount, activeCount: allGoals.filter(g => g.status === 'active').length },
  };
}

// ─── Get by ID ────────────────────────────────────────────────────────────────
export async function getGoalById(userId, goalId) {
  const goal = await Goal.findById(goalId);
  if (!goal) throw NotFound('Goal not found');
  if (goal.user.toString() !== userId.toString()) throw Forbidden('Not your goal');
  return goal;
}

// ─── Update ───────────────────────────────────────────────────────────────────
export async function updateGoal(userId, goalId, body) {
  const goal = await getGoalById(userId, goalId);

  const allowed = ['title', 'description', 'emoji', 'category', 'targetAmount',
                   'currency', 'targetDate', 'priority', 'color', 'notes', 'status'];
  for (const key of allowed) {
    if (body[key] !== undefined) {
      if (key === 'targetAmount') goal[key] = Number(body[key]);
      else if (key === 'targetDate') goal[key] = body[key] ? new Date(body[key]) : null;
      else goal[key] = body[key];
    }
  }

  // Auto-complete when savedAmount >= targetAmount
  if (goal.savedAmount >= goal.targetAmount && goal.status === 'active') {
    goal.status = 'completed';
    goal.completedAt = new Date();
  }

  await goal.save();
  return goal;
}

// ─── Delete ───────────────────────────────────────────────────────────────────
export async function deleteGoal(userId, goalId) {
  const goal = await getGoalById(userId, goalId);
  await goal.deleteOne();
  recordTombstone({
    entityType: 'goal',
    entityId: goalId,
    users: [userId],
  }).catch(() => {});
  return { ok: true };
}

// ─── Add contribution ─────────────────────────────────────────────────────────
export async function addContribution(userId, goalId, { amount, note, date }) {
  if (!amount || Number(amount) <= 0) throw BadRequest('Amount must be greater than 0');

  const goal = await getGoalById(userId, goalId);
  if (goal.status === 'abandoned') throw BadRequest('Cannot add to an abandoned goal');
  if (goal.status === 'completed') throw BadRequest('Goal is already completed');

  const contribution = {
    amount: Number(amount),
    note: note || '',
    date: date ? new Date(date) : new Date(),
  };

  goal.contributions.push(contribution);
  goal.savedAmount += contribution.amount;

  // Auto-complete
  if (goal.savedAmount >= goal.targetAmount) {
    goal.status = 'completed';
    goal.completedAt = new Date();
  }

  await goal.save();
  return goal;
}

// ─── Remove contribution ──────────────────────────────────────────────────────
export async function removeContribution(userId, goalId, contributionId) {
  const goal = await getGoalById(userId, goalId);

  const idx = goal.contributions.findIndex(c => c._id.toString() === contributionId);
  if (idx === -1) throw NotFound('Contribution not found');

  const removed = goal.contributions[idx];
  goal.contributions.splice(idx, 1);
  goal.savedAmount = Math.max(0, goal.savedAmount - removed.amount);

  // Reopen if was auto-completed and now underfunded
  if (goal.status === 'completed' && goal.savedAmount < goal.targetAmount) {
    goal.status = 'active';
    goal.completedAt = null;
  }

  await goal.save();
  return goal;
}

// ─── Update contribution ──────────────────────────────────────────────────────
export async function updateContribution(userId, goalId, contributionId, { amount, note, date }) {
  const goal = await getGoalById(userId, goalId);

  const contribution = goal.contributions.id(contributionId);
  if (!contribution) throw NotFound('Contribution not found');

  const oldAmount = contribution.amount;
  if (amount !== undefined) contribution.amount = Number(amount);
  if (note !== undefined) contribution.note = note;
  if (date !== undefined) contribution.date = new Date(date);

  // Recalculate savedAmount
  goal.savedAmount = Math.max(0, goal.savedAmount - oldAmount + contribution.amount);

  // Auto-complete / reopen
  if (goal.savedAmount >= goal.targetAmount && goal.status === 'active') {
    goal.status = 'completed';
    goal.completedAt = new Date();
  } else if (goal.savedAmount < goal.targetAmount && goal.status === 'completed') {
    goal.status = 'active';
    goal.completedAt = null;
  }

  await goal.save();
  return goal;
}

// ─── Goal calculator: daily/weekly/monthly needed ─────────────────────────────
export function computeGoalStats(goal) {
  const remaining = Math.max(0, goal.targetAmount - goal.savedAmount);
  const progress  = goal.targetAmount > 0 ? Math.min(1, goal.savedAmount / goal.targetAmount) : 0;

  let daysLeft = null, dailyNeeded = null, weeklyNeeded = null, monthlyNeeded = null;
  let projectedCompletionDate = null;

  if (goal.targetDate) {
    daysLeft = Math.max(0, Math.ceil((new Date(goal.targetDate) - Date.now()) / 86_400_000));
    if (daysLeft > 0 && remaining > 0) {
      dailyNeeded   = remaining / daysLeft;
      weeklyNeeded  = dailyNeeded * 7;
      monthlyNeeded = dailyNeeded * 30;
    }
  }

  // Projected completion based on average contribution rate (last 30 days)
  if (goal.contributions.length >= 2 && remaining > 0) {
    const thirtyDaysAgo = Date.now() - 30 * 86_400_000;
    const recent = goal.contributions.filter(c => new Date(c.date) > thirtyDaysAgo);
    if (recent.length > 0) {
      const recentTotal = recent.reduce((s, c) => s + c.amount, 0);
      const dailyRate   = recentTotal / 30;
      if (dailyRate > 0) {
        const daysToComplete = remaining / dailyRate;
        projectedCompletionDate = new Date(Date.now() + daysToComplete * 86_400_000);
      }
    }
  }

  // Milestone
  const milestones = [0.25, 0.5, 0.75, 1.0];
  const reachedMilestone = milestones.filter(m => progress >= m).at(-1) ?? null;
  const nextMilestone    = milestones.find(m => progress < m) ?? null;

  return { remaining, progress, daysLeft, dailyNeeded, weeklyNeeded, monthlyNeeded,
           projectedCompletionDate, reachedMilestone, nextMilestone };
}
