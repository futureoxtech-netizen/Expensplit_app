import { asyncHandler } from '../../utils/asyncHandler.js';
import { AppError } from '../../utils/errors.js';
import { deleteFromS3 } from '../../middleware/upload.js';
import { PersonalExpense } from './personal.model.js';
import { recordTombstone } from '../sync/tombstone.model.js';
import { activityService } from '../activity/activity.service.js';

// Personal expenses have no group, so their activity is addressed to the owner
// alone via `recipients`. The actor is also the owner, so the client's unread
// badge skips it (own actions never notify) — it only ever shows in history.
function logPersonalActivity(userId, type, message, personalId) {
  activityService
    .log({
      actor: userId,
      recipients: [userId],
      type,
      message,
      meta: { personalId: personalId?.toString(), route: '/personal' },
    })
    .catch(() => {});
}

const money = (e) => `${e.currency} ${Number(e.amount).toFixed(2)}`;

// POST /personal-expenses
export const create = asyncHandler(async (req, res) => {
  const { description, amount, currency, category, date, note, receiptUrl, clientOpId } = req.body;
  // Idempotent replay for offline-first sync.
  if (clientOpId) {
    const dup = await PersonalExpense.findOne({ user: req.user.id, clientOpId });
    if (dup) return res.status(200).json({ ok: true, data: dup });
  }
  const expense = await PersonalExpense.create({
    user: req.user.id,
    description,
    amount,
    currency: currency || 'USD',
    category: category || 'other',
    date: date ? new Date(date) : new Date(),
    note: note || '',
    receiptUrl: receiptUrl || '',
    clientOpId: clientOpId || null,
  });
  // Logged only on a real create (the clientOpId dup-replay above returns
  // early), so a retried offline op never double-posts the activity.
  logPersonalActivity(
    req.user.id,
    'personal.created',
    `added a personal expense "${expense.description}" (${money(expense)})`,
    expense._id,
  );
  res.status(201).json({ ok: true, data: expense });
});

// GET /personal-expenses  ?from=&to=&category=&page=&limit=
export const list = asyncHandler(async (req, res) => {
  const { from, to, category } = req.query;
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 30));
  const filter = { user: req.user.id };

  if (from || to) {
    filter.date = {};
    if (from) filter.date.$gte = new Date(from);
    if (to)   filter.date.$lte = new Date(to);
  }
  if (category) filter.category = category;

  const skip = (page - 1) * limit;
  const [expenses, total] = await Promise.all([
    PersonalExpense.find(filter).sort({ date: -1 }).skip(skip).limit(limit).lean(),
    PersonalExpense.countDocuments(filter),
  ]);
  res.json({
    ok: true,
    data: {
      items: expenses,
      total,
      page,
      limit,
      hasMore: skip + expenses.length < total,
    },
  });
});

// GET /personal-expenses/summary  ?months=3
export const summary = asyncHandler(async (req, res) => {
  const months = parseInt(req.query.months) || 3;
  const since = new Date();
  since.setMonth(since.getMonth() - months);

  const rows = await PersonalExpense.aggregate([
    { $match: { user: req.user.id, date: { $gte: since } } },
    {
      $group: {
        _id: {
          year: { $year: '$date' },
          month: { $month: '$date' },
          category: '$category',
        },
        total: { $sum: '$amount' },
      },
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } },
  ]);

  res.json({ ok: true, data: { rows } });
});

// PATCH /personal-expenses/:id — partial update of the owner's own record.
export const update = asyncHandler(async (req, res) => {
  const { description, amount, currency, category, date, note, receiptUrl } = req.body;

  // Load first so we know the previous receipt — needed to clean up S3 if the
  // receipt is being replaced or removed.
  const existing = await PersonalExpense.findOne({ _id: req.params.id, user: req.user.id });
  if (!existing) throw new AppError('Not found', 404);
  const oldReceipt = existing.receiptUrl;

  if (description !== undefined) existing.description = description;
  if (amount !== undefined) existing.amount = amount;
  if (currency !== undefined) existing.currency = currency;
  if (category !== undefined) existing.category = category;
  if (date !== undefined) existing.date = new Date(date);
  if (note !== undefined) existing.note = note;
  if (receiptUrl !== undefined) existing.receiptUrl = receiptUrl;
  await existing.save();

  // Receipt was swapped or cleared → drop the old object from storage.
  if (receiptUrl !== undefined && oldReceipt && oldReceipt !== existing.receiptUrl) {
    deleteFromS3(oldReceipt).catch(() => {});
  }
  logPersonalActivity(
    req.user.id,
    'personal.updated',
    `updated personal expense "${existing.description}"`,
    existing._id,
  );
  res.json({ ok: true, data: existing });
});

// DELETE /personal-expenses/:id
export const remove = asyncHandler(async (req, res) => {
  const expense = await PersonalExpense.findOneAndDelete({
    _id: req.params.id,
    user: req.user.id,
  });
  if (!expense) throw new AppError('Not found', 404);
  // Clean up the attached receipt, if any.
  if (expense.receiptUrl) deleteFromS3(expense.receiptUrl).catch(() => {});
  recordTombstone({
    entityType: 'personalExpense',
    entityId: expense._id,
    users: [req.user.id],
  }).catch(() => {});
  logPersonalActivity(
    req.user.id,
    'personal.deleted',
    `deleted personal expense "${expense.description}" (${money(expense)})`,
    expense._id,
  );
  res.json({ ok: true });
});
