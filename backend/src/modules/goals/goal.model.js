import mongoose from 'mongoose';

const { Schema } = mongoose;

// ─── Contribution sub-document ────────────────────────────────────────────────
const contributionSchema = new Schema(
  {
    amount:    { type: Number, required: true, min: 0.01 },
    note:      { type: String, trim: true, maxlength: 200, default: '' },
    date:      { type: Date, default: Date.now },
  },
  { _id: true }
);

// ─── Goal ─────────────────────────────────────────────────────────────────────
const goalSchema = new Schema(
  {
    user:         { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title:        { type: String, required: true, trim: true, maxlength: 100 },
    description:  { type: String, trim: true, maxlength: 500, default: '' },
    emoji:        { type: String, default: '🎯', maxlength: 8 },
    category: {
      type: String,
      enum: ['house', 'car', 'vacation', 'emergency', 'education',
             'device', 'health', 'wedding', 'business', 'other'],
      default: 'other',
    },
    targetAmount: { type: Number, required: true, min: 0.01 },
    savedAmount:  { type: Number, default: 0, min: 0 },   // denormalised running total
    currency:     { type: String, default: 'USD', maxlength: 8 },
    targetDate:   { type: Date, default: null },
    status: {
      type: String,
      enum: ['active', 'completed', 'paused', 'abandoned'],
      default: 'active',
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },
    color:        { type: String, default: '#6C5CE7', maxlength: 9 },
    notes:        { type: String, trim: true, maxlength: 1000, default: '' },
    contributions: [contributionSchema],
    completedAt:  { type: Date, default: null },
  },
  { timestamps: true }
);

// ─── Compound index for listing ───────────────────────────────────────────────
goalSchema.index({ user: 1, status: 1, createdAt: -1 });

export const Goal = mongoose.model('Goal', goalSchema);
