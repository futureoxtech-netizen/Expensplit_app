import { z } from 'zod';

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'Invalid id');

const splitEntry = z.object({
  userId: objectId,
  value: z.number().nonnegative().optional(),
});

// One contributor when an expense is paid by multiple people.
const payerEntry = z.object({
  userId: objectId,
  amount: z.number().nonnegative(),
});

export const createExpenseSchema = z.object({
  groupId: objectId,
  description: z.string().min(1).max(120),
  notes: z.string().max(500).optional().default(''),
  amount: z.number().positive(),
  currency: z.string().length(3).optional(),
  category: z
    .enum([
      'food',
      'groceries',
      'transport',
      'shopping',
      'rent',
      'utilities',
      'entertainment',
      'travel',
      'health',
      'gifts',
      'other',
    ])
    .optional(),
  splitMode: z.enum(['equal', 'exact', 'percent', 'shares']),
  clientOpId: z.string().max(64).optional(),
  paidBy: objectId,
  // Optional multi-payer breakdown. When present (2+ entries) it overrides the
  // single `paidBy` and the amounts must sum to the expense total.
  payers: z.array(payerEntry).optional(),
  splits: z.array(splitEntry).min(1),
  tax: z.number().nonnegative().optional().default(0),
  tip: z.number().nonnegative().optional().default(0),
  // Accepts an absolute S3 URL (production) or a relative /uploads path
  // (local-disk dev fallback). The value always comes from our own upload
  // endpoint, so we only bound its length rather than requiring url() format.
  receiptUrl: z.string().max(500).optional().or(z.literal('')),
  spentAt: z.coerce.date().optional(),
  recurring: z
    .object({
      enabled: z.boolean(),
      cadence: z.enum(['daily', 'weekly', 'monthly', 'yearly']).optional(),
    })
    .optional(),
});

export const updateExpenseSchema = createExpenseSchema.partial().omit({ groupId: true });
