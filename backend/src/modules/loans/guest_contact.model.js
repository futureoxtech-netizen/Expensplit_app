import mongoose from 'mongoose';

const guestContactSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true },
    phone: { type: String, default: null },
    email: { type: String, default: null },
    avatarColor: { type: String, default: '#6C5CE7' },
    // The client's local UUID for this contact (used for idempotency and for
    // linking back guest loans to their contact after logout/re-login).
    clientId: { type: String, default: null },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

guestContactSchema.index({ owner: 1, updatedAt: 1 });
guestContactSchema.index({ clientId: 1 }, { unique: true, sparse: true });

export const GuestContact = mongoose.model('GuestContact', guestContactSchema);
