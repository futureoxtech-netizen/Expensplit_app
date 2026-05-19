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

// GET /personal-expenses  ?from=&to=&category=
export const list = asyncHandler(async (req, res) => {
  const { from, to, category } = req.query;
  const filter = { user: req.user.id };

  if (from || to) {
    filter.date = {};
    if (from) filter.date.$gte = new Date(from);
    if (to)   filter.date.$lte = new Date(to);
  }
  if (category) filter.category = category;

  const expenses = await PersonalExpense.find(filter).sort({ date: -1 }).lean();
  res.json({ ok: true, data: { items: expenses } });
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

// DELETE /personal-expenses/:id
export const remove = asyncHandler(async (req, res) => {
  const expense = await PersonalExpense.findOneAndDelete({
    _id: req.params.id,
    user: req.user.id,
  });
  if (!expense) throw new AppError('Not found', 404);
  res.json({ ok: true });
});
