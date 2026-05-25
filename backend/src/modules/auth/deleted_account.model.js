import mongoose from 'mongoose';

// Keeps a record of recently-deleted accounts so we can:
//   1. Enforce a 3-day re-registration cooldown on the same email.
//   2. Supply a human-readable name for any expenses the user left behind.
// Documents are auto-purged after 30 days via the TTL index.

const deletedAccountSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, index: true },
    name: { type: String, default: 'Deleted User' },
    avatarUrl: { type: String, default: null },
    deletedAt: { type: Date, default: Date.now },
  },
  { _id: true, timestamps: false },
);

// TTL: Mongoose removes documents automatically after 30 days.
deletedAccountSchema.index({ deletedAt: 1 }, { expireAfterSeconds: 30 * 24 * 3600 });

export const DeletedAccount = mongoose.model('DeletedAccount', deletedAccountSchema);
