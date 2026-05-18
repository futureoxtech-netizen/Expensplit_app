import mongoose from 'mongoose';

const settlementSchema = new mongoose.Schema(
  {
    group: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
    from: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    to: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true, min: 0 },
    currency: { type: String, default: 'USD' },
    method: { type: String, enum: ['cash', 'bank', 'upi', 'other'], default: 'cash' },
    note: { type: String, default: '' },
    settledAt: { type: Date, default: Date.now },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true },
);

export const Settlement = mongoose.model('Settlement', settlementSchema);
