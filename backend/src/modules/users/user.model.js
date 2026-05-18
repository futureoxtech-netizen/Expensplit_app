import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, index: true },
    passwordHash: { type: String, required: true, select: false },
    avatarUrl: { type: String, default: '' },
    currency: { type: String, default: 'USD' },
    locale: { type: String, default: 'en-US' },
    bio: { type: String, default: '' },
    refreshTokens: { type: [String], default: [], select: false },
    fcmTokens: { type: [String], default: [] },
    referralCode: { type: String, unique: true, sparse: true },
    streak: {
      lastActiveAt: Date,
      currentDays: { type: Number, default: 0 },
    },
  },
  { timestamps: true },
);

userSchema.method('toPublic', function toPublic() {
  return {
    id: this._id.toString(),
    name: this.name,
    email: this.email,
    avatarUrl: this.avatarUrl,
    currency: this.currency,
    locale: this.locale,
    bio: this.bio,
    referralCode: this.referralCode,
    createdAt: this.createdAt,
  };
});

export const User = mongoose.model('User', userSchema);
