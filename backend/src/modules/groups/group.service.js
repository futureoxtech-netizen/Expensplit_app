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

// Populate spec shared by every method that returns a group to the client, so
// members *and* pending members always arrive with their user details filled
// in (the Flutter side renders both).
const GROUP_POPULATE = [
  { path: 'members.user', select: 'name email avatarUrl isPlaceholder' },
  { path: 'pendingMembers.user', select: 'name email avatarUrl' },
  { path: 'pendingMembers.invitedBy', select: 'name avatarUrl' },
];

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
    const pendingMembers = [];
    const addedIds = [];
    const pendingIds = [];
    if (data.memberEmails?.length) {
      const others = await User.find({ email: { $in: data.memberEmails.map((e) => e.toLowerCase()) } })
        .select('groupInvitePolicy name');
      for (const u of others) {
        if (u._id.toString() === userId.toString()) continue;
        // Respect each invitee's privacy choice: 'approval' people get a
        // pending invite they must accept; everyone else joins immediately.
        if (u.groupInvitePolicy === 'approval') {
          pendingMembers.push({ user: u._id, invitedBy: userId, role: 'member' });
          pendingIds.push(u._id);
        } else {
          members.push({ user: u._id, role: 'member' });
          addedIds.push(u._id);
        }
      }
    }
    const group = await Group.create({ ...data, createdBy: userId, members, pendingMembers });
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.created',
      message: `created group "${group.name}"`,
    });

    const actor = await actorName(userId);
    // Tell everyone added at creation that they're in a new group, and everyone
    // pending that they have an invitation to accept.
    if (addedIds.length) {
      notifyUsers(addedIds, {
        title: 'New group',
        message: `${actor} added you to "${group.name}"`,
        type: 'group.member_added',
        data: { groupId: group._id.toString(), route: `/groups/${group._id.toString()}` },
      }).catch(() => {});
    }
    if (pendingIds.length) {
      notifyUsers(pendingIds, {
        title: 'Group invitation',
        message: `${actor} invited you to join "${group.name}"`,
        type: 'group.invite',
        data: { groupId: group._id.toString(), route: '/groups' },
      }).catch(() => {});
      // Log one activity entry per pending invite so invited users see it in
      // their Activity feed (the feed query includes pending-group invites).
      const pendingUsers = others.filter((u) => pendingIds.some((id) => id.equals(u._id)));
      for (const u of pendingUsers) {
        activityService
          .log({
            groupId: group._id,
            actor: userId,
            type: 'group.invite',
            message: `invited ${u.name} to join`,
            meta: { invitedUserId: u._id.toString() },
          })
          .catch(() => {});
      }
    }
    return group.populate(GROUP_POPULATE);
  },

  async listForUser(userId) {
    return Group.find({ 'members.user': userId, archived: false })
      .sort({ updatedAt: -1 })
      .populate('members.user', 'name email avatarUrl isPlaceholder')
      .populate('pendingMembers.user', 'name email avatarUrl')
      .populate('pendingMembers.invitedBy', 'name avatarUrl')
      .lean();
  },

  async getById({ userId, groupId }) {
    const group = await findGroupForMember(groupId, userId);
    return group.populate(GROUP_POPULATE);
  },

  // Groups this user has been invited to but hasn't accepted yet. Drives the
  // "pending invitations" banner on the Groups screen.
  async listInvitesForUser({ userId }) {
    const groups = await Group.find({ 'pendingMembers.user': userId, archived: false })
      .populate('pendingMembers.invitedBy', 'name avatarUrl')
      .select('name coverColor icon currency members pendingMembers')
      .lean();
    return groups.map((g) => {
      const pending = (g.pendingMembers ?? []).find(
        (m) => (m.user?._id ?? m.user).toString() === userId.toString(),
      );
      const inviter = pending?.invitedBy;
      return {
        groupId: g._id.toString(),
        name: g.name,
        coverColor: g.coverColor,
        icon: g.icon,
        currency: g.currency,
        memberCount: (g.members ?? []).length,
        invitedBy: inviter
          ? {
              id: (inviter._id ?? inviter).toString(),
              name: inviter.name ?? '',
              avatarUrl: inviter.avatarUrl ?? null,
            }
          : null,
        invitedAt: pending?.invitedAt ?? null,
      };
    });
  },

  async update({ userId, groupId, data }) {
    const group = await findGroupForMember(groupId, userId);
    const role = group.roleOf(userId);
    if (!['owner', 'admin'].includes(role)) throw Forbidden('Only admins can update the group');
    Object.assign(group, data);
    await group.save();
    return group.populate(GROUP_POPULATE);
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

    // Already in, or already invited — nothing to do (idempotent).
    if (group.isMember(user._id)) {
      return { group: await group.populate(GROUP_POPULATE), status: 'already_member' };
    }
    if (group.isPending(user._id)) {
      return { group: await group.populate(GROUP_POPULATE), status: 'pending' };
    }

    const actor = await actorName(userId);

    // The invitee requires approval → record a pending invite instead of
    // adding them. They show up as "pending" to the group and must accept
    // before they count as a member (and can be split with).
    if (user.groupInvitePolicy === 'approval') {
      group.pendingMembers.push({ user: user._id, invitedBy: userId, role: 'member' });
      await group.save();
      // Log the invite as an activity so the invited user sees it in their
      // Activity feed (the feed endpoint also queries pending-member groups
      // filtered to group.invite type).
      await activityService.log({
        groupId: group._id,
        actor: userId,
        type: 'group.invite',
        message: `invited ${user.name} to join`,
        meta: { invitedUserId: user._id.toString() },
      });
      emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });
      notifyUser(user._id, {
        title: 'Group invitation',
        message: `${actor} invited you to join "${group.name}"`,
        type: 'group.invite',
        data: { groupId: group._id.toString(), route: '/groups' },
      }).catch(() => {});
      return { group: await group.populate(GROUP_POPULATE), status: 'pending' };
    }

    // Default 'anyone' policy → add straight in (legacy behaviour).
    group.members.push({ user: user._id, role: 'member' });
    await group.save();
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.member_added',
      message: `added ${user.name}`,
    });
    emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });
    notifyUser(user._id, {
      title: 'New group',
      message: `${actor} added you to "${group.name}"`,
      type: 'group.member_added',
      data: { groupId: group._id.toString(), route: `/groups/${group._id.toString()}` },
    }).catch(() => {});
    return { group: await group.populate(GROUP_POPULATE), status: 'added' };
  },

  // The invitee accepts → they become a real member and can now be split with.
  async acceptInvite({ userId, groupId }) {
    if (!mongoose.isValidObjectId(groupId)) throw NotFound('Group not found');
    const group = await Group.findById(groupId);
    if (!group) throw NotFound('Group not found');

    if (group.isMember(userId)) {
      // Already joined (double-tap / accepted elsewhere) — idempotent.
      return { group: await group.populate(GROUP_POPULATE), joined: true };
    }
    if (!group.isPending(userId)) {
      throw NotFound('You have no pending invitation for this group', 'NO_PENDING_INVITE');
    }

    const pending = group.pendingMembers.find((m) => m.user.toString() === userId.toString());
    group.pendingMembers = group.pendingMembers.filter(
      (m) => m.user.toString() !== userId.toString(),
    );
    group.members.push({ user: userId, role: pending?.role || 'member' });
    await group.save();

    const user = await User.findById(userId).lean();
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.member_joined',
      message: `${user?.name ?? 'A user'} joined the group`,
    });
    emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });

    // Send a personalised notification to the person who sent the original
    // invite, then a generic "joined" message to everyone else.
    const invitedBy = pending?.invitedBy;
    const gid = group._id.toString();
    const route = `/groups/${gid}`;
    const notifBase = { type: 'group.member_joined', data: { groupId: gid, route } };

    if (invitedBy) {
      notifyUser(invitedBy, {
        ...notifBase,
        title: group.name,
        message: `${user?.name ?? 'Someone'} accepted your invitation`,
      }).catch(() => {});
    }
    // Notify remaining members (skip the joiner AND the already-notified inviter).
    const skipIds = new Set([userId.toString(), ...(invitedBy ? [invitedBy.toString()] : [])]);
    const otherIds = group.members
      .map((m) => (m.user?._id ?? m.user).toString())
      .filter((id) => !skipIds.has(id));
    if (otherIds.length > 0) {
      notifyUsers(otherIds, {
        ...notifBase,
        title: group.name,
        message: `${user?.name ?? 'Someone'} joined the group`,
      }).catch(() => {});
    }

    return { group: await group.populate(GROUP_POPULATE), joined: true };
  },

  // The invitee declines → the pending entry is dropped and the inviter is told.
  async declineInvite({ userId, groupId }) {
    if (!mongoose.isValidObjectId(groupId)) throw NotFound('Group not found');
    const group = await Group.findById(groupId);
    if (!group) throw NotFound('Group not found');
    if (!group.isPending(userId)) {
      return { declined: true }; // already gone — idempotent
    }

    const pending = group.pendingMembers.find((m) => m.user.toString() === userId.toString());
    group.pendingMembers = group.pendingMembers.filter(
      (m) => m.user.toString() !== userId.toString(),
    );
    await group.save();
    emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });

    const user = await User.findById(userId).lean();
    // Log so the inviter's activity feed shows the decline in real-time.
    await activityService.log({
      groupId: group._id,
      actor: userId,
      type: 'group.invite_declined',
      message: `${user?.name ?? 'Someone'} declined the invitation`,
    });

    if (pending?.invitedBy) {
      notifyUser(pending.invitedBy, {
        title: group.name,
        message: `${user?.name ?? 'Someone'} declined your invitation`,
        type: 'group.invite_declined',
        data: { groupId: group._id.toString(), route: `/groups/${group._id.toString()}` },
      }).catch(() => {});
    }
    return { declined: true };
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

    return group.populate(GROUP_POPULATE);
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

    // Cancelling a pending invitation (the person never accepted) — just drop
    // the pending entry and let them know it was withdrawn.
    if (!group.isMember(memberId) && group.isPending(memberId)) {
      group.pendingMembers = group.pendingMembers.filter(
        (m) => m.user.toString() !== memberId.toString(),
      );
      await group.save();
      emitToGroup(group._id, 'group:updated', { groupId: group._id.toString() });
      const actor = await actorName(userId);
      notifyUser(memberId, {
        title: group.name,
        message: `${actor} cancelled your invitation to "${group.name}"`,
        type: 'group.invite_cancelled',
        data: { groupId: group._id.toString(), route: '/groups' },
      }).catch(() => {});
      return group.populate(GROUP_POPULATE);
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
    return group.populate(GROUP_POPULATE);
  },

  async joinByCode({ userId, code }) {
    const group = await Group.findOne({ inviteCode: code.toUpperCase() });
    if (!group) throw NotFound('Invalid invite code');
    if (!group.isMember(userId)) {
      group.members.push({ user: userId, role: 'member' });
      // Joining by code satisfies any outstanding invitation, so clear a
      // stale pending entry to avoid showing the user as member *and* pending.
      if (group.isPending(userId)) {
        group.pendingMembers = group.pendingMembers.filter(
          (m) => m.user.toString() !== userId.toString(),
        );
      }
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
    return group.populate(GROUP_POPULATE);
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
