import mongoose from 'mongoose';
import { v4 as uuid } from 'uuid';

const memberSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: ['owner', 'admin', 'member'], default: 'member' },
    joinedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

// A person who was added to the group but whose `groupInvitePolicy` is
// 'approval' — they only become a real member once they accept. Pending
// people are NOT members: they're excluded from balances, splits and the
// member list until they accept.
const pendingMemberSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    invitedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: ['admin', 'member'], default: 'member' },
    invitedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

const groupSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    category: {
      type: String,
      enum: ['family', 'trip', 'roommates', 'office', 'event', 'other'],
      default: 'other',
    },
    coverColor: { type: String, default: '#6C5CE7' },
    icon: { type: String, default: 'group' },
    currency: { type: String, default: 'USD' },
    inviteCode: {
      type: String,
      unique: true,
      default: () => uuid().replace(/-/g, '').slice(0, 10).toUpperCase(),
    },
    members: { type: [memberSchema], default: [] },
    pendingMembers: { type: [pendingMemberSchema], default: [] },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    archived: { type: Boolean, default: false },
  },
  { timestamps: true },
);

groupSchema.index({ 'members.user': 1 });
groupSchema.index({ 'pendingMembers.user': 1 });

groupSchema.method('isMember', function isMember(userId) {
  return this.members.some((m) => m.user.toString() === userId.toString());
});

groupSchema.method('isPending', function isPending(userId) {
  return (this.pendingMembers ?? []).some((m) => m.user.toString() === userId.toString());
});

groupSchema.method('roleOf', function roleOf(userId) {
  return this.members.find((m) => m.user.toString() === userId.toString())?.role;
});

export const Group = mongoose.model('Group', groupSchema);
