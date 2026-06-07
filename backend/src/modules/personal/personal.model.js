import mongoose from 'mongoose';

const personalExpenseSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    description: { type: String, required: true, trim: true },
    amount: { type: Number, required: true, min: 0 },
    currency: { type: String, default: 'USD' },
    category: {
      type: String,
      enum: ['food', 'transport', 'shopping', 'entertainment', 'health', 'bills', 'education', 'other'],
      default: 'other',
    },
    date: { type: Date, required: true, index: true },
    note: { type: String, default: '' },
    receiptUrl: { type: String, default: '' },
    clientOpId: { type: String, default: null },
  },
  { timestamps: true },
);

personalExpenseSchema.index({ user: 1, date: -1 });
personalExpenseSchema.index(
  { clientOpId: 1 },
  { unique: true, partialFilterExpression: { clientOpId: { $type: 'string' } } },
);

export const PersonalExpense = mongoose.model('PersonalExpense', personalExpenseSchema);
