import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import { User } from '../users/user.model.js';
import { signAccess, signRefresh, verifyRefresh } from '../../utils/jwt.js';
import { BadRequest, Conflict, Unauthorized } from '../../utils/errors.js';

const referralCode = () => uuid().replace(/-/g, '').slice(0, 8).toUpperCase();

async function buildSession(user) {
  const payload = { sub: user._id.toString(), email: user.email };
  const accessToken = signAccess(payload);
  const refreshToken = signRefresh({ ...payload, jti: uuid() });
  // Persist refresh token so we can revoke on logout
  user.refreshTokens = [...(user.refreshTokens || []), refreshToken].slice(-5);
  await user.save();
  return { accessToken, refreshToken };
}

export const authService = {
  async register({ name, email, password, currency = 'USD' }) {
    const exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) throw Conflict('Email is already registered', 'EMAIL_TAKEN');
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: email.toLowerCase(),
      passwordHash,
      currency,
      referralCode: referralCode(),
    });
    const userWithSecrets = await User.findById(user._id).select('+passwordHash +refreshTokens');
    const tokens = await buildSession(userWithSecrets);
    return { user: user.toPublic(), ...tokens };
  },

  async login({ email, password }) {
    const user = await User.findOne({ email: email.toLowerCase() }).select(
      '+passwordHash +refreshTokens',
    );
    if (!user) throw Unauthorized('Invalid credentials', 'INVALID_CREDENTIALS');
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw Unauthorized('Invalid credentials', 'INVALID_CREDENTIALS');
    const tokens = await buildSession(user);
    return { user: user.toPublic(), ...tokens };
  },

  async refresh({ refreshToken }) {
    let decoded;
    try {
      decoded = verifyRefresh(refreshToken);
    } catch {
      throw Unauthorized('Invalid refresh token');
    }
    const user = await User.findById(decoded.sub).select('+refreshTokens');
    if (!user || !user.refreshTokens.includes(refreshToken)) {
      throw Unauthorized('Refresh token revoked');
    }
    user.refreshTokens = user.refreshTokens.filter((t) => t !== refreshToken);
    const tokens = await buildSession(user);
    return { user: user.toPublic(), ...tokens };
  },

  async logout({ userId, refreshToken }) {
    if (!refreshToken) throw BadRequest('refreshToken required');
    const user = await User.findById(userId).select('+refreshTokens');
    if (!user) return;
    user.refreshTokens = user.refreshTokens.filter((t) => t !== refreshToken);
    await user.save();
  },
};
