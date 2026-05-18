import { z } from 'zod';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { groupService } from './group.service.js';

export const groupController = {
  create: asyncHandler(async (req, res) => {
    const group = await groupService.create({ userId: req.user.id, data: req.body });
    res.status(201).json({ ok: true, data: group });
  }),

  list: asyncHandler(async (req, res) => {
    const groups = await groupService.listForUser(req.user.id);
    res.json({ ok: true, data: groups });
  }),

  getById: asyncHandler(async (req, res) => {
    const group = await groupService.getById({ userId: req.user.id, groupId: req.params.id });
    res.json({ ok: true, data: group });
  }),

  update: asyncHandler(async (req, res) => {
    const group = await groupService.update({
      userId: req.user.id,
      groupId: req.params.id,
      data: req.body,
    });
    res.json({ ok: true, data: group });
  }),

  addMember: asyncHandler(async (req, res) => {
    const email = z.string().email().parse(req.body?.email);
    const group = await groupService.addMemberByEmail({
      userId: req.user.id,
      groupId: req.params.id,
      email,
    });
    res.json({ ok: true, data: group });
  }),

  joinByCode: asyncHandler(async (req, res) => {
    const group = await groupService.joinByCode({ userId: req.user.id, code: req.body.code });
    res.json({ ok: true, data: group });
  }),

  leave: asyncHandler(async (req, res) => {
    const result = await groupService.leave({ userId: req.user.id, groupId: req.params.id });
    res.json({ ok: true, data: result });
  }),

  balances: asyncHandler(async (req, res) => {
    const result = await groupService.balances({ userId: req.user.id, groupId: req.params.id });
    res.json({ ok: true, data: result });
  }),
};
