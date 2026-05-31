import mongoose from 'mongoose';

/**
 * The fixed palette of emojis a user may react with. Kept small and
 * deliberate (WhatsApp-style) so the picker stays a single tidy row and
 * the data stays easy to aggregate. Shared with the validation layer.
 */
export const ALLOWED_REACTIONS = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🎉', '💰'];

/**
 * A single user's reaction to a target. The target is polymorphic — either an
 * `expense` or a `settlement` — so one collection backs reactions everywhere
 * they appear. A user may hold at most ONE reaction per target (WhatsApp
 * semantics): reacting again with the same emoji removes it, reacting with a
 * different emoji switches it. The unique index enforces the "one per user"
 * rule at the database level.
 */
const reactionSchema = new mongoose.Schema(
  {
    // Denormalised so membership checks and the realtime room can be resolved
    // without a second lookup back to the target document.
    group: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
    targetType: { type: String, enum: ['expense', 'settlement'], required: true },
    targetId: { type: mongoose.Schema.Types.ObjectId, required: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    emoji: { type: String, required: true, enum: ALLOWED_REACTIONS },
  },
  { timestamps: true },
);

// Fast "all reactions for these targets" aggregation.
reactionSchema.index({ targetType: 1, targetId: 1 });
// One reaction per user per target.
reactionSchema.index({ targetType: 1, targetId: 1, user: 1 }, { unique: true });

export const Reaction = mongoose.model('Reaction', reactionSchema);
