import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, index: true },
    passwordHash: { type: String, required: false, select: false },
    googleId: { type: String, sparse: true, index: true },
    isEmailVerified: { type: Boolean, default: false },
    avatarUrl: { type: String, default: '' },
    // Placeholder ("guest") accounts represent people who are split with but
    // aren't on Expensplit. They have no credentials and can never log in;
    // they exist only so expenses/balances can reference them like any other
    // member. `createdBy` is the user who added them; `placeholderGroup` is
    // the group they belong to (used for cleanup when removed).
    isPlaceholder: { type: Boolean, default: false },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    placeholderGroup: { type: mongoose.Schema.Types.ObjectId, ref: 'Group' },
    currency: { type: String, default: 'USD' },
    locale: { type: String, default: 'en-US' },
    bio: { type: String, default: '' },
    refreshTokens: { type: [String], default: [], select: false },
    fcmTokens: { type: [String], default: [] },
    // OneSignal subscription / player IDs registered by every device this
    // user signs into. Used as a fallback target if external_id routing
    // ever fails; the primary delivery path is external_id == userId.
    oneSignalIds: { type: [String], default: [] },
    referralCode: { type: String, unique: true, sparse: true },
    streak: {
      lastActiveAt: Date,
      currentDays: { type: Number, default: 0 },
    },
    notificationPrefs: {
      expenses: { type: Boolean, default: true },
      settlements: { type: Boolean, default: true },
      groups: { type: Boolean, default: true },
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
    isPlaceholder: this.isPlaceholder ?? false,
    currency: this.currency,
    locale: this.locale,
    bio: this.bio,
    referralCode: this.referralCode,
    isEmailVerified: this.isEmailVerified,
    notificationPrefs: this.notificationPrefs ?? {
      expenses: true,
      settlements: true,
      groups: true,
    },
    createdAt: this.createdAt,
  };
});

export const User = mongoose.model('User', userSchema);
