import { verifyAccess } from '../utils/jwt.js';
import { Unauthorized } from '../utils/errors.js';

export function requireAuth(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) throw Unauthorized('Missing bearer token');
    const decoded = verifyAccess(token);
    req.user = { id: decoded.sub, email: decoded.email };
    next();
  } catch (err) {
    next(err.statusCode ? err : Unauthorized('Invalid or expired token'));
  }
}
