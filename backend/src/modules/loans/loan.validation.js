import { z } from 'zod';

const guestCounterpartySchema = z.object({
  clientId: z.string().optional().nullable(),
  name: z.string().min(1, 'Guest name is required'),
  phone: z.string().optional().nullable(),
  email: z.string().optional().nullable(),
  avatarColor: z.string().optional(),
});

export const createLoanSchema = z
  .object({
    // User-to-user loan fields
    lenderId: z.string().min(1).optional(),
    borrowerId: z.string().min(1).optional(),
    // Guest loan fields
    loanType: z.enum(['given', 'taken']).optional(),
    guestCounterparty: guestCounterpartySchema.optional(),
    // Common
    amount: z.number().positive('Amount must be positive'),
    currency: z.string().min(1).default('PKR'),
    description: z.string().default(''),
    notes: z.string().default(''),
    dueDate: z.string().datetime().optional().nullable(),
    clientOpId: z.string().optional(),
  })
  .refine(
    (data) =>
      (data.lenderId && data.borrowerId) ||
      (data.loanType && data.guestCounterparty),
    { message: 'Either lenderId+borrowerId or loanType+guestCounterparty is required' }
  );


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
