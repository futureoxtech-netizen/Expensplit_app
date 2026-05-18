import mongoose from 'mongoose';

const activitySchema = new mongoose.Schema(
  {
    group: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', index: true },
    actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, required: true, index: true },
    message: { type: String, required: true },
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

activitySchema.index({ group: 1, createdAt: -1 });

export const Activity = mongoose.model('Activity', activitySchema);
