import { z } from 'zod';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { groupService } from './group.service.js';

export const groupController = {
  create: asyncHandler(async (req, res) => {
    // console.log("🚀 ~ req:", req)
    console.log("🚀 ~ req.user.id:", req.user.id)
    const group = await groupService.create({ userId: req.user.id, data: req.body });
    console.log("🚀 ~ group:", group)
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

  updateNotes: asyncHandler(async (req, res) => {
    const group = await groupService.updateNotes({
      userId: req.user.id,
      groupId: req.params.id,
      notes: req.body.notes,
    });
    res.json({ ok: true, data: group });
  }),

  addMember: asyncHandler(async (req, res) => {
    const email = z.string().email().parse(req.body?.email);
    const result = await groupService.addMemberByEmail({
      userId: req.user.id,
      groupId: req.params.id,
      email,
    });
    // `status` distinguishes a direct add from a pending invitation so the
    // client can say "Invitation sent" vs "Member added".
    res.json({ ok: true, data: result.group, status: result.status });
  }),

  listInvites: asyncHandler(async (req, res) => {
    const data = await groupService.listInvitesForUser({ userId: req.user.id });
    res.json({ ok: true, data });
  }),

  acceptInvite: asyncHandler(async (req, res) => {
    const result = await groupService.acceptInvite({
      userId: req.user.id,
      groupId: req.params.id,
    });
    res.json({ ok: true, data: result.group });
  }),

  declineInvite: asyncHandler(async (req, res) => {
    const result = await groupService.declineInvite({
      userId: req.user.id,
      groupId: req.params.id,
    });
    res.json({ ok: true, data: result });
  }),

  addPlaceholder: asyncHandler(async (req, res) => {
    const name = z.string().min(1).max(80).parse(req.body?.name);
    const group = await groupService.addPlaceholderMember({
      userId: req.user.id,
      groupId: req.params.id,
      name,
    });
    res.status(201).json({ ok: true, data: group });
  }),

  removeMember: asyncHandler(async (req, res) => {
    const group = await groupService.removeMember({
      userId: req.user.id,
      groupId: req.params.id,
      memberId: req.params.memberId,
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

  remove: asyncHandler(async (req, res) => {
    const result = await groupService.deleteGroup({ userId: req.user.id, groupId: req.params.id });
    res.json({ ok: true, data: result });
  }),

  balances: asyncHandler(async (req, res) => {
    const result = await groupService.balances({ userId: req.user.id, groupId: req.params.id });
    res.json({ ok: true, data: result });
  }),
};
