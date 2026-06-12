import mongoose from 'mongoose';

const loanPaymentSchema = new mongoose.Schema(
  {
    loan: { type: mongoose.Schema.Types.ObjectId, ref: 'Loan', required: true, index: true },
    amount: { type: Number, required: true, min: 0.01 },
    note: { type: String, default: '' },
    method: { type: String, enum: ['cash', 'bank', 'upi', 'other'], default: 'cash' },
    paidAt: { type: Date, default: Date.now },
    recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    clientOpId: { type: String, default: null },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

loanPaymentSchema.index({ clientOpId: 1 }, { unique: true, sparse: true });

export const LoanPayment = mongoose.model('LoanPayment', loanPaymentSchema);
