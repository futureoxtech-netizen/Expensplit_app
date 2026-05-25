import mongoose from 'mongoose';

const shareSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    // Snapshot of the user's display info, written when the user deletes their account.
    // Allows showing "John Doe (deleted)" in expense lists even after the user is gone.
    userSnapshot: {
      name: { type: String, default: null },
      email: { type: String, default: null },
      avatarUrl: { type: String, default: null },
    },
  },
  { _id: false },
);

const expenseSchema = new mongoose.Schema(
  {
    group: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
    description: { type: String, required: true, trim: true },
    notes: { type: String, default: '' },
    amount: { type: Number, required: true, min: 0 },
    currency: { type: String, default: 'USD' },
    fxRate: { type: Number, default: 1 },
    category: {
      type: String,
      enum: [
        'food',
        'groceries',
        'transport',
        'shopping',
        'rent',
        'utilities',
        'entertainment',
        'travel',
        'health',
        'gifts',
        'other',
      ],
      default: 'other',
      index: true,
    },
    splitMode: {
      type: String,
      enum: ['equal', 'exact', 'percent', 'shares'],
      required: true,
    },
    paidBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    // Written on account deletion so the payer's identity is preserved in expense history.
    paidBySnapshot: {
      name: { type: String, default: null },
      email: { type: String, default: null },
      avatarUrl: { type: String, default: null },
    },
    shares: { type: [shareSchema], required: true },
    tax: { type: Number, default: 0 },
    tip: { type: Number, default: 0 },
    receiptUrl: { type: String, default: '' },
    spentAt: { type: Date, default: Date.now, index: true },
    recurring: {
      enabled: { type: Boolean, default: false },
      cadence: { type: String, enum: ['daily', 'weekly', 'monthly', 'yearly'], default: 'monthly' },
      nextRunAt: Date,
    },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    deletedAt: { type: Date, default: null, index: true },
  },
  { timestamps: true },
);

expenseSchema.index({ group: 1, spentAt: -1 });

export const Expense = mongoose.model('Expense', expenseSchema);
