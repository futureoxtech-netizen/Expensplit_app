import mongoose from 'mongoose';
import { v4 as uuid } from 'uuid';
import { Group } from './group.model.js';
import { User } from '../users/user.model.js';
import { Expense } from '../expenses/expense.model.js';
import { Settlement } from '../settlements/settlement.model.js';
import { Activity } from '../activity/activity.model.js';
import { BadRequest, Forbidden, NotFound } from '../../utils/errors.js';
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

// Net balance of one member inside the group. > 0 means they are owed money,
// < 0 means they owe. Used to gate "leave group": you must be square first.
async function memberNetBalance(group, memberId) {
  const id = memberId.toString();
  const [expenses, settlements] = await Promise.all([
    Expense.find({ group: group._id, deletedAt: null }).lean(),
    Settlement.find({ group: group._id }).lean(),
  ]);
  let net = 0;
  for (const exp of expenses) {
    if (exp.paidBy && exp.paidBy.toString() === id) net += exp.amount;
    for (const s of exp.shares) {
      if (s.user && s.user.toString() === id) net -= s.amount;
    }
  }
  for (const s of settlements) {
    if (s.from.toString() === id) net += s.amount;
    if (s.to.toString() === id) net -= s.amount;
  }
  return Math.round(net * 100) / 100;
}

// Build a id -> isPlaceholder map for a group's members so we can tell real
// members (who can own a group / must settle up) from guests.
async function classifyMembers(group) {
  const users = await User.find({ _id: { $in: group.members.map((m) => m.user) } })
    .select('isPlaceholder')
    .lean();
  return new Map(users.map((u) => [u._id.toString(), !!u.isPlaceholder]));
}

