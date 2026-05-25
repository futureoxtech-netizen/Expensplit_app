import { asyncHandler } from '../../utils/asyncHandler.js';
import * as svc from './goal.service.js';

// POST /goals
export const create = asyncHandler(async (req, res) => {
  const goal = await svc.createGoal(req.user.id, req.body);
  res.status(201).json({ ok: true, data: goal });
});

// GET /goals?status=active&page=1&limit=20
export const list = asyncHandler(async (req, res) => {
  const result = await svc.listGoals(req.user.id, req.query);
  res.json({ ok: true, data: result });
});

// GET /goals/:id
export const getOne = asyncHandler(async (req, res) => {
  const goal = await svc.getGoalById(req.user.id, req.params.id);
  const stats = svc.computeGoalStats(goal);
  res.json({ ok: true, data: { ...goal.toObject(), stats } });
});

// PATCH /goals/:id
export const update = asyncHandler(async (req, res) => {
  const goal = await svc.updateGoal(req.user.id, req.params.id, req.body);
  res.json({ ok: true, data: goal });
});

// DELETE /goals/:id
export const remove = asyncHandler(async (req, res) => {
  await svc.deleteGoal(req.user.id, req.params.id);
  res.json({ ok: true, message: 'Goal deleted' });
});

// POST /goals/:id/contributions
export const addContribution = asyncHandler(async (req, res) => {
  const goal = await svc.addContribution(req.user.id, req.params.id, req.body);
  const stats = svc.computeGoalStats(goal);
  res.status(201).json({ ok: true, data: { ...goal.toObject(), stats } });
});

// PATCH /goals/:id/contributions/:cId
export const updateContribution = asyncHandler(async (req, res) => {
  const goal = await svc.updateContribution(req.user.id, req.params.id, req.params.cId, req.body);
  const stats = svc.computeGoalStats(goal);
  res.json({ ok: true, data: { ...goal.toObject(), stats } });
});

// DELETE /goals/:id/contributions/:cId
export const removeContribution = asyncHandler(async (req, res) => {
  const goal = await svc.removeContribution(req.user.id, req.params.id, req.params.cId);
  res.json({ ok: true, data: goal });
});
