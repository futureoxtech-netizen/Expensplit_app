import mongoose from 'mongoose';

const otpSchema = new mongoose.Schema({
  email:    { type: String, required: true, lowercase: true },
  purpose:  { type: String, enum: ['register', 'reset'], default: 'register' },
  code:     { type: String, required: true },
  expiresAt:{ type: Date, required: true, index: { expires: 0 } }, // TTL auto-delete
  attempts: { type: Number, default: 0 },
});

// Each (email, purpose) pair can only have one active OTP at a time
otpSchema.index({ email: 1, purpose: 1 }, { unique: true });

export const Otp = mongoose.model('Otp', otpSchema);
