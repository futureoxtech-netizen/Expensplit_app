import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import { OAuth2Client } from 'google-auth-library';
import { User } from '../users/user.model.js';
import { Otp } from './otp.model.js';
import { DeletedAccount } from './deleted_account.model.js';
import { signAccess, signRefresh, verifyRefresh } from '../../utils/jwt.js';
import { sendOtpEmail, sendPasswordResetEmail } from '../../utils/mailer.js';
import { env } from '../../config/env.js';
import { BadRequest, Conflict, Unauthorized } from '../../utils/errors.js';

const googleClient = new OAuth2Client();

const OTP_TTL_MS = 10 * 60 * 1000;
const MAX_OTP_ATTEMPTS = 5;
const DELETION_COOLDOWN_MS = 3 * 24 * 60 * 60 * 1000; // 3 days

const referralCode = () => uuid().replace(/-/g, '').slice(0, 8).toUpperCase();

// How long a just-rotated refresh token stays usable so a client that never
// received the rotation response can recover when it next comes online —
// including after being backgrounded/killed and reopened later, not just an
// immediate retry. Bounded so a leaked rotated token can't be replayed forever.
const ROTATION_GRACE_MS = 24 * 60 * 60 * 1000; // 24h
// Cap on retained grace tokens. Shared across a user's devices, so kept well
// above MAX_SESSIONS so a busy second device's rotations can't evict the grace
// entry a stuck device still needs.
const MAX_GRACE = 50;
// Max concurrent sessions (devices) per user. Rotation is net-zero per device;
// each distinct login adds one. Kept generous so a user with several devices /
// reinstalls isn't silently evicted (which surfaces as a surprise logout).
const MAX_SESSIONS = 10;

async function buildSession(user) {
  const payload = { sub: user._id.toString(), email: user.email };
  const accessToken = signAccess(payload);
  const refreshToken = signRefresh({ ...payload, jti: uuid() });
  user.refreshTokens = [...(user.refreshTokens || []), refreshToken].slice(-MAX_SESSIONS);
  await user.save();
  return { accessToken, refreshToken };
}

/** Throw if the email was recently deleted and is still within the cooldown window. */
async function checkDeletionCooldown(email) {
  const record = await DeletedAccount.findOne({ email });
  if (!record) return;
  const elapsed = Date.now() - record.deletedAt.getTime();
  if (elapsed < DELETION_COOLDOWN_MS) {
    const remainingHours = Math.ceil((DELETION_COOLDOWN_MS - elapsed) / 3_600_000);
    throw Conflict(
      `This email was recently used on a deleted account. You can register again in ${remainingHours} hour${remainingHours !== 1 ? 's' : ''}.`,
      'ACCOUNT_DELETED_COOLDOWN',
    );
  }
  // Past the cooldown — clean up the record so it no longer blocks
  await record.deleteOne();
}

/** Send or resend an OTP for the given (email, purpose) pair. */
async function dispatchOtp(email, purpose) {
  const existing = await Otp.findOne({ email, purpose });
  if (existing) {
    const ageMs = Date.now() - (existing.expiresAt.getTime() - OTP_TTL_MS);
    if (ageMs < 60_000) throw BadRequest('Please wait before requesting another code', 'OTP_COOLDOWN');
  }
  const code = String(crypto.randomInt(100000, 999999));
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);
  await Otp.findOneAndUpdate(
    { email, purpose },
    { code, expiresAt, attempts: 0 },
    { upsert: true, new: true },
  );
  return code;
}

/** Verify an OTP and delete it on success. Throws on wrong code / expired / locked. */
async function verifyOtp(email, purpose, otp) {
  const record = await Otp.findOne({ email, purpose });
  if (!record || record.expiresAt < new Date()) {
    throw BadRequest('Code expired or not found. Request a new one.', 'OTP_EXPIRED');
  }
  if (record.attempts >= MAX_OTP_ATTEMPTS) {
    await record.deleteOne();
    throw BadRequest('Too many incorrect attempts. Request a new code.', 'OTP_MAX_ATTEMPTS');
  }
  if (record.code !== otp) {
    record.attempts += 1;
    await record.save();
    const left = MAX_OTP_ATTEMPTS - record.attempts;
    throw BadRequest(`Incorrect code. ${left} attempt${left !== 1 ? 's' : ''} remaining.`, 'OTP_INVALID');
  }
  await record.deleteOne();
}

/**
 * Validate an OTP without consuming it. Used by the verify-reset screen
 * so we can show "wrong code" feedback immediately instead of letting
 * the user proceed to the new-password screen with a bogus code.
 *
 * Mirrors `verifyOtp` exactly except it does not delete the record on
 * success — the subsequent `resetPassword` call still calls `verifyOtp`,
 * which is the canonical consume-on-success step. Failure attempts ARE
 * counted so brute-force protection still applies.
 */
