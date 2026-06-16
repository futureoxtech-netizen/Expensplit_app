import mongoose from 'mongoose';

const loanSchema = new mongoose.Schema(
  {
    // For user-to-user loans, both are set. For guest loans, only the real user
    // side is set; the other is null and guestCounterparty carries the info.
    lender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    borrower: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    // 'user' = both parties are registered users; 'guest' = counterparty is local-only contact
    counterpartyType: { type: String, enum: ['user', 'guest'], default: 'user' },
    // Populated only when counterpartyType == 'guest'
    guestCounterparty: {
      clientId: { type: String, default: null }, // client's local UUID for the guest contact
      name: { type: String, default: '' },
      phone: { type: String, default: null },
      email: { type: String, default: null },
      avatarColor: { type: String, default: '#6C5CE7' },
    },
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
