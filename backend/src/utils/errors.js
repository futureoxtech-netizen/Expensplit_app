export class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
  }
}

export const BadRequest = (m, c = 'BAD_REQUEST') => new AppError(m, 400, c);
export const Unauthorized = (m = 'Unauthorized', c = 'UNAUTHORIZED') => new AppError(m, 401, c);
export const Forbidden = (m = 'Forbidden', c = 'FORBIDDEN') => new AppError(m, 403, c);
export const NotFound = (m = 'Not found', c = 'NOT_FOUND') => new AppError(m, 404, c);
export const Conflict = (m, c = 'CONFLICT') => new AppError(m, 409, c);
