import mongoose from 'mongoose';

const activitySchema = new mongoose.Schema(
  {
    group: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', index: true },
    actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, required: true, index: true },
    message: { type: String, required: true },
    // Explicit recipients for activities that are NOT scoped to a group — e.g.
    // loan events (no group) and the "group deleted" tombstone trace (the group
    // is gone, so it must outlive it). Group activities leave this empty and are
    // scoped by `group` membership instead.
    recipients: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true }],
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

activitySchema.index({ group: 1, createdAt: -1 });
activitySchema.index({ recipients: 1, createdAt: -1 });

export const Activity = mongoose.model('Activity', activitySchema);
