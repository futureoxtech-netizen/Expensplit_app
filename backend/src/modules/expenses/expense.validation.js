import { z } from 'zod';

const objectId = z.string().regex(/^[a-f0-9]{24}$/i, 'Invalid id');

const splitEntry = z.object({
  userId: objectId,
  value: z.number().nonnegative().optional(),
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
  paidBy: objectId,
  splits: z.array(splitEntry).min(1),
  tax: z.number().nonnegative().optional().default(0),
  tip: z.number().nonnegative().optional().default(0),
  receiptUrl: z.string().url().optional().or(z.literal('')),
  spentAt: z.coerce.date().optional(),
  recurring: z
    .object({
      enabled: z.boolean(),
      cadence: z.enum(['daily', 'weekly', 'monthly', 'yearly']).optional(),
    })
    .optional(),
});

export const updateExpenseSchema = createExpenseSchema.partial().omit({ groupId: true });
