import mongoose from 'mongoose';
import { Group } from './group.model.js';
import { User } from '../users/user.model.js';
import { Expense } from '../expenses/expense.model.js';
import { Settlement } from '../settlements/settlement.model.js';
import { Forbidden, NotFound } from '../../utils/errors.js';
import { simplifyDebts } from '../../utils/simplifyDebts.js';
import { emitToGroup } from '../../socket/index.js';
import { activityService } from '../activity/activity.service.js';
import { notifyUser, notifyUsers, notifyGroup, actorName } from '../../services/notifications.service.js';

async function findGroupForMember(groupId, userId) {
  if (!mongoose.isValidObjectId(groupId)) throw NotFound('Group not found');
  const group = await Group.findById(groupId);
  if (!group) throw NotFound('Group not found');
  if (!group.isMember(userId)) throw Forbidden('Not a member of this group');
  return group;
}

export const groupService = {
  async create({ userId, data }) {
    const members = [{ user: userId, role: 'owner' }];
    const invitedIds = [];
    if (data.memberEmails?.length) {
      const others = await User.find({ email: { $in: data.memberEmails.map((e) => e.toLowerCase()) } });
      for (const u of others) {
        if (u._id.toString() !== userId.toString()) {
          members.push({ user: u._id, role: 'member' });
          invitedIds.push(u._id);
        }
      }
    }
    const group = await Group.create({ ...data, createdBy: userId, members });
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.created',
      message: `created group "${group.name}"`,
    });
    // Tell everyone invited at creation that they were added to a new group.
    // Without this, invitees only saw the group on next refresh and missed
    // the real-time/push notification entirely.
    if (invitedIds.length) {
      const actor = await actorName(userId);
      notifyUsers(
        invitedIds,
        {
          title: 'New group',
          message: `${actor} added you to "${group.name}"`,
          type: 'group.member_added',
          data: {
            groupId: group._id.toString(),
            route: `/groups/${group._id.toString()}`,
          },
        },
      ).catch(() => {});
    }
    return group;
  },

  async listForUser(userId) {
    return Group.find({ 'members.user': userId, archived: false })
      .sort({ updatedAt: -1 })
      .populate('members.user', 'name email avatarUrl')
      .lean();
  },

  async getById({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    return group.populate('members.user', 'name email avatarUrl');
  },

  async update({ userId, groupId, data }) {
    const group = await findGroupForMember(groupId, userId);
    const role = group.roleOf(userId);
    if (!['owner', 'admin'].includes(role)) throw Forbidden('Only admins can update the group');
    Object.assign(group, data);
    await group.save();
    return group;
  },

  async addMemberByEmail({ userId, groupId, email }) {
    const group = await findGroupForMember(groupId, userId);
    const role = group.roleOf(userId);
    if (!['owner', 'admin'].includes(role)) throw Forbidden('Only admins can invite members');
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) throw NotFound('User not found');
    if (!group.isMember(user._id)) {
      group.members.push({ user: user._id, role: 'member' });
      await group.save();
      await activityService.log({
        groupId: group._id,
        actor: userId,
        type: 'group.member_added',
        message: `added ${user.name}`,
      });
      emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });
      const actor = await actorName(userId);
      notifyUser(user._id, {
        title: 'New group',
        message: `${actor} added you to "${group.name}"`,
        type: 'group.member_added',
        data: {
          groupId: group._id.toString(),
          route: `/groups/${group._id.toString()}`,
        },
      }).catch(() => {});
    }
    return group;
  },

  async joinByCode({ userId, code }) {
    const group = await Group.findOne({ inviteCode: code.toUpperCase() });
    if (!group) throw NotFound('Invalid invite code');
    if (!group.isMember(userId)) {
      group.members.push({ user: userId, role: 'member' });
      await group.save();
      const user = await User.findById(userId).lean();
      await activityService.log({
        groupId: group._id,
        actor: userId,
        type: 'group.member_joined',
        message: `${user?.name ?? 'A user'} joined via invite code`,
      });
      emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });
      // Notify everyone already in the group that a new person joined.
      notifyGroup(
        group,
        {
          title: group.name,
          message: `${user?.name ?? 'Someone'} joined the group`,
          type: 'group.member_joined',
          data: {
            groupId: group._id.toString(),
            route: `/groups/${group._id.toString()}`,
          },
        },
        userId,
      ).catch(() => {});
    }
    return group.populate('members.user', 'name email avatarUrl');
  },

  async leave({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    group.members = group.members.filter((m) => m.user.toString() !== userId.toString());
    if (group.members.length === 0) {
      await group.deleteOne();
      return { deleted: true };
    }
    await group.save();
    return { deleted: false };
  },

  async balances({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    const expenses = await Expense.find({ group: group._id, deletedAt: null }).lean();
    const settlements = await Settlement.find({ group: group._id }).lean();

    const totals = new Map();
    const ensure = (uid) => {
      const key = uid.toString();
      if (!totals.has(key)) totals.set(key, 0);
      return key;
    };

    for (const m of group.members) ensure(m.user);

    for (const exp of expenses) {
      const payerKey = ensure(exp.paidBy);
      totals.set(payerKey, totals.get(payerKey) + exp.amount);
      for (const share of exp.shares) {
        const k = ensure(share.user);
        totals.set(k, totals.get(k) - share.amount);
      }
    }
    for (const s of settlements) {
      const fromKey = ensure(s.from);
      const toKey = ensure(s.to);
      totals.set(fromKey, totals.get(fromKey) + s.amount);
      totals.set(toKey, totals.get(toKey) - s.amount);
    }

    const memberInfo = await User.find({ _id: { $in: [...totals.keys()] } })
      .select('name email avatarUrl')
      .lean();
    const userMap = new Map(memberInfo.map((u) => [u._id.toString(), u]));

    const balances = [...totals.entries()].map(([uid, net]) => ({
      userId: uid,
      user: userMap.get(uid)
        ? {
            id: uid,
            name: userMap.get(uid).name,
            email: userMap.get(uid).email,
            avatarUrl: userMap.get(uid).avatarUrl,
          }
        : null,
      net: Math.round(net * 100) / 100,
    }));

    const transfers = simplifyDebts(balances.map((b) => ({ userId: b.userId, net: b.net })));
    const transfersWithUsers = transfers.map((t) => ({
      ...t,
      fromUser: userMap.get(t.from) && {
        id: t.from,
        name: userMap.get(t.from).name,
        avatarUrl: userMap.get(t.from).avatarUrl,
      },
      toUser: userMap.get(t.to) && {
        id: t.to,
        name: userMap.get(t.to).name,
        avatarUrl: userMap.get(t.to).avatarUrl,
      },
    }));

    return { balances, transfers: transfersWithUsers };
  },
};
