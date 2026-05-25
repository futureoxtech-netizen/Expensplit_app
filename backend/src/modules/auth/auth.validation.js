import { z } from 'zod';

export const sendOtpSchema = z.object({
  email: z.string().email(),
});

export const registerSchema = z.object({
  name: z.string().min(2).max(80),
  email: z.string().email(),
  password: z.string().min(8).max(128),
  currency: z.string().length(3).optional(),
  otp: z.string().length(6),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const googleAuthSchema = z
  .object({
    idToken: z.string().min(10).optional(),
    accessToken: z.string().min(10).optional(),
  })
  .refine((d) => d.idToken || d.accessToken, {
    message: 'Either idToken or accessToken is required',
  });

export const refreshSchema = z.object({
  refreshToken: z.string().min(20),
});

export const forgotOtpSchema = z.object({
  email: z.string().email(),
});

export const verifyResetOtpSchema = z.object({
  email: z.string().email(),
  otp: z.string().length(6),
});

export const resetPasswordSchema = z.object({
  email: z.string().email(),
  otp: z.string().length(6),
  newPassword: z.string().min(8).max(128),
});