// Permanently delete a group and everything attached to it: expenses,
// settlements, activity, and any guest (placeholder) users that only ever
// existed inside it. Shared by "delete group" and the last-member-leaves path.
async function purgeGroup(group) {
  await Promise.all([
    Expense.deleteMany({ group: group._id }),
    Settlement.deleteMany({ group: group._id }),
    Activity.deleteMany({ group: group._id }),
    User.deleteMany({ isPlaceholder: true, placeholderGroup: group._id }),
  ]);
  await group.deleteOne();
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
      .populate('members.user', 'name email avatarUrl isPlaceholder')
      .lean();
  },

  async getById({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    return group.populate('members.user', 'name email avatarUrl isPlaceholder');
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
    if (!user) {
      throw NotFound(
        "This person doesn't have an Expensplit account yet. Ask them to install the app and sign up with this email.",
        'EMAIL_NOT_REGISTERED',
      );
    }
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

  // Add a "guest" member who isn't on Expensplit. We materialise a real but
  // credential-less User (isPlaceholder) so the rest of the expense/balance
  // machinery can reference them by id exactly like any other member.
  async addPlaceholderMember({ userId, groupId, name }) {
    const group = await findGroupForMember(groupId, userId);
    const role = group.roleOf(userId);
    if (!['owner', 'admin'].includes(role)) {
      throw Forbidden('Only admins can add members');
    }

    const trimmed = String(name || '').trim();
    if (trimmed.length < 1 || trimmed.length > 80) {
      throw BadRequest('Please enter a name between 1 and 80 characters', 'INVALID_NAME');
    }

    // Synthetic, non-routable email keeps the unique index happy without
    // colliding with real accounts or implying the guest can be emailed.
    const placeholder = await User.create({
      name: trimmed,
      email: `guest.${uuid().replace(/-/g, '')}@placeholder.expensplit`,
      isPlaceholder: true,
      createdBy: userId,
      placeholderGroup: group._id,
    });

    group.members.push({ user: placeholder._id, role: 'member' });
    await group.save();

    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.member_added',
      message: `added ${trimmed} (guest)`,
    });
    emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });

    return group.populate('members.user', 'name email avatarUrl isPlaceholder');
  },

  // Remove a member from the group. Guests (placeholders) that aren't tied to
  // any expense or settlement are deleted outright; otherwise we refuse so we
  // never orphan balances. Real users can be removed by an admin too, but only
  // when they have no financial history in the group (same safety rule).
  async removeMember({ userId, groupId, memberId }) {
    const group = await findGroupForMember(groupId, userId);
    const role = group.roleOf(userId);
    if (!['owner', 'admin'].includes(role)) {
      throw Forbidden('Only admins can remove members');
    }
    if (memberId.toString() === userId.toString()) {
      throw BadRequest('Use "Leave group" to remove yourself.', 'CANNOT_REMOVE_SELF');
    }
    if (!group.isMember(memberId)) throw NotFound('That member is not in this group');

    const target = await User.findById(memberId);
    if (!target) throw NotFound('Member not found');

    // Block removal if the member has any financial footprint in the group.
    const hasExpenses = await Expense.exists({
      group: group._id,
      deletedAt: null,
      $or: [{ paidBy: memberId }, { 'shares.user': memberId }],
    });
    const hasSettlements = await Settlement.exists({
      group: group._id,
      $or: [{ from: memberId }, { to: memberId }],
    });
    if (hasExpenses || hasSettlements) {
      throw BadRequest(
        target.isPlaceholder
          ? 'This guest already has expenses in the group, so they can\'t be removed. Settle and delete their expenses first.'
          : 'This member has expenses in the group and can\'t be removed.',
        'MEMBER_HAS_ACTIVITY',
      );
    }

    group.members = group.members.filter((m) => m.user.toString() !== memberId.toString());
    await group.save();

    // A placeholder belongs to exactly one group, so once removed it's dead
    // weight — delete the User document to keep the collection clean.
    if (target.isPlaceholder) {
      await User.findByIdAndDelete(memberId);
    }

    emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });
    return group.populate('members.user', 'name email avatarUrl isPlaceholder');
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
    return group.populate('members.user', 'name email avatarUrl isPlaceholder');
  },

  async leave({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    const isGuest = await classifyMembers(group);

    // Real members remaining if this user leaves (guests can't hold a group
    // together — they have no account to manage it).
    const remainingReal = group.members.filter(
      (m) => m.user.toString() !== userId.toString() && !isGuest.get(m.user.toString()),
    );

    // Last real member leaving → the group can't survive on guests alone, so
    // dissolve it entirely. No balance gate here: there's no real
    // counterparty left to settle with.
    if (remainingReal.length === 0) {
      const name = group.name;
      await purgeGroup(group);
      return { deleted: true, name };
    }

    // Otherwise you must be settled up before leaving — same rule as Splitwise.
    const net = await memberNetBalance(group, userId);
    if (Math.abs(net) >= 0.01) {
      throw BadRequest(
        "You can't leave this group while you still have unsettled balances. "
          + 'Settle up with the other members first, then try again.',
        'OUTSTANDING_BALANCE',
      );
    }

    const wasOwner = group.roleOf(userId) === 'owner';
    group.members = group.members.filter(
      (m) => m.user.toString() !== userId.toString(),
    );

    // Hand ownership to a remaining real member: an existing admin first,
    // otherwise the earliest-joined real member. Guests are never eligible.
    let newOwnerId = null;
    if (wasOwner) {
      const realLeft = group.members.filter((m) => !isGuest.get(m.user.toString()));
      const next =
        realLeft.find((m) => m.role === 'admin') ??
        [...realLeft].sort(
          (a, b) => new Date(a.joinedAt ?? 0) - new Date(b.joinedAt ?? 0),
        )[0];
      if (next) {
        const idx = group.members.findIndex(
          (m) => m.user.toString() === next.user.toString(),
        );
        group.members[idx].role = 'owner';
        newOwnerId = next.user;
      }
    }

    await group.save();

    const user = await User.findById(userId).lean();
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.member_left',
      message: `${user?.name ?? 'A member'} left the group`,
    });
    emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });

    if (newOwnerId) {
      notifyUser(newOwnerId, {
        title: group.name,
        message: `You're now the owner of "${group.name}".`,
        type: 'group.owner_changed',
        data: {
          groupId: group._id.toString(),
          route: `/groups/${group._id.toString()}`,
        },
      }).catch(() => {});
    }

    return { deleted: false };
  },

  // Permanently delete a group for everyone. Owner or admin only — regular
  // members can leave but not nuke shared history. All expenses, settlements
  // and guest members are removed; this cannot be undone.
  async deleteGroup({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    if (!['owner', 'admin'].includes(group.roleOf(userId))) {
      throw Forbidden(
        'Only the group owner or an admin can delete this group.',
        'NOT_GROUP_ADMIN',
      );
    }

    const name = group.name;
    const otherMemberIds = group.members
      .map((m) => m.user.toString())
      .filter((id) => id !== userId.toString());

    emitToGroup(group._id, 'group:deleted', { groupId: group._id.toString() });
    await purgeGroup(group);

    if (otherMemberIds.length) {
      const actor = await actorName(userId);
      notifyUsers(otherMemberIds, {
        title: 'Group deleted',
        message: `${actor} deleted the group "${name}".`,
        type: 'group.deleted',
        data: {},
      }).catch(() => {});
    }

    return { deleted: true, name };
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
