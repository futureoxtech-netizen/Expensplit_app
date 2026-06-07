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
    // When an expense is paid by more than one person, each contribution is
    // recorded here (amounts must sum to `amount`). Empty for single-payer
    // expenses, where `paidBy` + `amount` are authoritative. `paidBy` always
    // mirrors the largest contributor so legacy reads stay meaningful.
    payers: {
      type: [
        new mongoose.Schema(
          {
            user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
            amount: { type: Number, required: true, min: 0 },
          },
          { _id: false },
        ),
      ],
      default: [],
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
    // Client-generated idempotency key for offline-first sync. A retried
    // offline-create with the same key returns the existing doc, never a dup.
    clientOpId: { type: String, default: null },
  },
  { timestamps: true },
);

expenseSchema.index({ group: 1, spentAt: -1 });
// Partial (not sparse) unique index: only enforced when clientOpId is a real
// string, so the many rows with clientOpId:null (normal online creates) don't
// collide with each other.
expenseSchema.index(
  { clientOpId: 1 },
  { unique: true, partialFilterExpression: { clientOpId: { $type: 'string' } } },
);

export const Expense = mongoose.model('Expense', expenseSchema);
