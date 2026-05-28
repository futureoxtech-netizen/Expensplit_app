import { asyncHandler } from '../../utils/asyncHandler.js';
import { AppError } from '../../utils/errors.js';
import { PersonalExpense } from './personal.model.js';

// POST /personal-expenses
export const create = asyncHandler(async (req, res) => {
  const { description, amount, currency, category, date, note } = req.body;
  const expense = await PersonalExpense.create({
    user: req.user.id,
    description,
    amount,
    currency: currency || 'USD',
    category: category || 'other',
    date: date ? new Date(date) : new Date(),
    note: note || '',
  });
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
  const { description, amount, currency, category, date, note } = req.body;
  const patch = {};
  if (description !== undefined) patch.description = description;
  if (amount !== undefined) patch.amount = amount;
  if (currency !== undefined) patch.currency = currency;
  if (category !== undefined) patch.category = category;
  if (date !== undefined) patch.date = new Date(date);
  if (note !== undefined) patch.note = note;

  const expense = await PersonalExpense.findOneAndUpdate(
    { _id: req.params.id, user: req.user.id },
    { $set: patch },
    { new: true },
  );
  if (!expense) throw new AppError('Not found', 404);
  res.json({ ok: true, data: expense });
});

// DELETE /personal-expenses/:id
export const remove = asyncHandler(async (req, res) => {
  const expense = await PersonalExpense.findOneAndDelete({
    _id: req.params.id,
    user: req.user.id,
  });
  if (!expense) throw new AppError('Not found', 404);
  res.json({ ok: true });
});
