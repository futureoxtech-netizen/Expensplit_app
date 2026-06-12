import mongoose from 'mongoose';

const loanSchema = new mongoose.Schema(
  {
    lender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    borrower: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true, min: 0.01 },
    paidAmount: { type: Number, default: 0, min: 0 },
    currency: { type: String, default: 'PKR' },
    description: { type: String, default: '' },
    notes: { type: String, default: '' },
    dueDate: { type: Date, default: null },
    // pending_approval → active → settled; rejected is a terminal state.
    // Guest-user loans skip pending_approval and start as active.
    status: {
      type: String,
      enum: ['pending_approval', 'active', 'settled', 'rejected'],
      default: 'pending_approval',
    },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    clientOpId: { type: String, default: null },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

loanSchema.index({ lender: 1, deletedAt: 1 });
loanSchema.index({ borrower: 1, deletedAt: 1 });
loanSchema.index({ clientOpId: 1 }, { unique: true, sparse: true });

export const Loan = mongoose.model('Loan', loanSchema);
