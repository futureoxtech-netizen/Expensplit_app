import { z } from 'zod';

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'Invalid id');

export const createSettlementSchema = z.object({
  groupId: objectId,
  from: objectId,
  to: objectId,
  amount: z.number().positive(),
  currency: z.string().length(3).optional(),
  method: z.enum(['cash', 'bank', 'upi', 'other']).optional(),
  note: z.string().max(280).optional(),
  settledAt: z.coerce.date().optional(),
});
