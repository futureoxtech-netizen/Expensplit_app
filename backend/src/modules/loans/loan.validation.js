import { z } from 'zod';

export const createLoanSchema = z.object({
  lenderId: z.string().min(1, 'Lender is required'),
  borrowerId: z.string().min(1, 'Borrower is required'),
  amount: z.number().positive('Amount must be positive'),
  currency: z.string().min(1).default('PKR'),
  description: z.string().default(''),
  notes: z.string().default(''),
  dueDate: z.string().datetime().optional().nullable(),
  clientOpId: z.string().optional(),
});

export const recordPaymentSchema = z.object({
  amount: z.number().positive('Amount must be positive'),
  note: z.string().default(''),
  method: z.enum(['cash', 'bank', 'upi', 'other']).default('cash'),
  paidAt: z.string().datetime().optional(),
  clientOpId: z.string().optional(),
});

export const updateLoanSchema = z.object({
  description: z.string().optional(),
  notes: z.string().optional(),
  dueDate: z.string().datetime().optional().nullable(),
});
