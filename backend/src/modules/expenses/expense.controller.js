import { z } from 'zod';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { expenseService } from './expense.service.js';

const paging = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(30),
});

export const expenseController = {
  create: asyncHandler(async (req, res) => {
    const expense = await expenseService.create({ userId: req.user.id, payload: req.body });
    res.status(201).json({ ok: true, data: expense });
  }),

  listByGroup: asyncHandler(async (req, res) => {
    const { page, limit } = paging.parse(req.query);
    const data = await expenseService.list({
      userId: req.user.id,
      groupId: req.params.groupId,
      page,
      limit,
    });
    res.json({ ok: true, data });
  }),

  getById: asyncHandler(async (req, res) => {
    const expense = await expenseService.getById({ userId: req.user.id, expenseId: req.params.id });
    res.json({ ok: true, data: expense });
  }),

  update: asyncHandler(async (req, res) => {
    const expense = await expenseService.update({
      userId: req.user.id,
      expenseId: req.params.id,
      patch: req.body,
    });
    res.json({ ok: true, data: expense });
  }),

  remove: asyncHandler(async (req, res) => {
    await expenseService.remove({ userId: req.user.id, expenseId: req.params.id });
    res.json({ ok: true });
  }),

  feed: asyncHandler(async (req, res) => {
    const { page, limit } = paging.parse(req.query);
    const data = await expenseService.myFeed({ userId: req.user.id, page, limit });
    res.json({ ok: true, data });
  }),

  analytics: asyncHandler(async (req, res) => {
    const months = Math.min(Math.max(Number(req.query.months) || 6, 1), 24);
    const data = await expenseService.monthlyAnalytics({ userId: req.user.id, months });
    res.json({ ok: true, data });
  }),

  report: asyncHandler(async (req, res) => {
    const data = await expenseService.report({
      userId: req.user.id,
      from: req.query.from,
      to: req.query.to,
      groupId: req.query.groupId,
    });
    res.json({ ok: true, data });
  }),
};