async function peekOtp(email, purpose, otp) {
  const record = await Otp.findOne({ email, purpose });
  if (!record || record.expiresAt < new Date()) {
    throw BadRequest('Code expired or not found. Request a new one.', 'OTP_EXPIRED');
  }
  if (record.attempts >= MAX_OTP_ATTEMPTS) {
    await record.deleteOne();
    throw BadRequest('Too many incorrect attempts. Request a new code.', 'OTP_MAX_ATTEMPTS');
  }
  if (record.code !== otp) {
    record.attempts += 1;
    await record.save();
    const left = MAX_OTP_ATTEMPTS - record.attempts;
    throw BadRequest(`Incorrect code. ${left} attempt${left !== 1 ? 's' : ''} remaining.`, 'OTP_INVALID');
  }
  // success → leave the record intact for the reset step to consume
}

export const authService = {
  // ── Send OTP (registration) ───────────────────────────────────────────────────
  async sendOtp({ email }) {
    const normalEmail = email.toLowerCase();

    // Block re-registration of existing accounts immediately
    const exists = await User.findOne({ email: normalEmail });
    if (exists) throw Conflict('An account with this email already exists. Please sign in.', 'EMAIL_TAKEN');

    // Enforce 3-day cooldown for recently-deleted accounts
    await checkDeletionCooldown(normalEmail);

    const code = await dispatchOtp(normalEmail, 'register');
    await sendOtpEmail(normalEmail, code);
    return { message: 'Verification code sent' };
  },

  // ── Register (OTP required) ───────────────────────────────────────────────────
  async register({ name, email, password, currency = 'USD', otp }) {
    const normalEmail = email.toLowerCase();

    // Double-check in case of race condition between sendOtp and register
    const exists = await User.findOne({ email: normalEmail });
    if (exists) throw Conflict('An account with this email already exists. Please sign in.', 'EMAIL_TAKEN');

    // Also check cooldown here to guard against direct API calls that skip sendOtp
    await checkDeletionCooldown(normalEmail);

    await verifyOtp(normalEmail, 'register', otp);

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: normalEmail,
      passwordHash,
      currency,
      referralCode: referralCode(),
      isEmailVerified: true,
    });
    const userWithSecrets = await User.findById(user._id).select('+passwordHash +refreshTokens');
    const tokens = await buildSession(userWithSecrets);
    return { user: user.toPublic(), ...tokens };
  },

  // ── Login ─────────────────────────────────────────────────────────────────────
  async login({ email, password }) {
    const user = await User.findOne({ email: email.toLowerCase() }).select(
      '+passwordHash +refreshTokens',
    );
    if (!user) throw Unauthorized('Invalid credentials', 'INVALID_CREDENTIALS');
    if (!user.passwordHash) throw Unauthorized('This account uses Google Sign-In. Please sign in with Google.', 'USE_GOOGLE');
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw Unauthorized('Invalid credentials', 'INVALID_CREDENTIALS');
    const tokens = await buildSession(user);
    return { user: user.toPublic(), ...tokens };
  },

  // ── Forgot password: send OTP ─────────────────────────────────────────────────
  async sendForgotOtp({ email }) {
    const normalEmail = email.toLowerCase();
    // passwordHash is `select: false` in the schema, so it has to be
    // explicitly selected — otherwise every account looks Google-only.
    const user = await User.findOne({ email: normalEmail }).select('+passwordHash');
    if (!user) throw BadRequest('No account found with this email address.', 'USER_NOT_FOUND');
    // Google-only accounts have a googleId but no passwordHash.
    if (!user.passwordHash && user.googleId) {
      throw BadRequest('This account uses Google Sign-In and has no password to reset.', 'USE_GOOGLE');
    }
    const code = await dispatchOtp(normalEmail, 'reset');
    await sendPasswordResetEmail(normalEmail, code);
    return { message: 'Password reset code sent' };
  },

  // ── Forgot password: verify OTP only (does not consume) ──────────────────────
  async verifyResetOtp({ email, otp }) {
    const normalEmail = email.toLowerCase();
    await peekOtp(normalEmail, 'reset', otp);
    return { message: 'Code verified' };
  },

  // ── Forgot password: reset ─────────────────────────────────────────────────
  async resetPassword({ email, otp, newPassword }) {
    const normalEmail = email.toLowerCase();
    await verifyOtp(normalEmail, 'reset', otp);

    const user = await User.findOne({ email: normalEmail }).select('+passwordHash +refreshTokens');
    if (!user) throw BadRequest('Account not found', 'USER_NOT_FOUND');

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    user.refreshTokens = []; // invalidate all active sessions
    user.recentlyRotated = []; // ...including any in-grace rotated tokens
    await user.save();
    return { message: 'Password updated successfully' };
  },


  async googleAuth({ idToken, accessToken }) {
    if (!env.GOOGLE_CLIENT_IDS.length || env.GOOGLE_CLIENT_IDS.some((id) => id.includes('YOUR_GOOGLE'))) {
      throw BadRequest('Google Sign-In is not configured on this server', 'GOOGLE_NOT_CONFIGURED');
    }

    let googleId, email, name, picture;

    if (idToken) {
      // Mobile path: verify Google ID token (JWT) directly
      let ticket;
      try {
        // Accept tokens minted for any of our configured clients (web / Android
        // / iOS) — each platform uses a different audience. See env.GOOGLE_CLIENT_IDS.
        ticket = await googleClient.verifyIdToken({ idToken, audience: env.GOOGLE_CLIENT_IDS });
      } catch {
        throw Unauthorized('Invalid Google token', 'GOOGLE_TOKEN_INVALID');
      }
      const payload = ticket.getPayload();
      googleId = payload.sub;
      email = payload.email;
      name = payload.name;
      picture = payload.picture;
    } else if (accessToken) {
      // Web path: verify access token via Google userinfo endpoint
      let resp;
      try {
        resp = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
          headers: { Authorization: `Bearer ${accessToken}` },
        });
      } catch {
        throw Unauthorized('Could not reach Google servers', 'GOOGLE_TOKEN_INVALID');
      }
      if (!resp.ok) throw Unauthorized('Invalid Google access token', 'GOOGLE_TOKEN_INVALID');
      const info = await resp.json();
      if (!info.sub) throw Unauthorized('Invalid Google token response', 'GOOGLE_TOKEN_INVALID');
      googleId = info.sub;
      email = info.email;
      name = info.name;
      picture = info.picture;
    } else {
      throw BadRequest('Either idToken or accessToken is required', 'MISSING_TOKEN');
    }
    const normalEmail = email.toLowerCase();
    let user = await User.findOne({ $or: [{ googleId }, { email: normalEmail }] }).select('+refreshTokens');
    if (!user) {
      user = await User.create({
        name,
        email: normalEmail,
        googleId,
        avatarUrl: picture ?? '',
        currency: 'PKR',
        referralCode: referralCode(),
        isEmailVerified: true,
      });
      user = await User.findById(user._id).select('+refreshTokens');
    } else if (!user.googleId) {
      user.googleId = googleId;
      if (!user.avatarUrl) user.avatarUrl = picture ?? '';
      user.isEmailVerified = true;
    }
    const tokens = await buildSession(user);
    return { user: user.toPublic(), ...tokens };
  },

  // ── Refresh ───────────────────────────────────────────────────────────────────
  async refresh({ refreshToken }) {
    let decoded;
    try {
      decoded = verifyRefresh(refreshToken);
    } catch {
      throw Unauthorized('Invalid refresh token');
    }
    const user = await User.findById(decoded.sub).select('+refreshTokens +recentlyRotated');
    if (!user) throw Unauthorized('Refresh token revoked');

    const now = Date.now();
    // Drop expired grace entries up front so the list can't grow unbounded.
    const grace = (user.recentlyRotated || []).filter(
      (r) => r.expiresAt && new Date(r.expiresAt).getTime() > now,
    );

    const isCurrent = user.refreshTokens.includes(refreshToken);
    const inGrace = grace.some((r) => r.token === refreshToken);
    // Accept the token if it's an active session OR was just rotated out within
    // the grace window (a retried refresh after a lost response). Anything else
    // is genuinely revoked/replayed/expired → the client should re-authenticate.
    if (!isCurrent && !inGrace) {
      throw Unauthorized('Refresh token revoked');
    }

    if (isCurrent) {
      // Normal rotation: retire this token but keep it usable briefly in case
      // the client never sees the response we're about to send.
      user.refreshTokens = user.refreshTokens.filter((t) => t !== refreshToken);
      grace.push({ token: refreshToken, expiresAt: new Date(now + ROTATION_GRACE_MS) });
    }
    // Cap the grace list (defensive) and persist via buildSession's save.
    user.recentlyRotated = grace.slice(-MAX_GRACE);

    const tokens = await buildSession(user);
    return { user: user.toPublic(), ...tokens };
  },

  async logout({ userId, refreshToken }) {
    if (!refreshToken) throw BadRequest('refreshToken required');
    const user = await User.findById(userId).select('+refreshTokens');
    if (!user) return;
    user.refreshTokens = user.refreshTokens.filter((t) => t !== refreshToken);
    await user.save();
    // Clear stored OneSignal subscription ids for this user so the database
    // stays tidy and diagnostics aren't polluted with stale entries.
    // Push delivery itself is already cut on the OneSignal side by the client
    // calling OneSignal.logout() which unlinks the external_id.
    await User.findByIdAndUpdate(userId, { $set: { oneSignalIds: [] } });
  },
};
