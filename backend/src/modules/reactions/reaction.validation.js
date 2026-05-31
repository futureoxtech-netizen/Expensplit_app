import { z } from 'zod';
import { ALLOWED_REACTIONS } from './reaction.model.js';

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'Invalid id');

export const toggleReactionSchema = z.object({
  targetType: z.enum(['expense', 'settlement']),
  targetId: objectId,
  // z.enum needs a non-empty tuple; ALLOWED_REACTIONS is a const array.
  emoji: z.enum(ALLOWED_REACTIONS),
});

export const targetParamsSchema = z.object({
  targetType: z.enum(['expense', 'settlement']),
  targetId: objectId,
});
