import { z } from 'zod';

export const createGroupSchema = z.object({
  name: z.string().min(2).max(80),
  description: z.string().max(280).optional().default(''),
  category: z.enum(['family', 'trip', 'roommates', 'office', 'event', 'other']).default('other'),
  coverColor: z.string().regex(/^#[0-9a-fA-F]{6}$/).optional(),
  icon: z.string().optional(),
  currency: z.string().length(3).optional(),
  memberEmails: z.array(z.string().email()).optional().default([]),
});

export const updateGroupSchema = createGroupSchema.partial();

export const joinByCodeSchema = z.object({
  code: z.string().min(4).max(20),
});
